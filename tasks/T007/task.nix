# T007: 3DS project scaffold
# Minimal devkitPro/devkitARM project: Makefile, citro2d boilerplate,
# empty main loop that compiles and links to typewriter.3dsx.
# Uses bandithedoge/devkitNix overlay (wired into project flake.nix)
# to provide devkitARM cross-compiler + libctru for 3DS.
{ pkgs, amonite }:

let
  devkitARM = pkgs.devkitNix.devkitARM;
  devkitPRO = "${devkitARM}/opt/devkitpro";
in

(amonite.mkTask {
  id = "T007";
  title = "3DS project scaffold — Makefile, devkitPro, citro2d boilerplate, cross-compile to typewriter.3dsx";

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
