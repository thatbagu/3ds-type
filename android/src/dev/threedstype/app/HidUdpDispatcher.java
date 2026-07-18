package dev.threedstype.app;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;

public class HidUdpDispatcher {

    // 0x0FFF in LE: all bits 0-11 set -> after HID inversion = 0 = no buttons pressed
    static final byte[] RELEASE = new byte[20];
    static {
        RELEASE[0] = (byte)0xFF;
        RELEASE[1] = (byte)0x0F;
    }

    public static byte[] buildPacket(int bitmask) {
        byte[] pkt = new byte[20];
        int raw = (~bitmask) & 0x0FFF;
        pkt[0] = (byte)(raw & 0xFF);
        pkt[1] = (byte)((raw >> 8) & 0xFF);
        return pkt;
    }

    // Persistent socket -- created once, reused for every packet in the stream.
    private static DatagramSocket sock;
    private static InetAddress    addr;
    private static String         lastHost;

    // Called from a single background thread, so no locking needed.
    static void sendRaw(byte[] pkt, String host, int port) {
        try {
            if (sock == null || sock.isClosed() || !host.equals(lastHost)) {
                if (sock != null && !sock.isClosed()) sock.close();
                sock     = new DatagramSocket();
                addr     = InetAddress.getByName(host);
                lastHost = host;
            }
            sock.send(new DatagramPacket(pkt, pkt.length, addr, port));
        } catch (Exception e) {
            sock = null; // force reconnect on next call
        }
    }
}
