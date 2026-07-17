#pragma once
#include <string>
#include <fstream>
#include <sstream>
#include <ctime>

class DraftManager {
public:
    // Returns the save directory (on real 3DS: "/3ds/typewriter/", in tests: override)
    static std::string defaultDir() { return "/3ds/typewriter/"; }

    // Constructs a filename: YYYYMMDDTHHMMSS.txt
    static std::string makeFilename() {
        std::time_t now = std::time(nullptr);
        char buf[20];
        std::strftime(buf, sizeof(buf), "%Y%m%dT%H%M%S", std::localtime(&now));
        return std::string(buf) + ".txt";
    }

    // Saves content to dir/TIMESTAMP.txt. Returns the full path.
    // Creates dir if it doesn't exist (on host; on 3DS the dir must pre-exist on SD).
    static std::string save(const std::string& content, const std::string& dir = defaultDir()) {
        // ensure trailing slash
        std::string d = dir;
        if (!d.empty() && d.back() != '/') d += '/';
        std::string path = d + makeFilename();
        // On host, create directory (ignore failure on 3DS)
        std::string cmd = "mkdir -p \"" + d + "\"";
        system(cmd.c_str());
        std::ofstream f(path);
        f << content;
        return path;
    }
};
