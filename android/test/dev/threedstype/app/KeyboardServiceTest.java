package dev.threedstype.app;
public class KeyboardServiceTest {
    public static void notificationStates(String[] args) {
        KeyboardService svc = new KeyboardService();

        svc.setState(ConnectionState.CONNECTING);
        if (!svc.getNotificationText().equals("Connecting")) { System.err.println("FAIL: CONNECTING"); System.exit(1); }
        svc.setState(ConnectionState.CONNECTED);
        if (!svc.getNotificationText().equals("Connected")) { System.err.println("FAIL: CONNECTED"); System.exit(1); }
        svc.setState(ConnectionState.DISCONNECTED);
        if (!svc.getNotificationText().equals("Disconnected")) { System.err.println("FAIL: DISCONNECTED"); System.exit(1); }
        System.out.println("PASS"); System.exit(0);
    }
    public static void main(String[] args) throws Exception {
        if (args.length == 0) { System.err.println("Requires method arg"); System.exit(1); }
        KeyboardServiceTest.class.getMethod(args[0], String[].class).invoke(null, (Object)new String[]{});
    }
}
