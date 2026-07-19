#pragma once
#include <vector>
#include <string>
#include "draft_list.h"

class LaunchScreen {
public:
    enum Action { NONE, OPEN_DRAFT, NEW_DRAFT, DELETE_DRAFT };

    struct State {
        std::vector<DraftEntry> drafts;
        int cursor = 0;
    };

    // Navigation uses KEY_X/KEY_Y (bits 10-11) — outside chord encoding range 0x367.
    // One-shot actions (KEY_A/B/SELECT) are safe because Android delays 150ms before
    // entering TYPING mode, so chord packets never arrive while 3DS is in MENU state.
    static Action update(State& s, uint32_t kDown) {
        if (kDown & 0x4) return NEW_DRAFT;
        if ((kDown & 0x1) && !s.drafts.empty()) return OPEN_DRAFT;
        if ((kDown & 0x2) && !s.drafts.empty()) return DELETE_DRAFT;
        if ((kDown & 0x800) && s.cursor + 1 < (int)s.drafts.size()) s.cursor++;
        if ((kDown & 0x400) && s.cursor > 0) s.cursor--;
        return NONE;
    }
};
