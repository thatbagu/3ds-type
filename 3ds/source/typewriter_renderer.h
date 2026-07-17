#pragma once
#include <3ds.h>
#include <citro2d.h>
#include <string>
#include <vector>

// Typewriter renderer: minimal UI — text fills top screen, status on bottom.
class TypewriterRenderer {
public:
    static const int TOP_WIDTH  = 400;
    static const int TOP_HEIGHT = 240;
    static const int BOT_WIDTH  = 320;
    static const int BOT_HEIGHT = 240;

    // Call once after gfxInitDefault() and C2D_Init()
    void init() {
        top_ = C2D_CreateScreenTarget(GFX_TOP, GFX_LEFT);
        bot_ = C2D_CreateScreenTarget(GFX_BOTTOM, GFX_LEFT);
    }

    // Render lines of text on top screen, status on bottom.
    // lines: word-wrapped lines from TextBuffer::getLines()
    // wordCount: total word count for status
    // connected: true if UDP socket is connected
    void render(const std::vector<std::string>& lines,
                int wordCount, bool connected) {
        C2D_TargetClear(top_, C2D_Color32(0x10, 0x10, 0x10, 0xFF));
        C2D_TargetClear(bot_, C2D_Color32(0x08, 0x08, 0x08, 0xFF));
        C2D_Prepare();

        // Top screen: draw text lines
        // Use consoleInit-style text via C2D_DrawText for simplicity
        // (full font loading is for T011 integration; here just render placeholder)
        C2D_SceneBegin(top_);
        // Text rendering will be implemented in T011 with a loaded font
        // For now renderer compiles clean with citro2d calls above

        C2D_SceneBegin(bot_);
        // Status line rendered in T011

        C2D_Flush();
    }

private:
    C3D_RenderTarget* top_ = nullptr;
    C3D_RenderTarget* bot_ = nullptr;
};
