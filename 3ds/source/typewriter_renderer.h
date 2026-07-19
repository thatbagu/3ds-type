#pragma once
#include <3ds.h>
#include <citro2d.h>
#include <cstdio>
#include <string>
#include <vector>
#include "draft_list.h"

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
        font_    = C2D_FontLoad("romfs:/font.bcfnt");
        if (!font_) {
            // Fall back to system font if romfs load fails.
            u8 region = CFG_REGION_USA;
            if (R_SUCCEEDED(cfguInit())) { CFGU_SecureInfoGetRegion(&region); cfguExit(); }
            font_ = C2D_FontLoadSystem((CFG_Region)region);
        }
        textBuf_ = C2D_TextBufNew(4096);
    }

    void renderMenu(const std::vector<DraftEntry>& drafts, int cursor) {
        C2D_TextBufClear(textBuf_);
        C3D_FrameBegin(C3D_FRAME_SYNCDRAW);

        C2D_TargetClear(top_, C2D_Color32(0x10, 0x10, 0x10, 0xFF));
        C2D_SceneBegin(top_);

        drawText("-- Drafts --", MARGIN, MARGIN + LINE_H,
                 SCALE, C2D_Color32(0x90, 0x90, 0xFF, 0xFF));

        if (drafts.empty()) {
            drawText("(no drafts)",
                     MARGIN, MARGIN + LINE_H * 3,
                     SCALE * 0.85f, C2D_Color32(0x60, 0x60, 0x60, 0xFF));
            drawText("Press SELECT (or 'n') to create one",
                     MARGIN, MARGIN + LINE_H * 4,
                     SCALE * 0.75f, C2D_Color32(0x50, 0x50, 0x50, 0xFF));
        } else {
            const int maxVisible = (int)((TOP_HEIGHT - MARGIN * 3 - LINE_H * 2) / LINE_H);
            int startIdx = cursor - maxVisible + 1;
            if (startIdx < 0) startIdx = 0;

            float y = MARGIN + LINE_H * 2;
            for (int i = startIdx; i < (int)drafts.size(); i++) {
                if (y + LINE_H > TOP_HEIGHT - MARGIN) break;
                bool sel = (i == cursor);
                uint32_t col = sel ? C2D_Color32(0xFF, 0xFF, 0x80, 0xFF)
                                   : C2D_Color32(0xC0, 0xC0, 0xC0, 0xFF);
                drawText(drafts[i].name.c_str(),
                         sel ? MARGIN : MARGIN + 10, y + LINE_H,
                         SCALE, col);
                y += LINE_H;
            }
            if (startIdx > 0)
                drawText("^ more ^", TOP_WIDTH - 70, MARGIN + LINE_H * 2,
                         SCALE * 0.7f, C2D_Color32(0x60, 0x60, 0x60, 0xFF));
        }

        C2D_TargetClear(bot_, C2D_Color32(0x08, 0x08, 0x08, 0xFF));
        C2D_SceneBegin(bot_);
        drawText("j/k arrows: navigate  Enter: open  n: new",
                 8.0f, BOT_HEIGHT - 48.0f, SCALE * 0.75f, C2D_Color32(0x70, 0x70, 0x60, 0xFF));
        drawText("d: delete",
                 8.0f, BOT_HEIGHT - 26.0f, SCALE * 0.75f, C2D_Color32(0x70, 0x70, 0x60, 0xFF));

        C3D_FrameEnd(0);
    }

    void renderDeleteConfirm(const std::string& draftName) {
        C2D_TextBufClear(textBuf_);
        C3D_FrameBegin(C3D_FRAME_SYNCDRAW);

        C2D_TargetClear(top_, C2D_Color32(0x18, 0x08, 0x08, 0xFF));
        C2D_SceneBegin(top_);
        drawText("Delete draft?", MARGIN, MARGIN + LINE_H,
                 SCALE, C2D_Color32(0xFF, 0x60, 0x60, 0xFF));
        drawText(draftName.c_str(), MARGIN, MARGIN + LINE_H * 2.5f,
                 SCALE, C2D_Color32(0xE0, 0xE0, 0xD0, 0xFF));

        C2D_TargetClear(bot_, C2D_Color32(0x08, 0x08, 0x08, 0xFF));
        C2D_SceneBegin(bot_);
        drawText("Enter: confirm delete",
                 8.0f, BOT_HEIGHT - 48.0f, SCALE * 0.85f, C2D_Color32(0xFF, 0x60, 0x60, 0xFF));
        drawText("Esc / any other key: cancel",
                 8.0f, BOT_HEIGHT - 26.0f, SCALE * 0.85f, C2D_Color32(0x70, 0x70, 0x60, 0xFF));

        C3D_FrameEnd(0);
    }

    void render(const std::vector<std::string>& lines, int /*wordCount*/, bool /*connected*/,
                uint32_t lastKDown = 0, uint32_t /*frameCount*/ = 0, int scrollOffset = 0,
                char lastDecoded = 0, const std::string& draftName = "") {
        C2D_TextBufClear(textBuf_);
        C3D_FrameBegin(C3D_FRAME_SYNCDRAW);

        C2D_TargetClear(top_, C2D_Color32(0x10, 0x10, 0x10, 0xFF));
        C2D_SceneBegin(top_);

        float y = MARGIN;
        for (int i = scrollOffset; i < (int)lines.size(); i++) {
            if (y + LINE_H > TOP_HEIGHT - MARGIN) break;
            if (!lines[i].empty())
                drawText(lines[i].c_str(), MARGIN, y + LINE_H,
                         SCALE, C2D_Color32(0xE0, 0xE0, 0xD0, 0xFF));
            y += LINE_H;
        }

        C2D_TargetClear(bot_, C2D_Color32(0x08, 0x08, 0x08, 0xFF));
        C2D_SceneBegin(bot_);

        char debug[160];
        char dec_str[8] = "---";
        if (lastDecoded >= 32 && lastDecoded <= 126)
            snprintf(dec_str, sizeof(dec_str), "'%c'", lastDecoded);
        else if (lastDecoded == 8)
            snprintf(dec_str, sizeof(dec_str), "BS");
        snprintf(debug, sizeof(debug), "hid:0x%03lX dec:%s scroll:%d/%d\n%s",
                 (unsigned long)lastKDown, dec_str,
                 scrollOffset, (int)lines.size(),
                 draftName.empty() ? "" : draftName.c_str());
        drawText(debug, 8.0f, BOT_HEIGHT - 40.0f,
                 SCALE * 0.75f, C2D_Color32(0x70, 0x70, 0x60, 0xFF));

        C3D_FrameEnd(0);
    }

private:
    C3D_RenderTarget* top_     = nullptr;
    C3D_RenderTarget* bot_     = nullptr;
    C2D_Font          font_    = nullptr;
    C2D_TextBuf       textBuf_ = nullptr;

    void drawText(const char* str, float x, float y, float scale, uint32_t color) {
        C2D_Text t;
        C2D_TextFontParse(&t, font_, textBuf_, str);
        C2D_TextOptimize(&t);
        C2D_DrawText(&t, C2D_AtBaseline | C2D_WithColor, x, y, 0.5f, scale, scale, color);
    }
};
