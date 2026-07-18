#pragma once
#include <3ds.h>
#include <citro2d.h>
#include <cstdio>
#include <string>
#include <vector>

class TypewriterRenderer {
public:
    static const int TOP_WIDTH  = 400;
    static const int TOP_HEIGHT = 240;
    static const int BOT_WIDTH  = 320;
    static const int BOT_HEIGHT = 240;

    static constexpr float MARGIN = 10.0f;
    static constexpr float LINE_H = 22.0f;
    static constexpr float SCALE  = 0.65f;

    void init() {
        top_     = C2D_CreateScreenTarget(GFX_TOP, GFX_LEFT);
        bot_     = C2D_CreateScreenTarget(GFX_BOTTOM, GFX_LEFT);
        u8 region = CFG_REGION_USA;
        if (R_SUCCEEDED(cfguInit())) {
            CFGU_SecureInfoGetRegion(&region);
            cfguExit();
        }
        font_ = C2D_FontLoadSystem((CFG_Region)region);
        textBuf_ = C2D_TextBufNew(4096);
    }

    void render(const std::vector<std::string>& lines, int wordCount, bool connected,
                uint32_t lastKDown = 0, uint32_t frameCount = 0, int scrollOffset = 0,
                char lastDecoded = 0) {
        C2D_TextBufClear(textBuf_);

        C3D_FrameBegin(C3D_FRAME_SYNCDRAW);

        // top screen: text content starting from scrollOffset
        C2D_TargetClear(top_, C2D_Color32(0x10, 0x10, 0x10, 0xFF));
        C2D_SceneBegin(top_);

        float y = MARGIN;
        for (int i = scrollOffset; i < (int)lines.size(); i++) {
            if (y + LINE_H > TOP_HEIGHT - MARGIN) break;
            if (!lines[i].empty()) {
                C2D_Text t;
                C2D_TextFontParse(&t, font_, textBuf_, lines[i].c_str());
                C2D_TextOptimize(&t);
                C2D_DrawText(&t, C2D_AtBaseline | C2D_WithColor,
                             MARGIN, y + LINE_H, 0.5f, SCALE, SCALE,
                             C2D_Color32(0xE0, 0xE0, 0xD0, 0xFF));
            }
            y += LINE_H;
        }

        // bottom screen: debug overlay
        C2D_TargetClear(bot_, C2D_Color32(0x08, 0x08, 0x08, 0xFF));
        C2D_SceneBegin(bot_);

        char debug[128];
        char dec_str[8] = "---";
        if (lastDecoded >= 32 && lastDecoded <= 126)
            snprintf(dec_str, sizeof(dec_str), "'%c'", lastDecoded);
        else if (lastDecoded == 8)
            snprintf(dec_str, sizeof(dec_str), "BS");
        snprintf(debug, sizeof(debug), "v6 hid:0x%03lX dec:%s\nscroll:%d/%d",
                 (unsigned long)lastKDown, dec_str,
                 scrollOffset, (int)lines.size());
        C2D_Text debugText;
        C2D_TextFontParse(&debugText, font_, textBuf_, debug);
        C2D_TextOptimize(&debugText);
        C2D_DrawText(&debugText, C2D_AtBaseline | C2D_WithColor,
                     8.0f, BOT_HEIGHT - 40.0f, 0.5f, SCALE * 0.75f, SCALE * 0.75f,
                     C2D_Color32(0x70, 0x70, 0x60, 0xFF));

        C3D_FrameEnd(0);
    }

private:
    C3D_RenderTarget* top_     = nullptr;
    C3D_RenderTarget* bot_     = nullptr;
    C2D_Font          font_    = nullptr;
    C2D_TextBuf       textBuf_ = nullptr;
};
