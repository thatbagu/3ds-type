#include <3ds.h>
#include <citro2d.h>
#include <cstdint>
#include <cstdio>
#include <sys/stat.h>
#include "text_buffer.h"
#include "typewriter_renderer.h"
#include "hid_poller.h"
#include "draft_list.h"
#include "draft_manager.h"
#include "launch_screen.h"

static const char* DRAFT_DIR = "sdmc:/3ds/typewriter";

int main(int argc, char* argv[]) {
    romfsInit();
    gfxInitDefault();
    C3D_Init(C3D_DEFAULT_CMDBUF_SIZE);
    C2D_Init(C2D_DEFAULT_MAX_OBJECTS);
    C2D_Prepare();

    TypewriterRenderer renderer;
    renderer.init();

    mkdir(DRAFT_DIR, 0755);

    enum AppState { MENU, DELETE_CONFIRM, TYPING };
    AppState appState = MENU;

    LaunchScreen::State menuState;
    menuState.drafts = DraftList::list(DRAFT_DIR);

    TextBuffer  buffer;
    std::string currentDraftPath;
    std::string currentDraftName;
    bool        draftDirty = false;

    int  scrollOffset = 0;
    u32  lastKDown    = 0;
    char lastDecoded  = 0;

    while (aptMainLoop()) {
        hidScanInput();
        u32 kDown = hidKeysDown();
        if (kDown) lastKDown = kDown;

        switch (appState) {

        case MENU: {
            LaunchScreen::Action action = LaunchScreen::update(menuState, kDown);
            if (action == LaunchScreen::OPEN_DRAFT && !menuState.drafts.empty()) {
                const DraftEntry& e = menuState.drafts[menuState.cursor];
                currentDraftName = e.name;
                currentDraftPath = std::string(DRAFT_DIR) + "/" + e.name;
                buffer = TextBuffer();
                buffer.loadRaw(DraftManager::load(currentDraftPath));
                scrollOffset = 0;
                draftDirty   = false;
                appState = TYPING;
            } else if (action == LaunchScreen::NEW_DRAFT) {
                currentDraftName = DraftManager::makeFilename();
                currentDraftPath = std::string(DRAFT_DIR) + "/" + currentDraftName;
                buffer = TextBuffer();
                scrollOffset = 0;
                draftDirty   = false;
                appState = TYPING;
            } else if (action == LaunchScreen::DELETE_DRAFT && !menuState.drafts.empty()) {
                appState = DELETE_CONFIRM;
            }
            renderer.renderMenu(menuState.drafts, menuState.cursor);
            break;
        }

        case DELETE_CONFIRM: {
            if ((kDown & KEY_A) && !menuState.drafts.empty()) {
                std::string path = std::string(DRAFT_DIR) + "/"
                                 + menuState.drafts[menuState.cursor].name;
                std::remove(path.c_str());
                menuState.drafts = DraftList::list(DRAFT_DIR);
                if (menuState.cursor >= (int)menuState.drafts.size())
                    menuState.cursor = (int)menuState.drafts.size() - 1;
                if (menuState.cursor < 0) menuState.cursor = 0;
                appState = MENU;
            } else if ((kDown & KEY_B) || (kDown & KEY_X)) {
                appState = MENU;
            }
            std::string name = menuState.drafts.empty()
                             ? "" : menuState.drafts[menuState.cursor].name;
            renderer.renderDeleteConfirm(name);
            break;
        }

        case TYPING: {
            // KEY_X+KEY_Y together (0xC00) = "exit typing" signal from Android.
            if ((kDown & 0xC00) == 0xC00) {
                if (draftDirty) {
                    DraftManager::saveTo(buffer.getContent(), currentDraftPath);
                    draftDirty = false;
                }
                menuState.drafts = DraftList::list(DRAFT_DIR);
                menuState.cursor = 0;
                appState = MENU;
                break;
            }
            if (kDown & KEY_Y) { if (scrollOffset > 0) scrollOffset--; }
            if (kDown & KEY_X) scrollOffset++;

            if (kDown != 0) {
                uint32_t chord = kDown & 0x367;
                if (chord != 0) {
                    int a = (chord & 0x07) | ((chord >> 2) & 0x18) | ((chord >> 3) & 0x60);
                    if (a >= 32 && a <= 126) lastDecoded = (char)a;
                    else if (a == 8) lastDecoded = 8;
                }
            }

            if (process_hid_frame(kDown, buffer)) draftDirty = true;

            auto lines = buffer.getLines();
            int maxScroll = (int)lines.size() > 0 ? (int)lines.size() - 1 : 0;
            if (scrollOffset > maxScroll) scrollOffset = maxScroll;

            renderer.render(lines, 0, false, lastKDown, 0,
                            scrollOffset, lastDecoded, currentDraftName);
            break;
        }
        }
    }

    if (appState == TYPING && draftDirty && !currentDraftPath.empty())
        DraftManager::saveTo(buffer.getContent(), currentDraftPath);

    C2D_Fini();
    C3D_Fini();
    gfxExit();
    romfsExit();
    return 0;
}
