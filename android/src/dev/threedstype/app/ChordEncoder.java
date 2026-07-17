package dev.threedstype.app;

public class ChordEncoder {
    // Returns the 12-bit bitmask for the given ASCII code, or 0 if unmapped.
    public static int encode(int ascii) {
        Integer b = ChordTable.ASCII_TO_BITMASK.get(ascii);
        return b != null ? b : 0;
    }
    // Returns the ASCII code for a bitmask, or -1 if unmapped.
    public static int decode(int bitmask) {
        Integer a = ChordTable.BITMASK_TO_ASCII.get(bitmask);
        return a != null ? a : -1;
    }
}
