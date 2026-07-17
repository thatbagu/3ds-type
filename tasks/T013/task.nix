{ pkgs, amonite }:

let
  devkitARM = pkgs.devkitNix.devkitARM;
  devkitPRO = "${devkitARM}/opt/devkitpro";
in

(amonite.mkTask {
  id = "T013";
  title = "3DS DraftManager list + launch-screen — sorted by mtime desc, D-pad nav, A/Start";

  src = ../..;

  env = with pkgs; [ devkitARM gnumake bash xxd coreutils gcc python3 ];

  build = ''
    set -euo pipefail
    mkdir -p $out/bin $TMPDIR/build

    # Generate chord_table.h (needed for the 3DS build)
    python3 $src/src/chord_table/generate.py $TMPDIR/build

    # Build host-side draft list sort test
    cp $src/3ds/source/draft_list.h   $TMPDIR/build/
    cp $src/3ds/test/draft_list_test.cpp $TMPDIR/build/
    g++ -std=c++17 -I$TMPDIR/build \
      -o $out/bin/draft_list_test $TMPDIR/build/draft_list_test.cpp

    # Cross-compile 3DS in a subshell to avoid polluting PATH for fixupPhase
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
    list-sort = ''
      "$out/bin/draft_list_test"
    '';
    cross-compile = ''
      test -f "$out/typewriter.3dsx"
    '';
    magic-3dsx = ''
      ${pkgs.xxd}/bin/xxd -l 4 "$out/typewriter.3dsx" | grep -q "3344 5358"
    '';
  };
}).overrideAttrs (_: { dontStrip = true; })
