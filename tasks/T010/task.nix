# T010: 3DS TypewriterRenderer (citro2d)
# Implements the visual layer: top screen renders TextBuffer lines as
# off-white text on near-black background; bottom screen shows status.
# Uses citro2d; links citro2d + citro3d + ctru.
# Verification is cross-compilation only — citro2d cannot run on host.
# Depends: T007 (3DS scaffold), T009 (TextBuffer)
{ pkgs, amonite }:

let
  devkitARM = pkgs.devkitNix.devkitARM;
  devkitPRO = "${devkitARM}/opt/devkitpro";
in

(amonite.mkTask {
  id = "T010";
  title = "3DS TypewriterRenderer — citro2d top screen (text+cursor) + bottom screen (status line)";

  src = ../..;

  env = with pkgs; [
    devkitARM
    gnumake
    bash
    xxd
    coreutils
    python3
  ];

  build = ''
    set -euo pipefail
    mkdir -p $out $TMPDIR/build
    # Generate chord_table.h — main.cpp includes chord_decoder.h which needs it
    python3 $src/src/chord_table/generate.py $TMPDIR/build
    # Cross-compile in subshell to avoid devkitARM PATH polluting fixupPhase
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
    cross-compile = ''
      test -f "$out/typewriter.3dsx"
    '';
    magic-3dsx = ''
      ${pkgs.xxd}/bin/xxd -l 4 "$out/typewriter.3dsx" | grep -q "3344 5358"
    '';
  };
# dontStrip: devkitARM on PATH causes strip.sh set-u bug (same as T011)
}).overrideAttrs (_: { dontStrip = true; })
