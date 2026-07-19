package dev.threedstype.app;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.Settings;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

public class SettingsActivity extends Activity {

    static final String PREFS              = "3ds_type";
    static final String KEY_IP             = "ip";
    static final String KEY_PORT           = "port";
    static final String KEY_DRAFT_PATH     = "draft_path";
    static final int    DEFAULT_PORT       = 4950;
    static final String DEFAULT_DRAFT_PATH = "/sdcard/3dstype";

    private static final int REQUEST_PICK_FOLDER = 1;

    private EditText ipField, portField;
    private TextView pathDisplay;
    private String   selectedPath;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        selectedPath = prefs.getString(KEY_DRAFT_PATH, DEFAULT_DRAFT_PATH);

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

        addLabel(root, "Draft Save Folder");

        pathDisplay = new TextView(this);
        pathDisplay.setText(selectedPath);
        pathDisplay.setPadding(0, 8, 0, 8);
        root.addView(pathDisplay);

        Button browse = new Button(this);
        browse.setText("Browse...");
        browse.setOnClickListener(v -> openFolderPicker());
        root.addView(browse);

        if (Build.VERSION.SDK_INT >= 30 && !Environment.isExternalStorageManager()) {
            Button perm = new Button(this);
            perm.setText("Grant storage permission (required to save drafts)");
            perm.setOnClickListener(v -> {
                Intent i = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:" + getPackageName()));
                startActivity(i);
            });
            root.addView(perm);
        }

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

    private void openFolderPicker() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        // Hint to start inside the current selected folder if possible.
        Uri initialUri = Uri.parse(
            "content://com.android.externalstorage.documents/tree/primary%3A"
            + Uri.encode(selectedPath.replaceFirst("^/sdcard/", "")
                                     .replaceFirst("^/storage/emulated/0/", "")));
        intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri);
        startActivityForResult(intent, REQUEST_PICK_FOLDER);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_PICK_FOLDER && resultCode == RESULT_OK && data != null) {
            Uri treeUri = data.getData();
            String path = treeUriToPath(treeUri);
            if (path != null) {
                selectedPath = path;
                pathDisplay.setText(selectedPath);
            }
        }
    }

    // Converts a DocumentsContract tree URI from primary storage to a /sdcard/ path.
    private static String treeUriToPath(Uri uri) {
        try {
            String docId = DocumentsContract.getTreeDocumentId(uri);
            // docId looks like "primary:folder/sub" or "primary:"
            int colon = docId.indexOf(':');
            if (colon < 0) return null;
            String type = docId.substring(0, colon);
            String rel  = docId.substring(colon + 1);
            if (!"primary".equals(type)) return null; // external SD not supported
            String base = Environment.getExternalStorageDirectory().getAbsolutePath();
            return rel.isEmpty() ? base : base + "/" + rel;
        } catch (Exception e) {
            return null;
        }
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
            .putString(KEY_DRAFT_PATH, selectedPath)
            .apply();
        finish();
    }
}
