#include "chord_table.h"
#include "chord_decoder.h"
#include "text_buffer.h"
#include "hid_poller.h"
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>

int main() {
    // Feed 'Hello' via chord encoding and check the buffer content.
    const char* expect = "Hello";
    TextBuffer buf;
    for (int i = 0; expect[i]; ++i) {
        uint16_t chord = char_to_chord((uint8_t)expect[i]);
        if (chord == 0) {
            std::cerr << "FAIL: char_to_chord('" << expect[i] << "') == 0\n";
            return 1;
        }
        process_hid_frame((uint32_t)chord, buf);
    }
    std::string content = buf.getContent();
    if (content != std::string(expect)) {
        std::cerr << "FAIL: expected '" << expect << "', got '" << content << "'\n";
        return 1;
    }

    // Backspace: 'Hello' → 'Hell'
    process_hid_frame((uint32_t)char_to_chord(8), buf);
    content = buf.getContent();
    if (content != "Hell") {
        std::cerr << "FAIL: after backspace expected 'Hell', got '" << content << "'\n";
        return 1;
    }

    std::cout << "PASS\n";
    return 0;
}
