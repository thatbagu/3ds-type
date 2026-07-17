package dev.threedstype.app;

public class HidUdpDispatcherTest {
    public static void payloadFormat(String[] args) {
        // Encode 'H' (ASCII 72), build packet, check: length==20, bytes 0-3 == bitmask LE, bytes 4-19 == 0
        int bitmask = ChordEncoder.encode(72); // 'H'
        byte[] pkt = HidUdpDispatcher.buildPacket(bitmask);
        if (pkt.length != 20) { System.err.println("FAIL: packet length " + pkt.length); System.exit(1); }
        int reconstructed = (pkt[0]&0xFF)|((pkt[1]&0xFF)<<8)|((pkt[2]&0xFF)<<16)|((pkt[3]&0xFF)<<24);
        if (reconstructed != bitmask) { System.err.println("FAIL: bitmask mismatch"); System.exit(1); }
        for (int i = 4; i < 20; i++) { if (pkt[i] != 0) { System.err.println("FAIL: byte " + i + " != 0"); System.exit(1); } }
        System.out.println("PASS"); System.exit(0);
    }
    public static void main(String[] args) throws Exception {
        if (args.length == 0) { System.err.println("Usage: HidUdpDispatcherTest payloadFormat"); System.exit(1); }
        HidUdpDispatcherTest.class.getMethod(args[0], String[].class).invoke(null, (Object)new String[]{});
    }
}
