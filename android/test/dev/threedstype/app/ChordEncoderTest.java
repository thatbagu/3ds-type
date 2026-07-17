package dev.threedstype.app;

public class ChordEncoderTest {
    public static void noCollision(String[] args) {
        // All entries: encode() results are unique and non-zero
        java.util.Set<Integer> seen = new java.util.HashSet<>();
        for (int ascii : ChordTable.ASCII_TO_BITMASK.keySet()) {
            int b = ChordEncoder.encode(ascii);
            if (b == 0) { System.err.println("FAIL: encode(" + ascii + ") == 0"); System.exit(1); }
            if (!seen.add(b)) { System.err.println("FAIL: collision at bitmask " + b); System.exit(1); }
        }
        System.out.println("PASS"); System.exit(0);
    }
    public static void roundTrip(String[] args) {
        for (int ascii : ChordTable.ASCII_TO_BITMASK.keySet()) {
            int b = ChordEncoder.encode(ascii);
            int back = ChordEncoder.decode(b);
            if (back != ascii) { System.err.println("FAIL: roundtrip for " + ascii); System.exit(1); }
        }
        System.out.println("PASS"); System.exit(0);
    }
    public static void main(String[] args) throws Exception {
        if (args.length == 0) { System.err.println("Usage: ChordEncoderTest <noCollision|roundTrip>"); System.exit(1); }
        ChordEncoderTest.class.getMethod(args[0], String[].class).invoke(null, (Object)new String[]{});
    }
}
