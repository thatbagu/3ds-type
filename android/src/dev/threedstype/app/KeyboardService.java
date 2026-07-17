package dev.threedstype.app;
public class KeyboardService {
    private ConnectionState state = ConnectionState.DISCONNECTED;
    public void setState(ConnectionState s) { this.state = s; }
    public ConnectionState getState() { return state; }
    public String getNotificationText() {
        switch (state) {
            case CONNECTING:    return "Connecting";
            case CONNECTED:     return "Connected";
            case DISCONNECTED:  return "Disconnected";
            default:            return "Unknown";
        }
    }
}
