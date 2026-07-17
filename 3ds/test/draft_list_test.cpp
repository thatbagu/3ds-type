#include "draft_list.h"
#include <cassert>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sys/time.h>

int main() {
    char tmp[] = "/tmp/draft_list_XXXXXX";
    char* dir = mkdtemp(tmp);
    if (!dir) { std::cerr << "FAIL: mkdtemp\n"; return 1; }

    // Create 3 files
    std::string a = std::string(dir) + "/a.txt";
    std::string b = std::string(dir) + "/b.txt";
    std::string c = std::string(dir) + "/c.txt";
    for (auto& p : {a, b, c}) { std::ofstream f(p); f << "x"; }

    // Set mtimes: a=1000, b=2000, c=3000 (c is newest)
    struct timeval tv[2];
    tv[0].tv_sec = 0; tv[0].tv_usec = 0;
    tv[1].tv_usec = 0;
    tv[1].tv_sec = 1000; utimes(a.c_str(), tv);
    tv[1].tv_sec = 2000; utimes(b.c_str(), tv);
    tv[1].tv_sec = 3000; utimes(c.c_str(), tv);

    auto entries = DraftList::list(dir);
    if (entries.size() != 3) {
        std::cerr << "FAIL: expected 3, got " << entries.size() << "\n"; return 1;
    }
    if (entries[0].name != "c.txt" || entries[1].name != "b.txt" || entries[2].name != "a.txt") {
        std::cerr << "FAIL: wrong order: "
                  << entries[0].name << " " << entries[1].name << " " << entries[2].name << "\n";
        return 1;
    }
    std::cout << "PASS\n";
    return 0;
}
