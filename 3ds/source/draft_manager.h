#pragma once
#include <string>
#include <fstream>
#include <sstream>
#include <ctime>
#include <sys/stat.h>

class DraftManager {
public:
    static std::string defaultDir() { return "sdmc:/3ds/typewriter"; }

    static void ensureDir(const std::string& dir) {
        mkdir(dir.c_str(), 0755);
    }

    static std::string makeFilename() {
        std::time_t now = std::time(nullptr);
        char buf[20];
        std::strftime(buf, sizeof(buf), "%Y%m%dT%H%M%S", std::localtime(&now));
        return std::string(buf) + ".md";
    }

    static std::string load(const std::string& path) {
        std::ifstream f(path);
        if (!f) return "";
        std::ostringstream ss;
        ss << f.rdbuf();
        return ss.str();
    }

    // Save content to an explicit path.
    static void saveTo(const std::string& content, const std::string& path) {
        std::ofstream f(path);
        f << content;
    }

    // Save content as a new timestamped file under dir. Returns the path.
    static std::string save(const std::string& content,
                            const std::string& dir = defaultDir()) {
        ensureDir(dir);
        std::string path = dir + "/" + makeFilename();
        saveTo(content, path);
        return path;
    }
};
