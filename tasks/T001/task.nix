# Task definition — the single source of truth for this task.
# Referenced by BOTH this capsule's flake (for encapsulated dev/verify)
# and the project flake (for aggregate verification and clustering).
{ pkgs, amonite }:

amonite.mkTask {
  id = "T001"; # amonite task id, matches tasks.md
  title = "Chord table generator — chord_table.h + ChordTable.kt + no-collision test";

  # Source this task builds from. Usually the project root filtered to
  # what the task may see — keep the aperture as narrow as possible.
  src = ../..;

  # Encapsulation boundary: everything this task's build and dev shell
  # may use. Nothing else is available.
  env = with pkgs; [
    python3
    gcc
    coreutils
  ];

  # Build: produce the task's artifacts under $out.
  build = ''
    mkdir -p $out/bin
    python3 $src/src/chord_table/generate.py $out
    cp $src/src/chord_table/chord_table_test.cpp $TMPDIR/chord_table_test.cpp
    cp $out/chord_table.h $TMPDIR/chord_table.h
    g++ -std=c++17 -I$TMPDIR -o $out/bin/chord_table_test $TMPDIR/chord_table_test.cpp
  '';

  # Acceptance criteria from tasks.md, made mechanical. Every entry must
  # exit 0 or the task does not exist as a derivation.
  verify = {
    no-collision = ''
      # Run the generator's self-test: unique bitmasks, none 0x000, none 0x00C
      "$out/bin/chord_table_test" --no-collision
    '';
    cpp-header = ''
      test -f "$out/chord_table.h"
      ${pkgs.gcc}/bin/gcc -x c++ -std=c++17 "$out/chord_table.h" -fsyntax-only
    '';
    kotlin-object = ''
      test -f "$out/ChordTable.kt"
      grep -q "^object ChordTable" "$out/ChordTable.kt"
    '';
  };
}
