# T009: 3DS TextBuffer host-side unit test
# Compiles text_buffer.cpp as a native x86_64 test binary and exercises:
# word-wrap at the 400px-wide top screen boundary (~53 chars at default
# font size), backspace (removes last char), and newline (starts new line).
# Depends: T007 (3DS source tree with text_buffer.cpp)
{ pkgs, amonite }:

amonite.mkTask {
  id = "T009";
  title = "3DS TextBuffer host-side unit test — word-wrap, backspace, newline";

  src = ../..;

  env = with pkgs; [
    gcc
    gnumake
    coreutils
  ];

  build = ''
    mkdir -p $out/bin $TMPDIR/build
    cp $src/3ds/source/text_buffer.h $TMPDIR/build/
    cp $src/3ds/test/text_buffer_test.cpp $TMPDIR/build/
    g++ -std=c++17 -I$TMPDIR/build -o $out/bin/text_buffer_test $TMPDIR/build/text_buffer_test.cpp
  '';

  verify = {
    word-wrap = ''
      "$out/bin/text_buffer_test" word-wrap
    '';
    backspace = ''
      "$out/bin/text_buffer_test" backspace
    '';
    newline = ''
      "$out/bin/text_buffer_test" newline
    '';
  };
}
