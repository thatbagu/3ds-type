package dev.threedstype.app;

import android.accessibilityservice.AccessibilityService;
import android.content.SharedPreferences;
import android.util.Log;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityEvent;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class KeyboardCaptureService extends AccessibilityService {

    private static final String TAG = "3DSType";

    // KEY_X/KEY_Y are bits 10-11, outside chord encoding range, safe for scroll.
    private static final int SCROLL_DOWN = 1024; // KEY_X = BIT(10)
    private static final int SCROLL_UP   = 2048; // KEY_Y = BIT(11)

    private static final int CHORD_MS  = 60;
    private static final int SCROLL_MS = 30;
    private static final int GAP_MS    = 20;

    private static final class Chord {
        final byte[] packet;
        final int    holdMs;
        Chord(byte[] p, int h) { packet = p; holdMs = h; }
    }

    private enum Phase { IDLE, GAP, CHORD }

    // Queue is thread-safe; written from the accessibility thread, drained by tick.
    private final LinkedBlockingQueue<Chord> queue = new LinkedBlockingQueue<>();

    // State machine: only accessed from the single executor thread, no sync needed.
    private Phase phase       = Phase.IDLE;
    private long  phaseEndsAt = 0;
    private Chord active      = null;

    private ScheduledExecutorService executor;
    // Written by tick (executor thread), read by onKeyEvent (accessibility thread).
    private volatile String ip   = null;
    private volatile int    port = SettingsActivity.DEFAULT_PORT;

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        executor = Executors.newSingleThreadScheduledExecutor();
        executor.scheduleAtFixedRate(this::tick, 0, 16, TimeUnit.MILLISECONDS);
    }

    private void tick() {
        SharedPreferences prefs = getSharedPreferences(SettingsActivity.PREFS, MODE_PRIVATE);
        ip   = prefs.getString(SettingsActivity.KEY_IP, null);
        port = prefs.getInt(SettingsActivity.KEY_PORT, SettingsActivity.DEFAULT_PORT);
        if (ip == null || ip.isEmpty()) return;

        long now = System.currentTimeMillis();

        // Advance state machine.
        switch (phase) {
            case IDLE: {
                Chord next = queue.poll();
                if (next != null) {
                    active = next;
                    phase = Phase.GAP;
                    phaseEndsAt = now + GAP_MS;
                }
                break;
            }
            case GAP:
                if (now >= phaseEndsAt) {
                    phase = Phase.CHORD;
                    phaseEndsAt = now + active.holdMs;
                }
                break;
            case CHORD:
                if (now >= phaseEndsAt) {
                    Chord next = queue.poll();
                    if (next != null) {
                        active = next;
                        phase = Phase.GAP;
                        phaseEndsAt = now + GAP_MS;
                    } else {
                        active = null;
                        phase = Phase.IDLE;
                    }
                }
                break;
        }

        // Send chord when active, RELEASE otherwise (GAP and IDLE both send RELEASE).
        byte[] out = (phase == Phase.CHORD) ? active.packet : HidUdpDispatcher.RELEASE;
        HidUdpDispatcher.sendRaw(out, ip, port);
    }

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        if (event.getAction() != KeyEvent.ACTION_DOWN) return false;
        if (event.getRepeatCount() > 0) return false;
        if (ip == null || ip.isEmpty()) return false;

        int keyCode = event.getKeyCode();

        if (keyCode == KeyEvent.KEYCODE_DPAD_UP || keyCode == KeyEvent.KEYCODE_PAGE_UP) {
            queue.offer(new Chord(HidUdpDispatcher.buildPacket(SCROLL_UP), SCROLL_MS));
            return false;
        }
        if (keyCode == KeyEvent.KEYCODE_DPAD_DOWN || keyCode == KeyEvent.KEYCODE_PAGE_DOWN) {
            queue.offer(new Chord(HidUdpDispatcher.buildPacket(SCROLL_DOWN), SCROLL_MS));
            return false;
        }
        if (keyCode == KeyEvent.KEYCODE_DEL) {
            queue.offer(new Chord(HidUdpDispatcher.buildPacket(ChordEncoder.encode(8)), CHORD_MS));
            return false;
        }
        if (keyCode == KeyEvent.KEYCODE_ENTER || keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER) {
            queue.offer(new Chord(HidUdpDispatcher.buildPacket(ChordEncoder.encode(10)), CHORD_MS));
            return false;
        }

        int unicode = keycodeToUnicode(keyCode, event.getMetaState());
        if (unicode <= 0) {
            int meta = event.getMetaState()
                & (KeyEvent.META_SHIFT_ON | KeyEvent.META_SHIFT_LEFT_ON
                 | KeyEvent.META_SHIFT_RIGHT_ON | KeyEvent.META_CAPS_LOCK_ON);
            unicode = event.getUnicodeChar(meta);
        }
        if (unicode <= 0) return false;

        int bitmask = ChordEncoder.encode(unicode);
        Log.w(TAG, "keyCode=" + keyCode + " -> '" + (char)unicode + "'(" + unicode + ") bitmask=" + bitmask);
        if (bitmask == 0) return false;

        queue.offer(new Chord(HidUdpDispatcher.buildPacket(bitmask), CHORD_MS));
        return false;
    }

    private static int keycodeToUnicode(int kc, int meta) {
        if (kc >= KeyEvent.KEYCODE_A && kc <= KeyEvent.KEYCODE_Z) {
            boolean shift = (meta & (KeyEvent.META_SHIFT_ON | KeyEvent.META_SHIFT_LEFT_ON
                                   | KeyEvent.META_SHIFT_RIGHT_ON)) != 0;
            boolean caps  = (meta & KeyEvent.META_CAPS_LOCK_ON) != 0;
            char c = (char)('a' + (kc - KeyEvent.KEYCODE_A));
            return (shift ^ caps) ? Character.toUpperCase(c) : c;
        }
        if (kc >= KeyEvent.KEYCODE_0 && kc <= KeyEvent.KEYCODE_9) {
            boolean shift = (meta & (KeyEvent.META_SHIFT_ON | KeyEvent.META_SHIFT_LEFT_ON
                                   | KeyEvent.META_SHIFT_RIGHT_ON)) != 0;
            if (!shift) return '0' + (kc - KeyEvent.KEYCODE_0);
            return "!@#$%^&*()".charAt(kc - KeyEvent.KEYCODE_0);
        }
        if (kc == KeyEvent.KEYCODE_SPACE) return ' ';
        switch (kc) {
            case KeyEvent.KEYCODE_PERIOD:     return '.';
            case KeyEvent.KEYCODE_COMMA:      return ',';
            case KeyEvent.KEYCODE_MINUS:      return '-';
            case KeyEvent.KEYCODE_EQUALS:     return '=';
            case KeyEvent.KEYCODE_APOSTROPHE: return '\'';
            default:                          return 0;
        }
    }

    @Override public void onAccessibilityEvent(AccessibilityEvent event) {}
    @Override public void onInterrupt() {}

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (executor != null) executor.shutdownNow();
    }
}
