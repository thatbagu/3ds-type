package dev.threedstype.app;
import java.util.prefs.Preferences;

public class SettingsRepository {
    private static final String KEY_IP   = "ds_ip";
    private static final String KEY_PORT = "ds_port";
    private static final String KEY_PATH = "draft_path";
    private static final String DEFAULT_PORT = "4950";
    private static final String DEFAULT_PATH = "/sdcard/3dstype";

    private final Preferences prefs;

    public SettingsRepository() {
        this.prefs = Preferences.userNodeForPackage(SettingsRepository.class);
    }

    public SettingsRepository(Preferences prefs) {
        this.prefs = prefs;
    }

    public void setIp(String ip)       { prefs.put(KEY_IP, ip); }
    public String getIp()              { return prefs.get(KEY_IP, ""); }
    public void setPort(int port)      { prefs.put(KEY_PORT, String.valueOf(port)); }
    public int getPort()               { return Integer.parseInt(prefs.get(KEY_PORT, DEFAULT_PORT)); }
    public void setDraftPath(String p) { prefs.put(KEY_PATH, p); }
    public String getDraftPath()       { return prefs.get(KEY_PATH, DEFAULT_PATH); }
}
