package dev.threedstype.app;
import java.io.*;
import java.nio.file.*;

public class DraftStorageTest {
    public static void writeAndReadBack(String[] args) throws Exception {
        Path tmpDir = Files.createTempDirectory("draft-test-");
        DraftStorage storage = new DraftStorage(tmpDir.toString());
        String content = "Hello, 3DS Type!\nThis is a test draft.";
        String savedPath = storage.saveDraft(content);
        String readBack = storage.readDraft(savedPath);
        if (!readBack.equals(content)) {
            System.err.println("FAIL: content mismatch");
            System.err.println("Expected: " + content);
            System.err.println("Got: " + readBack);
            System.exit(1);
        }
        System.out.println("PASS");
        System.exit(0);
    }

    public static void pathConfigurable(String[] args) throws Exception {
        Path tmpDir1 = Files.createTempDirectory("draft-test-1-");
        Path tmpDir2 = Files.createTempDirectory("draft-test-2-");
        DraftStorage storage = new DraftStorage(tmpDir1.toString());

        if (!storage.getStoragePath().equals(tmpDir1.toString())) {
            System.err.println("FAIL: initial path wrong");
            System.exit(1);
        }

        storage.setStoragePath(tmpDir2.toString());
        if (!storage.getStoragePath().equals(tmpDir2.toString())) {
            System.err.println("FAIL: updated path wrong");
            System.exit(1);
        }

        // Verify it actually saves to the new path
        String saved = storage.saveDraft("test content");
        if (!saved.startsWith(tmpDir2.toString())) {
            System.err.println("FAIL: file saved to wrong path: " + saved);
            System.exit(1);
        }
        System.out.println("PASS");
        System.exit(0);
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 0) { System.err.println("Requires method arg"); System.exit(1); }
        DraftStorageTest.class.getMethod(args[0], String[].class).invoke(null, (Object)new String[]{});
    }
}
