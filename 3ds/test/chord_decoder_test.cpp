// chord_decoder_test.cpp — round-trip identity test for ChordDecoder.
// For every entry in CHORD_TABLE: chord_to_char(char_to_chord(ascii)) == ascii
// Also checks chord_to_char(0) == -1 (invalid bitmask).
#include <iostream>
#include "chord_decoder.h"

int main() {
    // Test: invalid bitmask 0 should return -1
    if (chord_to_char(0) != -1) {
        std::cerr << "FAIL: chord_to_char(0) expected -1, got " << chord_to_char(0) << "\n";
        return 1;
    }

    // Round-trip test: for every entry, chord_to_char(char_to_chord(ascii)) == ascii
    for (size_t i = 0; i < CHORD_TABLE_SIZE; i++) {
        uint8_t ascii = CHORD_TABLE[i].ascii;
        uint16_t bitmask = char_to_chord(ascii);
        int decoded = chord_to_char(bitmask);
        if (decoded != static_cast<int>(ascii)) {
            std::cerr << "FAIL: round-trip for ascii=" << static_cast<int>(ascii)
                      << " bitmask=" << bitmask
                      << " decoded=" << decoded << "\n";
            return 1;
        }
    }

    std::cout << "PASS\n";
    return 0;
}
