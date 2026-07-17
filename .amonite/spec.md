# Specification: 3DS Type

<!-- What and why. No tech stack, no file paths — that belongs in plan.md. -->

## Intent

Users with a modded 3DS lack a practical way to type text on the device away from a computer. The 3DS on-screen keyboard is slow and the existing input-redirect ecosystem only handles gamepad buttons, not characters. 3DS Type turns the 3DS into a distraction-free digital typewriter: a physical keyboard connected to an Android phone maps each key to a unique combination of 3DS HID buttons and forwards them over the Luma3DS InputRedirect UDP protocol. The 3DS typewriter app decodes those button chords back into characters and displays them in a minimal full-screen drafting interface. No menus, no chrome — just text on screen. Drafts are saved to both the 3DS SD card and (optionally) a configurable path on the Android device.

Design reference: BYOK digital typewriter — single-purpose drafting, text fills the screen, everything else stays out of the way.

Transport: Luma3DS InputRedirect, UDP port 4950, 20-byte HID packet. Characters are encoded as button chords; no custom TCP channel.

## User stories

<!-- Priority-ordered. Each story must be independently deliverable and
     independently verifiable — it will become a cluster. -->

### US1 (P1): Android keyboard capture and HID forwarding

As a user with a USB or Bluetooth keyboard connected to my Android phone, I want a background service that captures each keystroke, encodes it as a unique 3DS HID button chord, and sends it to my 3DS over the Luma3DS InputRedirect UDP protocol, so that typing on the keyboard produces text on the 3DS in real time.

**Done when**:
- [ ] `./gradlew assembleDebug` exits 0 and produces a valid APK
- [ ] A JVM unit test: the chord encoder maps every printable ASCII key plus Backspace, Enter, and Delete to a unique 12-bit button bitmask with no collisions; test asserts uniqueness over the full table and exits 0
- [ ] A JVM unit test: given a `KeyEvent` for key 'H', the service encodes it to the correct bitmask and serializes it into a valid 20-byte Luma3DS HID UDP payload; test exits 0

### US2 (P2): 3DS digital typewriter display

As a user on the 3DS, I want a custom homebrew app that receives HID button chords via Luma3DS InputRedirect, decodes them back into characters, and displays them in a distraction-free full-screen drafting interface, so the 3DS feels like a dedicated writing device.

**Reference**: Notepad3DS (github.com/MaeveMcT/Notepad3DS) as a structural reference for devkitPro/libctru project layout, HID polling pattern (`hidScanInput` / `hidKeysDown`), and SD card I/O via `std::ofstream`. The typewriter app uses citro2d for rendering (not consoleInit), giving full control over typography and the dark-background aesthetic.

**UI contract** (informs verification, not implementation):
- Top screen (400×240): text only — off-white characters on a near-black background, soft word-wrap, blinking block cursor. No title bar, no status bar, no decorations.
- Bottom screen (320×240): a single dim status line — word count, connection state (`● connected` / `○ waiting`), and the save hint (`[START] save`). Nothing else during drafting.

**Done when**:
- [ ] Cross-compilation exits 0 and produces `typewriter.3dsx` whose first 4 bytes are the magic `3DSX` (verified by header check)
- [ ] A host-side unit-test binary of the chord decoder: given every bitmask in the encoding table, `chord_to_char()` returns the exact character the encoder assigned; binary exits 0 (this test shares the encoding table with US1, enforcing round-trip correctness)
- [ ] A host-side unit-test binary of the text-buffer module: given a sequence of decoded chars (letters, backspace, newline, word-wrap boundary), `buffer_get_lines()` returns the expected wrapped line array; binary exits 0

### US3 (P3): Save draft — 3DS SD card

As a user who finished typing, I want to press Start on the 3DS to save my current draft to the SD card, so the text is preserved after closing the app.

**Done when**:
- [ ] A host-side test of the save function: given a populated text buffer and a writable temp path, the save routine writes the exact buffer contents to that path; `diff` against expected string exits 0
- [ ] Pressing Start in the running app writes `/3ds/typewriter/<ISO-timestamp>.txt` on the SD card (path-construction logic covered by the host test above; hardware execution noted as a `gate.live` boundary in the plan)

### US4 (P4): Draft list on 3DS

As a user returning to the app, I want to see a scrollable list of my saved drafts on launch so I can select and continue an existing draft or start a new one.

**Done when**:
- [ ] A host-side unit test: given a directory with N stub `.txt` files, the draft-list loader returns them sorted by modification time descending; test exits 0
- [ ] Running `typewriter.3dsx` on a 3DS with at least one saved draft shows a navigable list (Up/Down to move, A to open, B/Start to create new); cross-compilation exits 0 as the primary hermetic gate; list-navigation logic covered by the host test above

### US5 (P5): Android draft storage

As a user who wants a backup of typed text, I want the Android app to save each completed draft to a configurable local path on the phone, so I have a copy independent of the 3DS SD card.

**Done when**:
- [ ] A JVM unit test: saving a draft string to a mock file path via the draft-storage module and reading it back returns identical bytes; test exits 0
- [ ] A JVM unit test: the configured storage path is persisted across app restarts via the settings module; test exits 0
- [ ] The Android app settings screen includes a "Draft save path" field that is pre-filled with a sensible default and persists user changes

### US6 (P6): IP address configuration on Android

As a user setting up for the first time, I want to enter my 3DS's local IP address once in the Android app and have it remembered, so I don't need to reconfigure on every use.

**Done when**:
- [ ] A JVM unit test: saving and reloading an IP/port pair via the settings module returns identical values; test exits 0
- [ ] The foreground service notification shows one of three states — `Connecting`, `Connected`, or `Disconnected` — matching the actual socket state; verified by an instrumented test that toggles the socket and asserts the notification text

## Out of scope

- Building on or forking Notepad3DS — the 3DS app is written from scratch; Notepad3DS is a reference only
- Gamepad / button emulation for games or 3DS menu navigation — text typing only
- Custom TCP text channel — the wire protocol is exclusively Luma3DS InputRedirect UDP
- iOS or any non-Android phone client
- Bluetooth pairing or keyboard setup UI (keyboard must already be paired/connected to Android)
- Rich text, Markdown, or any formatting on the 3DS display
- Cloud sync or any upload of drafts to external services
- WiFi encryption or authentication (LAN-only, same-network trust)
- Auto-discovery of the 3DS IP (manual entry only in v1)

## Open questions

_(none — all resolved during specify)_
