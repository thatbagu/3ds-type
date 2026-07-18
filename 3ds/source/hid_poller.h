#pragma once
#include <cstdint>
#include "text_buffer.h"

// Decodes one HID frame's bitmask to ASCII using the same bijection as
// ChordEncoder.encode() on the Android side:
//   HID bits 0-2 -> ASCII bits 0-2
//   HID bits 5-6 -> ASCII bits 3-4   (skip HID bits 3,4 = START/DRIGHT)
//   HID bits 8-9 -> ASCII bits 5-6   (skip HID bits 3,4,7 = START/DRIGHT/DDOWN)
inline bool process_hid_frame(uint32_t kDown, TextBuffer& buf) {
    if (kDown == 0) return false;
    uint32_t chord = kDown & 0x367;  // encoding uses bits 0-2, 5-6, 8-9
    if (chord == 0) return false;
    int ascii = (chord & 0x07)
              | ((chord >> 2) & 0x18)
              | ((chord >> 3) & 0x60);
    if (ascii == 8)  { buf.backspace(); return true; }
    if (ascii == 10) { buf.append('\n'); return true; }
    if (ascii < 32 || ascii > 126) return false;
    buf.append((char)ascii);
    return true;
}
