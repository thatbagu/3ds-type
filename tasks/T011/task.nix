# T011: 3DS HidPoller + main loop
# The 60fps frame loop: hidScanInput() → hidKeysDown() → ChordDecoder
# → TextBuffer → TypewriterRenderer, plus key-up packet timing (16ms
# blank packet after each key-down). Also builds a host-side stub test
# that feeds 5 synthetic bitmasks and asserts the buffer contains the
# expected 5 characters.
# Depends: T001 (chord table), T008 (ChordDecoder), T009 (TextBuffer), T010 (Renderer)
{ pkgs, amonite }:

amonite.mkTask {
  id = "T011";
  title = "3DS HidPoller + main loop — hidKeysDown → ChordDecoder → TextBuffer → TypewriterRenderer";

  src = ../..;

  env = with pkgs; [
    gcc
    gnumake
    xxd
    coreutils
  ];

  build = ''echo "T011 not yet implemented" >&2 && exit 1'';

  verify = {
    cross-compile = ''
      test -f "$out/typewriter.3dsx"
    '';
    magic-3dsx = ''
      ${pkgs.xxd}/bin/xxd -l 4 "$out/typewriter.3dsx" | grep -q "3344 5358"
    '';
    host-integration = ''
      "$out/bin/hid_loop_test"
    '';
  };
}
