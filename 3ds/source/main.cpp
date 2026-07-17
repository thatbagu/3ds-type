#include <3ds.h>
#include <citro2d.h>
#include <cstdint>
#include "chord_decoder.h"
#include "text_buffer.h"
#include "typewriter_renderer.h"
#include "hid_poller.h"

int main(int argc, char* argv[]) {
    gfxInitDefault();
    C2D_Init(C2D_DEFAULT_MAX_OBJECTS);
    C2D_Prepare();

    TypewriterRenderer renderer;
    renderer.init();
    TextBuffer buffer;

    while (aptMainLoop()) {
        hidScanInput();
        u32 kDown = hidKeysDown();
        if (kDown & KEY_START) break;
        process_hid_frame(kDown, buffer);
        renderer.render(buffer.getLines(), 0, false);
        gfxSwapBuffers();
        gspWaitForVBlank();
    }

    C2D_Fini();
    gfxExit();
    return 0;
}
