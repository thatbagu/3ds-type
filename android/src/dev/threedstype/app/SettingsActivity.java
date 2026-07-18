package dev.threedstype.app;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

public class SettingsActivity extends Activity {

    static final String PREFS = "3ds_type";
    static final String KEY_IP = "ip";
    static final String KEY_PORT = "port";
    static final String KEY_DRAFT_PATH = "draft_path";
    static final int DEFAULT_PORT = 4950;
    static final String DEFAULT_DRAFT_PATH = "/sdcard/3dstype";

    private EditText ipField, portField, pathField;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(48, 48, 48, 48);

        addLabel(root, "3DS IP Address");
        ipField = new EditText(this);
        ipField.setText(prefs.getString(KEY_IP, ""));
        ipField.setHint("192.168.1.xxx");
        root.addView(ipField);

        addLabel(root, "UDP Port");
        portField = new EditText(this);
        portField.setText(String.valueOf(prefs.getInt(KEY_PORT, DEFAULT_PORT)));
        root.addView(portField);

        addLabel(root, "Draft Save Path");
        pathField = new EditText(this);
        pathField.setText(prefs.getString(KEY_DRAFT_PATH, DEFAULT_DRAFT_PATH));
        root.addView(pathField);

        Button save = new Button(this);
        save.setText("Save");
        save.setOnClickListener(v -> saveAndFinish());
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.topMargin = 32;
        root.addView(save, lp);

        ScrollView scroll = new ScrollView(this);
        scroll.addView(root);
        setContentView(scroll);
    }

    private void addLabel(LinearLayout parent, String text) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setPadding(0, 24, 0, 4);
        parent.addView(tv);
    }

    private void saveAndFinish() {
        int port;
        try {
            port = Integer.parseInt(portField.getText().toString().trim());
        } catch (NumberFormatException e) {
            port = DEFAULT_PORT;
        }
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .putString(KEY_IP, ipField.getText().toString().trim())
            .putInt(KEY_PORT, port)
            .putString(KEY_DRAFT_PATH, pathField.getText().toString().trim())
            .apply();
        finish();
    }
}
