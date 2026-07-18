package dev.threedstype.app;

public class ChordEncoder {
    // Maps ASCII (0-127) to a HID bitmask, avoiding bits 3,4,7 (START/DRIGHT/DDOWN).
    // ASCII bits 0-2 -> HID bits 0-2 (A, B, SELECT)
    // ASCII bits 3-4 -> HID bits 5-6 (DLEFT, DUP)    [skip HID bits 3 and 4 = START/DRIGHT]
    // ASCII bits 5-6 -> HID bits 8-9 (R, L)          [skip HID bits 3,4,7 = START/DRIGHT/DDOWN]
    public static int encode(int ascii) {
        if (ascii <= 0 || ascii > 127) return 0;
        return (ascii & 0x07)
             | ((ascii & 0x18) << 2)
             | ((ascii & 0x60) << 3);
    }
}
