#pragma once
#include <string>
#include <vector>
#include <dirent.h>
#include <sys/stat.h>
#include <algorithm>
#include <ctime>

struct DraftEntry {
    std::string name;
    std::time_t mtime;
    DraftEntry(std::string n, std::time_t t) : name(std::move(n)), mtime(t) {}
};

class DraftList {
public:
    static std::vector<DraftEntry> list(const std::string& dir) {
        std::vector<DraftEntry> entries;
        DIR* d = opendir(dir.c_str());
        if (!d) return entries;
        struct dirent* ent;
        while ((ent = readdir(d)) != nullptr) {
            std::string name(ent->d_name);
            if (name.size() < 3 || name.substr(name.size()-3) != ".md") continue;
            std::string path = dir + "/" + name;
            struct stat st;
            if (stat(path.c_str(), &st) == 0) {
                entries.push_back({name, (std::time_t)st.st_mtime});
            }
        }
        closedir(d);
        std::sort(entries.begin(), entries.end(),
                  [](const DraftEntry& a, const DraftEntry& b){ return a.mtime > b.mtime; });
        return entries;
    }
};
