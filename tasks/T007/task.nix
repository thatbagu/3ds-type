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

amonite.mkTask {
  id = "T007";
  title = "3DS project scaffold — Makefile, devkitPro, citro2d boilerplate, cross-compile to typewriter.3dsx";

  src = ../..;

  env = with pkgs; [
    devkitARM
    gnumake
    bash
    xxd
    coreutils
  ];

  build = ''
    export DEVKITPRO="${devkitPRO}"
    export DEVKITARM="${devkitPRO}/devkitARM"
    export CTRULIB="${devkitPRO}/libctru"
    export PATH="$DEVKITARM/bin:${devkitPRO}/tools/bin:$PATH"
    # Copy source to a writable build directory (Nix store is read-only)
    cp -r $src/3ds $TMPDIR/3ds
    chmod -R u+w $TMPDIR/3ds
    cd $TMPDIR/3ds
    make SHELL=${pkgs.bash}/bin/bash
    mkdir -p $out
    cp typewriter.3dsx $out/typewriter.3dsx
  '';

  verify = {
    cross-compile = ''
      test -f "$out/typewriter.3dsx"
    '';
    magic-3dsx = ''
      # 3DSX magic: bytes 0-3 = "3DSX" = 0x33 0x44 0x53 0x58
      ${pkgs.xxd}/bin/xxd -l 4 "$out/typewriter.3dsx" | grep -q "3344 5358"
    '';
  };
}
