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
    gradle
    coreutils
  ];

  build = ''echo "T003 not yet implemented" >&2 && exit 1'';

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
