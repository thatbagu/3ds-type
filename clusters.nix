# Cluster layer: composition of verified tasks into higher abstractions.
# Topology matches .amonite/plan.md § Cluster topology.
{ pkgs, tasks, amonite }:

let
  C001 = amonite.mkCluster {
    id = "C001";
    title = "Chord Table Foundation";
    tasks = with tasks; [ T001 ];
    env = [ pkgs.gcc pkgs.coreutils ];
    verify = {
      artifacts-present = ''
        test -f "$out/tasks/T001/chord_table.h"
        test -f "$out/tasks/T001/ChordTable.kt"
      '';
      no-collision = ''
        "$out/tasks/T001/bin/chord_table_test" --no-collision
      '';
    };
  };

  C002 = amonite.mkCluster {
    id = "C002";
    title = "Android Keyboard Service";
    tasks = with tasks; [ T002 T003 ];
    env = [ pkgs.coreutils ];
    verify = {
      apk-present = ''
        test -f "$out/tasks/T003/app-debug.apk"
      '';
      encoder-roundtrip = ''
        "$out/tasks/T003/bin/run-tests" ChordEncoderTest.roundTrip
      '';
    };
  };

  C003 = amonite.mkCluster {
    id = "C003";
    title = "Android Settings and Draft Storage";
    tasks = with tasks; [ T004 T005 T006 ];
    env = [ pkgs.coreutils ];
    verify = {
      apk-present = ''
        test -f "$out/tasks/T006/app-debug.apk"
      '';
      settings-roundtrip = ''
        "$out/tasks/T004/bin/run-tests" SettingsRepositoryTest.roundTrip
      '';
      draft-storage = ''
        "$out/tasks/T005/bin/run-tests" DraftStorageTest.writeAndReadBack
      '';
    };
  };

  C004 = amonite.mkCluster {
    id = "C004";
    title = "3DS Typewriter Core";
    tasks = with tasks; [ T007 T008 T009 T010 T011 ];
    env = [ pkgs.xxd pkgs.coreutils ];
    verify = {
      dsx-present = ''
        test -f "$out/tasks/T011/typewriter.3dsx"
      '';
      magic-3dsx = ''
        ${pkgs.xxd}/bin/xxd -l 4 "$out/tasks/T011/typewriter.3dsx" | grep -q "3344 5358"
      '';
      decoder-roundtrip = ''
        "$out/tasks/T008/bin/chord_decoder_test"
      '';
      buffer-word-wrap = ''
        "$out/tasks/T009/bin/text_buffer_test" word-wrap
      '';
      buffer-backspace = ''
        "$out/tasks/T009/bin/text_buffer_test" backspace
      '';
      buffer-newline = ''
        "$out/tasks/T009/bin/text_buffer_test" newline
      '';
    };
  };

  C005 = amonite.mkCluster {
    id = "C005";
    title = "3DS SD I/O and Draft List";
    tasks = with tasks; [ T012 T013 ];
    env = [ pkgs.xxd pkgs.coreutils ];
    verify = {
      dsx-present = ''
        test -f "$out/tasks/T013/typewriter.3dsx"
      '';
      magic-3dsx = ''
        ${pkgs.xxd}/bin/xxd -l 4 "$out/tasks/T013/typewriter.3dsx" | grep -q "3344 5358"
      '';
      save-content = ''
        "$out/tasks/T012/bin/draft_save_test" --content
      '';
      list-sort = ''
        "$out/tasks/T013/bin/draft_list_test"
      '';
    };
  };

in
{
  inherit C001 C002 C003 C004 C005;

  APP = amonite.mkApplication {
    id = "APP";
    title = "3DS Type — keyboard-to-3DS digital typewriter";
    tasks = [ C001 C002 C003 C004 C005 ];
    env = [ pkgs.xxd pkgs.coreutils ];
    build = ''
      mkdir -p "$out/android" "$out/3ds"
      cp "$out/tasks/C003/tasks/T006/app-debug.apk" "$out/android/3ds-type.apk"
      cp "$out/tasks/C005/tasks/T013/typewriter.3dsx" "$out/3ds/typewriter.3dsx"
    '';
    verify = {
      apk-present = ''
        test -f "$out/android/3ds-type.apk"
      '';
      dsx-present = ''
        test -f "$out/3ds/typewriter.3dsx"
      '';
      magic-3dsx = ''
        ${pkgs.xxd}/bin/xxd -l 4 "$out/3ds/typewriter.3dsx" | grep -q "3344 5358"
      '';
    };
  };
}
