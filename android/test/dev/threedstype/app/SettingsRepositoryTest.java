package dev.threedstype.app;
import java.util.prefs.Preferences;
public class SettingsRepositoryTest {
    public static void roundTrip(String[] args) {
        // Use a fresh in-memory Preferences node per run
        Preferences prefs = Preferences.userRoot().node("test-" + System.nanoTime());
        SettingsRepository repo = new SettingsRepository(prefs);

        repo.setIp("192.168.1.100");
        repo.setPort(4950);
        repo.setDraftPath("/sdcard/drafts");

        if (!repo.getIp().equals("192.168.1.100")) { System.err.println("FAIL: IP"); System.exit(1); }
        if (repo.getPort() != 4950)                { System.err.println("FAIL: port"); System.exit(1); }
        if (!repo.getDraftPath().equals("/sdcard/drafts")) { System.err.println("FAIL: path"); System.exit(1); }
        System.out.println("PASS"); System.exit(0);
    }
    public static void main(String[] args) throws Exception {
        if (args.length == 0) { System.err.println("Requires method arg"); System.exit(1); }
        SettingsRepositoryTest.class.getMethod(args[0], String[].class).invoke(null, (Object)new String[]{});
    }
}
