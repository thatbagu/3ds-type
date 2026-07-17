package dev.threedstype.app;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;

public class DraftStorage {
    private String storagePath;

    public DraftStorage(String storagePath) {
        this.storagePath = storagePath;
    }

    public void setStoragePath(String path) {
        this.storagePath = path;
    }

    public String getStoragePath() {
        return storagePath;
    }

    // Writes draft content to storagePath/draft_<timestamp>.txt
    // Returns the path of the saved file.
    public String saveDraft(String content) throws IOException {
        Path dir = Paths.get(storagePath);
        Files.createDirectories(dir);
        String filename = "draft_" + System.currentTimeMillis() + ".txt";
        Path file = dir.resolve(filename);
        Files.write(file, content.getBytes(StandardCharsets.UTF_8));
        return file.toString();
    }

    // Reads content from the given file path.
    public String readDraft(String filePath) throws IOException {
        return new String(Files.readAllBytes(Paths.get(filePath)), StandardCharsets.UTF_8);
    }
}
