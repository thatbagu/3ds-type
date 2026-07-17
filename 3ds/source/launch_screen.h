#pragma once
#include <vector>
#include <string>
#include "draft_list.h"

class LaunchScreen {
public:
    enum Action { NONE, OPEN_DRAFT, NEW_DRAFT };

    struct State {
        std::vector<DraftEntry> drafts;
        int cursor = 0;
    };

    // Returns which action the user took this frame.
    // On real 3DS, kDown comes from hidKeysDown(); in host tests, caller provides it.
    // Button constants (3DS HID):
    //   KEY_A=1, KEY_B=2, KEY_SELECT=4, KEY_START=8
    //   KEY_DOWN=0x800, KEY_UP=0x400
    static Action update(State& s, uint32_t kDown) {
        if (kDown & 0x8) return NEW_DRAFT;                               // KEY_START
        if ((kDown & 0x1) && !s.drafts.empty()) return OPEN_DRAFT;      // KEY_A
        if ((kDown & 0x800) && s.cursor + 1 < (int)s.drafts.size())     // KEY_DOWN
            s.cursor++;
        if ((kDown & 0x400) && s.cursor > 0)                             // KEY_UP
            s.cursor--;
        return NONE;
    }
};
