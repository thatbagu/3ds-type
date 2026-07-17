package dev.threedstype.app;

// Luma3DS InputRedirect UDP dispatcher (port 4950, 20-byte packet format).
public class HidUdpDispatcher {
    // Serializes a bitmask into the 20-byte Luma3DS InputRedirect packet.
    // Bytes 0-3: bitmask as u32 LE. Bytes 4-19: zeros.
    public static byte[] buildPacket(int bitmask) {
        byte[] pkt = new byte[20];
        pkt[0] = (byte)(bitmask & 0xFF);
        pkt[1] = (byte)((bitmask >> 8) & 0xFF);
        pkt[2] = (byte)((bitmask >> 16) & 0xFF);
        pkt[3] = (byte)((bitmask >> 24) & 0xFF);
        return pkt;
    }
}
