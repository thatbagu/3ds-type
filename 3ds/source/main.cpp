#include <3ds.h>
#include <citro2d.h>
#include <cstdint>
#include "text_buffer.h"
#include "typewriter_renderer.h"
#include "hid_poller.h"

int main(int argc, char* argv[]) {
    gfxInitDefault();
    C3D_Init(C3D_DEFAULT_CMDBUF_SIZE);
    C2D_Init(C2D_DEFAULT_MAX_OBJECTS);
    C2D_Prepare();

    TypewriterRenderer renderer;
    renderer.init();
    TextBuffer buffer;

    u32 lastKDown = 0;
    u32 frameCount = 0;
    int scrollOffset = 0;
    char lastDecoded = 0;

    while (aptMainLoop()) {
        hidScanInput();
        u32 kDown = hidKeysDown();
        if (kDown) lastKDown = kDown;
        frameCount++;
        // KEY_Y (bit 11) = scroll up, KEY_X (bit 10) = scroll down.
        if (kDown & KEY_Y) { if (scrollOffset > 0) scrollOffset--; }
        if (kDown & KEY_X) scrollOffset++;

        // Track what character was decoded for the debug display.
        if (kDown != 0) {
            uint32_t chord = kDown & 0x367;  // encoding bits 0-2, 5-6, 8-9
            if (chord != 0) {
                int a = (chord & 0x07) | ((chord >> 2) & 0x18) | ((chord >> 3) & 0x60);
                if (a >= 32 && a <= 126) lastDecoded = (char)a;
                else if (a == 8) lastDecoded = 8;
            }
        }

        process_hid_frame(kDown, buffer);

        auto lines = buffer.getLines();
        int maxScroll = (int)lines.size() > 0 ? (int)lines.size() - 1 : 0;
        if (scrollOffset > maxScroll) scrollOffset = maxScroll;

        renderer.render(lines, 0, false, lastKDown, frameCount, scrollOffset, lastDecoded);
    }

    C2D_Fini();
    C3D_Fini();
    gfxExit();
    return 0;
}
