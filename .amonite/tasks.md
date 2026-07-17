# Tasks: 3DS Type

**Plan**: `.amonite/plan.md`

<!-- Each task row corresponds 1:1 to tasks/TXXX/task.nix. A task is DONE
     when its derivation builds: `amonite verify TXXX`. Checkboxes here are
     a human-readable mirror; the store is the truth. -->

Format: `[ID] [P?] [Cluster] Title — env grants`

- `[P]` = parallelizable (no dependency on unfinished tasks)
- `[Cluster]` = which cluster this task rolls up into

## C001: Chord Table Foundation

- [ ] T001 [P] [C001] Chord table generator — chord_table.h + ChordTable.kt + no-collision test — env: pkgs.python3, pkgs.gcc
      verify:
        no-collision: run generator; test binary asserts all 97 bitmasks unique, none 0x000, none 0x00C (START+SELECT)
        cpp-header: test -f "$out/chord_table.h" && gcc -x c++ -std=c++17 "$out/chord_table.h" -fsyntax-only
        kotlin-object: test -f "$out/ChordTable.kt" && grep -q "object ChordTable" "$out/ChordTable.kt"

## C002: Android Keyboard Service  (US1)

- [ ] T002 [P] [C002] Android project scaffold — Gradle, AndroidManifest, AccessibilityService stub — env: pkgs.jdk17, pkgs.gradle
      verify:
        apk-builds: ./gradlew assembleDebug exits 0 and app/build/outputs/apk/debug/app-debug.apk exists
- [ ] T003 [C002] AccessibilityService + ChordEncoder + HidUdpDispatcher — env: pkgs.jdk17, pkgs.gradle (depends: T001, T002)
      verify:
        encoder-no-collision: ./gradlew test --tests "*.ChordEncoderTest.noCollision" exits 0
        encoder-roundtrip: ./gradlew test --tests "*.ChordEncoderTest.roundTrip" exits 0
        udp-payload: ./gradlew test --tests "*.HidUdpDispatcherTest.payloadFormat" exits 0

## C003: Android Settings & Storage  (US5, US6)

- [ ] T004 [C003] Android SettingsRepository + foreground service + notification states — env: pkgs.jdk17, pkgs.gradle (depends: T002)
      verify:
        settings-roundtrip: ./gradlew test --tests "*.SettingsRepositoryTest.roundTrip" exits 0
        notification-states: ./gradlew test --tests "*.KeyboardServiceTest.notificationStates" exits 0
- [ ] T005 [C003] Android DraftStorage module — write/read draft at configurable path — env: pkgs.jdk17, pkgs.gradle (depends: T002)
      verify:
        draft-roundtrip: ./gradlew test --tests "*.DraftStorageTest.writeAndReadBack" exits 0
        path-configurable: ./gradlew test --tests "*.DraftStorageTest.pathConfigurable" exits 0
- [ ] T006 [C003] Android SettingsActivity UI — IP, port, draft-path fields wired to SettingsRepository — env: pkgs.jdk17, pkgs.gradle (depends: T004, T005)
      verify:
        apk-builds: ./gradlew assembleDebug exits 0 (settings activity present in APK manifest)
        path-persists: ./gradlew test --tests "*.SettingsActivityTest.pathPersists" exits 0

## C004: 3DS Typewriter Core  (US2)

- [ ] T007 [P] [C004] 3DS project scaffold — Makefile, devkitPro, citro2d boilerplate, cross-compile to typewriter.3dsx — env: devkitpro (via overlay)
      verify:
        cross-compile: make exits 0
        3dsx-magic: xxd -l 4 typewriter.3dsx | grep -q "3445 5358" (3DSX magic bytes)
- [ ] T008 [C004] 3DS ChordDecoder host-side unit test — round-trip identity with T001 table — env: pkgs.gcc (depends: T001, T007)
      verify:
        roundtrip: compile and run test/chord_decoder_test.cpp; binary exits 0 asserting chord_to_char(chord_from_char(c))==c for all 97 entries
- [ ] T009 [P] [C004] 3DS TextBuffer host-side unit test — word-wrap, backspace, newline — env: pkgs.gcc (depends: T007)
      verify:
        word-wrap: compile and run test/text_buffer_test.cpp; test case "wordWrap" exits 0
        backspace: test case "backspace" exits 0
        newline: test case "newline" exits 0
- [ ] T010 [C004] 3DS TypewriterRenderer — citro2d top screen (text+cursor) + bottom screen (status line) — env: devkitpro (depends: T007, T009)
      verify:
        cross-compile: make exits 0 (renderer.cpp compiled into typewriter.3dsx)
        3dsx-magic: xxd -l 4 typewriter.3dsx | grep -q "3445 5358"
- [ ] T011 [C004] 3DS HidPoller + main loop — hidKeysDown → ChordDecoder → TextBuffer → TypewriterRenderer — env: devkitpro, pkgs.gcc (depends: T001, T008, T009, T010)
      verify:
        cross-compile: make exits 0
        3dsx-magic: xxd -l 4 typewriter.3dsx | grep -q "3445 5358"
        host-integration: compile and run test/hid_loop_test.cpp stub; feeds 5 bitmasks, asserts buffer contains expected 5 chars; exits 0

## C005: 3DS SD I/O  (US3, US4)

- [ ] T012 [C005] 3DS DraftManager save — SD path construction, ISO timestamp, write via ofstream — env: pkgs.gcc (depends: T007, T009)
      verify:
        save-content: compile and run test/draft_save_test.cpp; writes to $TMPDIR/test.txt, diff against expected string exits 0
        path-format: test binary asserts timestamp filename matches regex [0-9]{8}T[0-9]{6}\.txt
- [ ] T013 [C005] 3DS DraftManager list + launch-screen — sorted by mtime desc, D-pad nav, A/Start — env: devkitpro, pkgs.gcc (depends: T007, T012)
      verify:
        list-sort: compile and run test/draft_list_test.cpp; 3 stub files with different mtimes → loader returns them newest-first; exits 0
        cross-compile: make exits 0
        3dsx-magic: xxd -l 4 typewriter.3dsx | grep -q "3445 5358"

## Cluster verifications

- C001: chord_table.h and ChordTable.kt both present in cluster output; no-collision test binary exits 0
- C002: APK built by T002/T003 present in cluster output; encoder round-trip test exits 0
- C003: APK from T006 present; settings + draft storage unit tests all exit 0
- C004: typewriter.3dsx present and 3DSX magic valid; host-side round-trip + buffer tests exit 0
- C005: draft save host test exits 0; list sort test exits 0; typewriter.3dsx with draft UI cross-compiles
- APP: typewriter.3dsx + app-debug.apk both present in output

## gate.live (impure, manual)

- [ ] Copy typewriter.3dsx to 3DS SD → launch via Homebrew Launcher → confirm boot
- [ ] Enable Luma3DS InputRedirection (Rosalina menu)
- [ ] Install APK → grant Accessibility permission → enter 3DS IP → confirm `Connected` in notification
- [ ] Type short sentence → confirm chars appear on 3DS top screen with no perceptible lag
- [ ] Press Start on 3DS → confirm .txt file saved to SD with correct content
- [ ] Re-launch typewriter.3dsx → confirm draft in list → open → confirm content
- [ ] Confirm Android draft file saved to configured path with correct content
