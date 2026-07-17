# T006: Android SettingsActivity UI
# Settings screen: 3DS IP address, UDP port, and draft-save path fields.
# All fields backed by SettingsRepository (T004) and wired to
# DraftStorage (T005). APK must include the activity in the manifest.
# Depends: T004, T005
{ pkgs, amonite }:

amonite.mkTask {
  id = "T006";
  title = "Android SettingsActivity UI — IP, port, draft-path fields wired to SettingsRepository";

  src = ../..;

  env = with pkgs; [
    jdk17
    gradle
    coreutils
  ];

  build = ''echo "T006 not yet implemented" >&2 && exit 1'';

  verify = {
    apk-builds = ''
      test -f "$out/app-debug.apk"
    '';
    path-persists = ''
      "$out/bin/run-tests" SettingsActivityTest.pathPersists
    '';
  };
}
