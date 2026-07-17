# T012: 3DS DraftManager save
# On START press: constructs /3ds/typewriter/<ISO-timestamp>.txt path,
# serialises TextBuffer content, writes via std::ofstream. Host-side
# test writes to $TMPDIR and diffs output against expected string.
# Timestamp filename is validated against regex [0-9]{8}T[0-9]{6}\.txt.
# Depends: T007 (3DS scaffold), T009 (TextBuffer)
{ pkgs, amonite }:

amonite.mkTask {
  id = "T012";
  title = "3DS DraftManager save — SD path construction, ISO timestamp, write via ofstream";

  src = ../..;

  env = with pkgs; [
    gcc
    gnumake
    coreutils
    gnugrep
  ];

  build = ''
    mkdir -p $out/bin $TMPDIR/build
    cp $src/3ds/source/draft_manager.h $TMPDIR/build/
    cp $src/3ds/test/draft_save_test.cpp $TMPDIR/build/
    g++ -std=c++17 -I$TMPDIR/build -o $out/bin/draft_save_test $TMPDIR/build/draft_save_test.cpp
  '';

  verify = {
    save-content = ''
      "$out/bin/draft_save_test" --content
    '';
    path-format = ''
      "$out/bin/draft_save_test" --path-format
    '';
  };
}
