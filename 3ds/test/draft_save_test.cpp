#include "draft_manager.h"
#include <iostream>
#include <fstream>
#include <cassert>
#include <regex>
#include <cstdlib>

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: draft_save_test --content|--path-format\n";
        return 1;
    }
    std::string arg = argv[1];

    if (arg == "--content") {
        // Save to a temp dir, read back, compare
        char tmp[] = "/tmp/draft_test_XXXXXX";
        char* dir = mkdtemp(tmp);
        if (!dir) { std::cerr << "FAIL: mkdtemp\n"; return 1; }
        std::string content = "Hello, 3DS Type!\nSecond line.";
        std::string path = DraftManager::save(content, std::string(dir));
        std::ifstream f(path);
        std::string readback((std::istreambuf_iterator<char>(f)),
                              std::istreambuf_iterator<char>());
        if (readback != content) {
            std::cerr << "FAIL: content mismatch\n";
            std::cerr << "Expected: " << content << "\n";
            std::cerr << "Got: " << readback << "\n";
            return 1;
        }
        std::cout << "PASS\n";
        return 0;
    }

    if (arg == "--path-format") {
        // Check filename matches YYYYMMDDTHHMMSS.txt
        std::string name = DraftManager::makeFilename();
        std::regex pattern(R"(\d{8}T\d{6}\.txt)");
        if (!std::regex_match(name, pattern)) {
            std::cerr << "FAIL: filename '" << name << "' does not match YYYYMMDDTHHMMSS.txt\n";
            return 1;
        }
        std::cout << "PASS\n";
        return 0;
    }

    std::cerr << "Unknown arg: " << arg << "\n";
    return 1;
}
