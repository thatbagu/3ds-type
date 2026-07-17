#include <3ds.h>
#include <citro2d.h>
#include <cstdio>
#include "text_buffer.h"
#include "typewriter_renderer.h"

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
        // Rendering in T011
        C2D_Flush();
        gfxSwapBuffers();
        gspWaitForVBlank();
    }

    C2D_Fini();
    gfxExit();
    return 0;
}
