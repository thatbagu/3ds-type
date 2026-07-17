# T010: 3DS TypewriterRenderer (citro2d)
# Implements the visual layer: top screen renders TextBuffer lines as
# off-white text on near-black background with a blinking block cursor;
# bottom screen shows the single status line (word count / connection
# state / save hint). Uses citro2d; no consoleInit.
# Verification is cross-compilation only — citro2d cannot run on host.
# Depends: T007 (3DS scaffold), T009 (TextBuffer)
{ pkgs, amonite }:

amonite.mkTask {
  id = "T010";
  title = "3DS TypewriterRenderer — citro2d top screen (text+cursor) + bottom screen (status line)";

  src = ../..;

  env = with pkgs; [
    gcc
    gnumake
    xxd
    coreutils
  ];

  build = ''echo "T010 not yet implemented" >&2 && exit 1'';

  verify = {
    cross-compile = ''
      test -f "$out/typewriter.3dsx"
    '';
    magic-3dsx = ''
      ${pkgs.xxd}/bin/xxd -l 4 "$out/typewriter.3dsx" | grep -q "3344 5358"
    '';
  };
}
