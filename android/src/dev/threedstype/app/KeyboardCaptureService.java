package dev.threedstype.app;

import android.accessibilityservice.AccessibilityService;
import android.content.SharedPreferences;
import android.hardware.input.InputManager;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.util.Log;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityEvent;
import android.widget.Toast;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class KeyboardCaptureService extends AccessibilityService {

    private static final String TAG = "3DSType";

    private static final int HID_A      = 0x001;
    private static final int HID_B      = 0x002;
    private static final int HID_SELECT = 0x004;
    private static final int HID_X      = 0x400;
    private static final int HID_Y      = 0x800;

    private static final int CHORD_MS       = 60;
    private static final int NAV_MS         = 30;
    private static final int GAP_MS         = 20;
    private static final int TYPING_DELAY_MS = 150;

    private enum AppMode { OFF, MENU, TYPING }
    private volatile AppMode mode = AppMode.OFF;

    private static final class Chord {
        final byte[] packet;
        final int    holdMs;
        Chord(byte[] p, int h) { packet = p; holdMs = h; }
    }

    private enum Phase { IDLE, GAP, CHORD }

    private final LinkedBlockingQueue<Chord> queue = new LinkedBlockingQueue<>();
    private Phase phase       = Phase.IDLE;
    private long  phaseEndsAt = 0;
    private Chord active      = null;

    private ScheduledExecutorService executor;
    private ExecutorService          saveExecutor;
    private ExecutorService          rootExecutor;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private PowerManager.WakeLock wakeLock;

    // Persistent root shell - started once, reused for all root commands.
    private Process    suProcess;
    private OutputStream suStdin;

    // Sysfs path for the physical keyboard's wakeup control file.
    // Detected from the first key event; null until detected.
    private volatile String kbWakeupPath = null;

    private volatile String ip        = null;
    private volatile int    port      = SettingsActivity.DEFAULT_PORT;
    private volatile String draftPath = SettingsActivity.DEFAULT_DRAFT_PATH;

    private final StringBuilder mirror = new StringBuilder();
    private String  saveFilename    = "current_draft.md";
    private boolean pendingNewDraft  = false;
    // Set when 'd' is pressed in MENU; cleared on confirm or cancel.
    private boolean pendingDelete    = false;
    private String  pendingDeleteFile = null;

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "3DSType:typing");
        wakeLock.setReferenceCounted(false);
        saveExecutor = Executors.newSingleThreadExecutor();
        rootExecutor = Executors.newSingleThreadExecutor();
        executor = Executors.newSingleThreadScheduledExecutor();
        executor.scheduleAtFixedRate(this::tick, 0, 16, TimeUnit.MILLISECONDS);
        // Start persistent root shell eagerly so first TYPING mode has no su latency.
        rootExecutor.execute(this::ensureRootShell);
        // Load prefs once; refresh on change via listener.
        SharedPreferences prefs = getSharedPreferences(SettingsActivity.PREFS, MODE_PRIVATE);
        loadPrefs(prefs);
        prefs.registerOnSharedPreferenceChangeListener((p, k) -> loadPrefs(p));
    }

    private void loadPrefs(SharedPreferences prefs) {
        ip        = prefs.getString(SettingsActivity.KEY_IP, null);
        port      = prefs.getInt(SettingsActivity.KEY_PORT, SettingsActivity.DEFAULT_PORT);
        draftPath = prefs.getString(SettingsActivity.KEY_DRAFT_PATH, SettingsActivity.DEFAULT_DRAFT_PATH);
    }

    // --- root shell ---

    private void ensureRootShell() {
        if (suProcess != null) {
            try { suProcess.exitValue(); } catch (IllegalThreadStateException e) { return; }
        }
        try {
            suProcess = Runtime.getRuntime().exec("su");
            suStdin   = suProcess.getOutputStream();
            Log.i(TAG, "root shell ready");
        } catch (Exception e) {
            Log.w(TAG, "su unavailable: " + e.getMessage());
        }
    }

    private void rootRun(String cmd) {
        rootExecutor.execute(() -> {
            try {
                ensureRootShell();
                if (suStdin != null) {
                    suStdin.write((cmd + "\n").getBytes("UTF-8"));
                    suStdin.flush();
                }
            } catch (Exception e) {
                Log.w(TAG, "root cmd failed: " + e.getMessage());
                suProcess = null; suStdin = null;
            }
        });
    }

    // --- keyboard wakeup control ---

    // Called from onKeyEvent to detect and cache the sysfs wakeup path.
    private void detectKeyboard(int deviceId) {
        if (kbWakeupPath != null) return;
        InputDevice dev = InputDevice.getDevice(deviceId);
        if (dev == null) return;
        if ((dev.getSources() & InputDevice.SOURCE_KEYBOARD) == 0) return;
        String name = dev.getName();
        if (name == null || name.isEmpty()) return;
        // Escape single quotes for safe shell embedding.
        String safeName = name.replace("'", "'\\''");
        // Find the sysfs wakeup file for this device name and cache it.
        rootExecutor.execute(() -> {
            try {
                ensureRootShell();
                if (suStdin == null) return;
                // Write the path to a temp file so we can read it back.
                String script =
                    "for d in /sys/class/input/input*/; do " +
                    "  n=$(cat \"${d}name\" 2>/dev/null); " +
                    "  if [ \"$n\" = '" + safeName + "' ]; then " +
                    "    w=\"${d}device/power/wakeup\"; " +
                    "    if [ -f \"$w\" ]; then echo \"$w\" > /data/local/tmp/3dstype_kbpath; fi; " +
                    "    break; " +
                    "  fi; " +
                    "done";
                suStdin.write((script + "\n").getBytes("UTF-8"));
                suStdin.flush();
                // Give the shell a moment then read the result.
                Thread.sleep(300);
                java.io.File f = new java.io.File("/data/local/tmp/3dstype_kbpath");
                if (f.exists()) {
                    // We have root so we can read this file.
                    Process p = Runtime.getRuntime().exec(new String[]{"su", "-c", "cat /data/local/tmp/3dstype_kbpath"});
                    byte[] buf = p.getInputStream().readAllBytes();
                    String path = new String(buf).trim();
                    if (!path.isEmpty()) {
                        kbWakeupPath = path;
                        Log.i(TAG, "keyboard wakeup path: " + kbWakeupPath);
                    }
                }
            } catch (Exception e) {
                Log.w(TAG, "keyboard detect failed: " + e.getMessage());
            }
        });
    }

    private void setKeyboardWakeup(boolean enabled) {
        String path = kbWakeupPath;
        if (path == null) return;
        rootRun("echo " + (enabled ? "enabled" : "disabled") + " > " + path);
    }

    // --- HID tick ---

    private void tick() {
        if (ip == null || ip.isEmpty() || mode == AppMode.OFF) return;

        long now = System.currentTimeMillis();

        switch (phase) {
            case IDLE: {
                Chord next = queue.poll();
                if (next != null) { active = next; phase = Phase.GAP; phaseEndsAt = now + GAP_MS; }
                break;
            }
            case GAP:
                if (now >= phaseEndsAt) { phase = Phase.CHORD; phaseEndsAt = now + active.holdMs; }
                break;
            case CHORD:
                if (now >= phaseEndsAt) {
                    Chord next = queue.poll();
                    if (next != null) { active = next; phase = Phase.GAP; phaseEndsAt = now + GAP_MS; }
                    else              { active = null;  phase = Phase.IDLE; }
                }
                break;
        }

        HidUdpDispatcher.sendRaw(
            phase == Phase.CHORD ? active.packet : HidUdpDispatcher.RELEASE, ip, port);
    }

    // --- input handling ---

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        if (event.getAction() != KeyEvent.ACTION_DOWN) return false;
        if (event.getRepeatCount() > 0) return false;

        int keyCode = event.getKeyCode();

        // Detect keyboard device from any incoming event (cached after first hit).
        detectKeyboard(event.getDeviceId());

        if (keyCode == KeyEvent.KEYCODE_ESCAPE) {
            switch (mode) {
                case OFF:
                    mode = AppMode.MENU;
                    toast("-- MENU --");
                    break;
                case MENU:
                    mode = AppMode.OFF;
                    queue.clear();
                    pendingDelete = false;
                    toast("Off");
                    break;
                case TYPING:
                    queue.clear();
                    leaveTyping();
                    if (ip != null && !ip.isEmpty())
                        queue.offer(new Chord(HidUdpDispatcher.buildPacket(HID_X | HID_Y), NAV_MS));
                    mode = AppMode.MENU;
                    toast("-- MENU --");
                    break;
            }
            return true;
        }

        if (mode == AppMode.OFF) return false;

        if (mode == AppMode.MENU) {
            if (ip == null || ip.isEmpty()) return true;
            switch (keyCode) {
                case KeyEvent.KEYCODE_DPAD_UP:
                case KeyEvent.KEYCODE_PAGE_UP:
                case KeyEvent.KEYCODE_K:
                case KeyEvent.KEYCODE_I:
                    queue.offer(new Chord(HidUdpDispatcher.buildPacket(HID_X), NAV_MS));
                    break;
                case KeyEvent.KEYCODE_DPAD_DOWN:
                case KeyEvent.KEYCODE_PAGE_DOWN:
                case KeyEvent.KEYCODE_J:
                case KeyEvent.KEYCODE_L:
                    queue.offer(new Chord(HidUdpDispatcher.buildPacket(HID_Y), NAV_MS));
                    break;
                case KeyEvent.KEYCODE_ENTER:
                case KeyEvent.KEYCODE_NUMPAD_ENTER:
                    queue.offer(new Chord(HidUdpDispatcher.buildPacket(HID_A), NAV_MS));
                    if (pendingDelete) {
                        deleteLocalFile(pendingDeleteFile);
                        pendingDelete = false;
                        pendingDeleteFile = null;
                    } else {
                        pendingNewDraft = false;
                        mainHandler.postDelayed(this::enterTyping, TYPING_DELAY_MS);
                    }
                    break;
                case KeyEvent.KEYCODE_N:
                    queue.offer(new Chord(HidUdpDispatcher.buildPacket(HID_SELECT), NAV_MS));
                    pendingNewDraft = true;
                    pendingDelete = false;
                    mainHandler.postDelayed(this::enterTyping, TYPING_DELAY_MS);
                    break;
                case KeyEvent.KEYCODE_D:
                    queue.offer(new Chord(HidUdpDispatcher.buildPacket(HID_B), NAV_MS));
                    pendingDelete = true;
                    pendingDeleteFile = saveFilename;
                    break;
                default:
                    break;
            }
            return true;
        }

        // TYPING mode
        if (ip == null || ip.isEmpty()) return false;

        if (keyCode == KeyEvent.KEYCODE_DEL) {
            if (mirror.length() > 0) mirror.deleteCharAt(mirror.length() - 1);
            queue.offer(new Chord(HidUdpDispatcher.buildPacket(ChordEncoder.encode(8)), CHORD_MS));
        } else if (keyCode == KeyEvent.KEYCODE_ENTER || keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER) {
            mirror.append('\n');
            queue.offer(new Chord(HidUdpDispatcher.buildPacket(ChordEncoder.encode(10)), CHORD_MS));
        } else {
            int unicode = keycodeToUnicode(keyCode, event.getMetaState());
            if (unicode <= 0) {
                int meta = event.getMetaState()
                    & (KeyEvent.META_SHIFT_ON | KeyEvent.META_SHIFT_LEFT_ON
                     | KeyEvent.META_SHIFT_RIGHT_ON | KeyEvent.META_CAPS_LOCK_ON);
                unicode = event.getUnicodeChar(meta);
            }
            if (unicode > 0) {
                int bitmask = ChordEncoder.encode(unicode);
                if (bitmask != 0) {
                    if (unicode >= 32 && unicode <= 126) mirror.append((char) unicode);
                    queue.offer(new Chord(HidUdpDispatcher.buildPacket(bitmask), CHORD_MS));
                }
            }
        }
        return true;
    }

    // --- mode transitions ---

    private void enterTyping() {
        if (mode != AppMode.MENU) return;
        mirror.setLength(0);
        saveFilename = pendingNewDraft
            ? new java.text.SimpleDateFormat("yyyyMMdd'T'HHmmss").format(new java.util.Date()) + ".md"
            : "current_draft.md";
        setKeyboardWakeup(false);
        mode = AppMode.TYPING;
        if (!wakeLock.isHeld()) wakeLock.acquire();
        toast("-- TYPING --");
    }

    private void leaveTyping() {
        setKeyboardWakeup(true);
        scheduleSave();
        // pendingDeleteFile tracks the last saved file so delete knows what to remove.
        pendingDeleteFile = saveFilename;
        if (wakeLock.isHeld()) wakeLock.release();
    }

    // --- save / delete ---

    private void scheduleSave() {
        final String content  = mirror.toString();
        final String path     = draftPath;
        final String filename = saveFilename;
        saveExecutor.submit(() -> {
            try {
                File dir = new File(path);
                if (!dir.exists()) dir.mkdirs();
                File f = new File(dir, filename);
                try (FileOutputStream fos = new FileOutputStream(f, false)) {
                    fos.write(content.getBytes("UTF-8"));
                }
            } catch (Exception e) {
                Log.w(TAG, "save failed: " + e.getMessage());
            }
        });
    }

    private void deleteLocalFile(String filename) {
        if (filename == null) return;
        final String path = draftPath;
        saveExecutor.submit(() -> {
            File f = new File(new File(path), filename);
            if (f.exists()) f.delete();
        });
    }

    // --- helpers ---

    private void toast(String msg) {
        mainHandler.post(() -> Toast.makeText(this, msg, Toast.LENGTH_SHORT).show());
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
        if (mode == AppMode.TYPING) leaveTyping();
        if (executor != null)     executor.shutdownNow();
        if (saveExecutor != null) saveExecutor.shutdown();
        if (rootExecutor != null) rootExecutor.shutdownNow();
        if (wakeLock != null && wakeLock.isHeld()) wakeLock.release();
        if (suProcess != null)    suProcess.destroy();
    }
}
