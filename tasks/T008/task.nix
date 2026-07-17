# T008: 3DS ChordDecoder host-side unit test
# Compiles chord_decoder.cpp (and chord_table.h from T001) as a native
# x86_64 binary and runs a round-trip test: for every entry c in the
# chord table, assert chord_to_char(chord_from_char(c)) == c.
# This test is the single hermetic proof that both sides of the wire agree.
# Depends: T001 (chord_table.h), T007 (3DS source tree structure)
{ pkgs, amonite }:

amonite.mkTask {
  id = "T008";
  title = "3DS ChordDecoder host-side unit test — round-trip identity with T001 table";

  src = ../..;

  env = with pkgs; [
    gcc
    gnumake
    python3
    coreutils
  ];

  build = ''
    mkdir -p $out/bin $TMPDIR/build
    # Re-run the chord table generator to produce chord_table.h from source
    python3 $src/src/chord_table/generate.py $TMPDIR/build
    cp $src/3ds/source/chord_decoder.h $TMPDIR/build/
    cp $src/3ds/test/chord_decoder_test.cpp $TMPDIR/build/
    g++ -std=c++17 -I$TMPDIR/build -o $out/bin/chord_decoder_test $TMPDIR/build/chord_decoder_test.cpp
  '';

  verify = {
    roundtrip = ''
      "$out/bin/chord_decoder_test"
    '';
  };
}
