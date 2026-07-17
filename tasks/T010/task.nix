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

amonite.mkTask {
  id = "T010";
  title = "3DS TypewriterRenderer — citro2d top screen (text+cursor) + bottom screen (status line)";

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
      ${pkgs.xxd}/bin/xxd -l 4 "$out/typewriter.3dsx" | grep -q "3344 5358"
    '';
  };
}
