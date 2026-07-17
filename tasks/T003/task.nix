# T003: AccessibilityService + ChordEncoder + HidUdpDispatcher
# Captures keyboard KeyEvents, maps each to a 12-bit bitmask from the
# shared chord table (T001), serialises into a 20-byte Luma3DS HID UDP
# packet, and dispatches to the configured 3DS IP:4950.
# Depends: T001 (chord_table artifacts), T002 (Android project scaffold)
{ pkgs, amonite }:

amonite.mkTask {
  id = "T003";
  title = "AccessibilityService + ChordEncoder + HidUdpDispatcher";

  src = ../..;

  env = with pkgs; [
    jdk17
    bash
    coreutils
  ];

  build = ''
    set -euo pipefail
    WORK=$TMPDIR/t003
    mkdir -p $WORK/classes $out/bin

    # Compile all sources and tests together
    javac -cp $WORK/classes \
      -d $WORK/classes \
      $src/android/src/dev/threedstype/app/ChordTable.java \
      $src/android/src/dev/threedstype/app/ChordEncoder.java \
      $src/android/src/dev/threedstype/app/HidUdpDispatcher.java \
      $src/android/test/dev/threedstype/app/ChordEncoderTest.java \
      $src/android/test/dev/threedstype/app/HidUdpDispatcherTest.java

    cp -r $WORK/classes $out/classes

    cat > $out/bin/run-tests << WRAPPER
#!${pkgs.bash}/bin/bash
IFS='.' read -r CLASS METHOD <<< "\$1"
exec java -cp "\$(dirname "\$0")/../classes" "dev.threedstype.app.\$CLASS" "\$METHOD"
WRAPPER
    chmod +x $out/bin/run-tests
  '';

  verify = {
    encoder-no-collision = ''
      "$out/bin/run-tests" ChordEncoderTest.noCollision
    '';
    encoder-roundtrip = ''
      "$out/bin/run-tests" ChordEncoderTest.roundTrip
    '';
    udp-payload = ''
      "$out/bin/run-tests" HidUdpDispatcherTest.payloadFormat
    '';
  };
}
