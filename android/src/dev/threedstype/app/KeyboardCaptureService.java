package dev.threedstype.app;

import android.accessibilityservice.AccessibilityService;
import android.view.accessibility.AccessibilityEvent;

/**
 * Scaffold stub for KeyboardCaptureService.
 * Receives accessibility events (key presses, text changes) and will
 * forward them to the 3DS over a network socket in a future task.
 */
public class KeyboardCaptureService extends AccessibilityService {

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // TODO: capture key events and forward to 3DS
    }

    @Override
    public void onInterrupt() {
        // no-op for scaffold
    }
}
