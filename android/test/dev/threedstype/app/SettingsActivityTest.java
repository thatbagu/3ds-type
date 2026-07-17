package dev.threedstype.app;

public class SettingsActivityTest {
    public static void pathPersists(String[] args) {
        SettingsRepository repo = new SettingsRepository();
        String testPath = "/sdcard/typewriter/drafts";
        repo.setDraftPath(testPath);
        String got = repo.getDraftPath();
        if (!testPath.equals(got)) {
            System.err.println("FAIL: expected '" + testPath + "', got '" + got + "'");
            System.exit(1);
        }
        // Also verify port round-trip
        repo.setPort(9090);
        if (repo.getPort() != 9090) {
            System.err.println("FAIL: port not stored");
            System.exit(1);
        }
        System.out.println("PASS");
        System.exit(0);
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 0) {
            System.err.println("Usage: SettingsActivityTest pathPersists");
            System.exit(1);
        }
        SettingsActivityTest.class.getMethod(args[0], String[].class)
            .invoke(null, (Object) new String[]{});
    }
}
