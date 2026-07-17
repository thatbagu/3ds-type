#pragma once
#include <cstdint>
#include "chord_decoder.h"
#include "text_buffer.h"

// Decodes one HID frame's chord bitmask and updates the TextBuffer.
// Returns true if any character was appended or removed.
inline bool process_hid_frame(uint32_t kDown, TextBuffer& buf) {
    if (kDown == 0) return false;
    uint16_t chord = (uint16_t)(kDown & 0x0FFF);
    int ascii = chord_to_char(chord);
    if (ascii <= 0) return false;
    if (ascii == 8) { buf.backspace(); return true; }  // Backspace
    buf.append((char)ascii);
    return true;
}
