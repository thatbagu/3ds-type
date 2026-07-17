# T011: 3DS HidPoller + main loop
# Adds chord decoding to the main loop: hidKeysDown → process_hid_frame
# → TextBuffer → TypewriterRenderer. Also compiles a host-side integration
# test that feeds 'Hello' through chord encoding and verifies the buffer.
# chord_table.h is generated at build time (not in source).
# Depends: T001 (chord table), T007 (3DS scaffold), T008 (ChordDecoder),
#          T009 (TextBuffer), T010 (TypewriterRenderer)
{ pkgs, amonite }:

let
  devkitARM = pkgs.devkitNix.devkitARM;
  devkitPRO = "${devkitARM}/opt/devkitpro";
in

(amonite.mkTask {
  id = "T011";
  title = "3DS HidPoller + main loop — hidKeysDown → ChordDecoder → TextBuffer → TypewriterRenderer";

  src = ../..;

  env = with pkgs; [
    devkitARM
    gnumake
    bash
    xxd
    coreutils
    gcc
    python3
  ];

  build = ''
    set -euo pipefail
    mkdir -p $out/bin $TMPDIR/build

    # Generate chord_table.h from the JSON source (no devkitARM needed)
    python3 $src/src/chord_table/generate.py $TMPDIR/build

    # Build host-side integration test (native x86_64, no ARM toolchain)
    cp $src/3ds/source/chord_decoder.h $TMPDIR/build/
    cp $src/3ds/source/text_buffer.h   $TMPDIR/build/
    cp $src/3ds/source/hid_poller.h    $TMPDIR/build/
    cp $src/3ds/test/hid_loop_test.cpp $TMPDIR/build/
    g++ -std=c++17 -I$TMPDIR/build \
      -o $out/bin/hid_loop_test $TMPDIR/build/hid_loop_test.cpp

    # Cross-compile 3DS in a subshell to avoid polluting PATH for fixupPhase.
    # Nix's strip.sh uses $PATH to find 'strip'; if devkitARM's ARM strip is
    # first, it misbehaves when it encounters the native x86_64 hid_loop_test.
    (
      export DEVKITPRO="${devkitPRO}"
      export DEVKITARM="${devkitPRO}/devkitARM"
      export CTRULIB="${devkitPRO}/libctru"
      export PATH="$DEVKITARM/bin:${devkitPRO}/tools/bin:$PATH"
      cp -r $src/3ds $TMPDIR/3ds
      chmod -R u+w $TMPDIR/3ds
      cp $TMPDIR/build/chord_table.h $TMPDIR/3ds/source/chord_table.h
      cd $TMPDIR/3ds
      make SHELL=${pkgs.bash}/bin/bash
    )
    cp $TMPDIR/3ds/typewriter.3dsx $out/typewriter.3dsx
  '';

  verify = {
    host-integration = ''
      "$out/bin/hid_loop_test"
    '';
    cross-compile = ''
      test -f "$out/typewriter.3dsx"
    '';
    magic-3dsx = ''
      ${pkgs.xxd}/bin/xxd -l 4 "$out/typewriter.3dsx" | grep -q "3344 5358"
    '';
  };
# devkitARM is in nativeBuildInputs so its bin/ is first on PATH; Nix's
# strip.sh then calls arm-none-eabi-strip on the native x86_64 binary, which
# triggers a bug in strip.sh (exit_code: unbound variable). Skip stripping —
# the native test binary needs no strip for correctness.
}).overrideAttrs (_: { dontStrip = true; })
