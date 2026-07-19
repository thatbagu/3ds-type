#pragma once
#include <vector>
#include <string>
#include "draft_list.h"

class LaunchScreen {
public:
    enum Action { NONE, OPEN_DRAFT, NEW_DRAFT, DELETE_DRAFT };

    struct State {
        std::vector<DraftEntry> drafts;
        int         cursor           = 0;
        bool        receivingName    = false;
        std::string pendingName;     // filename stem sent by Android before SELECT
    };

    // START (0x008, bit 3) is outside chord encoding range → safe as a signal.
    // When Android creates a new draft it sends: START, then timestamp chars as
    // chords, then SELECT. The 3DS accumulates the chars and uses them as the
    // filename stem so both sides end up with the exact same name.
    static Action update(State& s, uint32_t kDown) {
        if (s.receivingName) {
            if (kDown & 0x080) {        // DDOWN — end-of-filename marker (0x080 is outside chord mask 0x367)
                s.receivingName = false;
                return NEW_DRAFT;
            }
            uint32_t chord = kDown & 0x367;
            if (chord) {
                int a = (chord & 0x07) | ((chord >> 2) & 0x18) | ((chord >> 3) & 0x60);
                if (a >= 32 && a <= 126) s.pendingName += (char)a;
            }
            return NONE;
        }
        if (kDown & 0x008) {            // START — begin receiving filename
            s.receivingName = true;
            s.pendingName.clear();
            return NONE;
        }
        if (kDown & 0x004) return NEW_DRAFT;   // plain SELECT (no filename from Android)
        if ((kDown & 0x1) && !s.drafts.empty()) return OPEN_DRAFT;
        if ((kDown & 0x2) && !s.drafts.empty()) return DELETE_DRAFT;
        if ((kDown & 0x800) && s.cursor + 1 < (int)s.drafts.size()) s.cursor++;
        if ((kDown & 0x400) && s.cursor > 0) s.cursor--;
        return NONE;
    }
};
