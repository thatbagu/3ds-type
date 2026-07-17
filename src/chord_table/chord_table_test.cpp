// chord_table_test.cpp — no-collision self-test for the chord table.
#include <iostream>
#include <string>
#include <unordered_set>
#include "chord_table.h"

int main(int argc, char* argv[]) {
    bool no_collision = false;
    for (int i = 1; i < argc; ++i) {
        if (std::string(argv[i]) == "--no-collision") {
            no_collision = true;
        }
    }

    if (no_collision) {
        std::unordered_set<uint16_t> seen;
        for (size_t i = 0; i < CHORD_TABLE_SIZE; ++i) {
            uint16_t bm = CHORD_TABLE[i].bitmask;

            if (bm == 0x000) {
                std::cerr << "FAIL: entry " << i << " (ascii=" << (int)CHORD_TABLE[i].ascii
                          << ") has forbidden bitmask 0x000\n";
                return 1;
            }

            if (bm == 0x00C) {
                std::cerr << "FAIL: entry " << i << " (ascii=" << (int)CHORD_TABLE[i].ascii
                          << ") has forbidden bitmask 0x00C (START+SELECT)\n";
                return 1;
            }

            if (seen.count(bm)) {
                std::cerr << "FAIL: duplicate bitmask " << bm << " at entry " << i
                          << " (ascii=" << (int)CHORD_TABLE[i].ascii << ")\n";
                return 1;
            }
            seen.insert(bm);
        }
        std::cout << "PASS\n";
        return 0;
    }

    std::cerr << "No test flag specified. Use --no-collision.\n";
    return 1;
}
