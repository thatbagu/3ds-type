# 3DS Type

Type on a Nintendo 3DS using a physical keyboard connected to your Android phone. Text is sent over Wi-Fi via Luma3DS InputRedirect (UDP port 4950) using a chord encoding scheme that maps ASCII to the 3DS button bitmask.

## How it works

The Android app captures keyboard input and encodes each character as a chord of 3DS buttons, sending 20-byte HID packets to the 3DS over UDP. The 3DS side decodes the chords and builds a text buffer with a typewriter-style interface.

**Chord encoding v6** — mask `0x367` (bits 0–2, 5–6, 8–9, skipping bits 3/4/7 which conflict with D-pad/START):
```
encode: (ascii & 0x07) | ((ascii & 0x18) << 2) | ((ascii & 0x60) << 3)
decode: (chord & 0x07) | ((chord >> 2) & 0x18) | ((chord >> 3) & 0x60)
```

Exit typing mode: send X+Y simultaneously (bitmask `0xC00`), outside chord range.

## Modes (Android app)

Vim-style modal control via `ESC`:

- **OFF** → `ESC` → **MENU**: navigate 3DS draft list with j/k/arrows, Enter to open, `n` for new draft, `d` to delete
- **MENU** → `n` or Enter → **TYPING**: keyboard captured, all input forwarded as HID chords
- **TYPING** → `ESC` → saves draft and returns to MENU

## Setup

### 3DS

1. Install [Luma3DS](https://github.com/LumaTeam/Luma3DS) with InputRedirect enabled
2. Copy `typewriter.3dsx` to `sdmc:/3ds/typewriter/typewriter.3dsx`
3. Launch from the Homebrew Launcher

### Android

1. Install the APK (requires Android 8+, root for screen-wake suppression)
2. Enable the accessibility service in Settings → Accessibility
3. Open the app and configure the 3DS IP address
4. Grant storage permission for draft saving (Settings → Manage Storage Permission)
5. Connect a physical Bluetooth/USB keyboard

### Building

Requires Nix with flakes:

```sh
# Android APK
nix build .#task-T002

# 3DS binary
nix build .#task-T010
```

## Features

- Vim-style modal interface (OFF / MENU / TYPING)
- Draft management: create, open, delete drafts on both 3DS and phone
- Drafts saved on exit to SD card (`sdmc:/3ds/typewriter/`) and phone mirror
- JetBrains Mono Nerd Font on the 3DS display
- Root: disables keyboard wake-lock when phone is screen-off in TYPING mode
- PARTIAL_WAKE_LOCK keeps CPU alive for the 16ms HID tick loop
- Pencil icon
