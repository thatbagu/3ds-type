# T006: Android SettingsActivity UI
# Adds SettingsActivity (IP/port/draft-path) to the APK and verifies that
# SettingsRepository correctly persists the draft path in the host JVM.
# APK built manually (no Gradle): aapt2 + javac + d8 + jarsigner.
# SettingsActivity compiles against android.jar; SettingsRepository test
# runs on the host JVM (uses java.util.prefs which is not in android.jar).
# Depends: T004 (SettingsRepository), T005 (DraftStorage)
{ pkgs, amonite }:

let
  pkgsAndroid = import pkgs.path {
    inherit (pkgs) system;
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };

  androidSdk = (pkgsAndroid.androidenv.composeAndroidPackages {
    buildToolsVersions = [ "34.0.0" ];
    platformVersions   = [ "34" ];
    includeNDK         = false;
  }).androidsdk;

  sdkRoot = "${androidSdk}/libexec/android-sdk";

in amonite.mkTask {
  id    = "T006";
  title = "Android SettingsActivity UI — IP, port, draft-path fields wired to SettingsRepository";

  src = ../..;

  env = with pkgs; [
    androidSdk
    jdk17
    zip
    unzip
    coreutils
    bash
  ];

  build = ''
    set -euo pipefail

    SDK="${sdkRoot}"
    BUILD_TOOLS="$SDK/build-tools/34.0.0"
    PLATFORM="$SDK/platforms/android-34"

    WORK="$TMPDIR/apk-build"
    mkdir -p "$WORK"/{android-classes,test-classes,dex,keystore}
    mkdir -p "$out/bin"

    # ── 1. Compile Android-side sources against android.jar ──────────────────
    # SettingsRepository uses java.util.prefs (not in android.jar), so it is
    # excluded here and compiled separately for the test runner below.
    javac -source 8 -target 8 -Xlint:-options \
      -cp "$PLATFORM/android.jar" \
      -d "$WORK/android-classes" \
      "$src/android/src/dev/threedstype/app/ConnectionState.java" \
      "$src/android/src/dev/threedstype/app/KeyboardCaptureService.java" \
      "$src/android/src/dev/threedstype/app/SettingsActivity.java"

    # ── 2. Compile SettingsRepository + test class on host JVM ───────────────
    javac -d "$WORK/test-classes" \
      "$src/android/src/dev/threedstype/app/SettingsRepository.java"
    javac -cp "$WORK/test-classes" \
      -d "$WORK/test-classes" \
      "$src/android/test/dev/threedstype/app/SettingsActivityTest.java"
    cp -r "$WORK/test-classes" "$out/classes"

    # ── 3. Write run-tests wrapper ────────────────────────────────────────────
    cat > "$out/bin/run-tests" << WRAPPER
#!${pkgs.bash}/bin/bash
IFS='.' read -r CLASS METHOD <<< "\$1"
exec ${pkgs.jdk17}/bin/java -cp "\$(dirname "\$0")/../classes" "dev.threedstype.app.\$CLASS" "\$METHOD"
WRAPPER
    chmod +x "$out/bin/run-tests"

    # ── 4. Build APK ─────────────────────────────────────────────────────────
    "$BUILD_TOOLS/aapt2" compile \
      --dir "$src/android/res" \
      -o "$WORK/compiled.zip"

    "$BUILD_TOOLS/aapt2" link \
      "$WORK/compiled.zip" \
      -I "$PLATFORM/android.jar" \
      --manifest "$src/android/AndroidManifest.xml" \
      -o "$WORK/app-unsigned.apk"

    java -cp "$BUILD_TOOLS/lib/d8.jar" com.android.tools.r8.D8 \
      --lib "$PLATFORM/android.jar" \
      --output "$WORK/dex" \
      "$WORK/android-classes/dev/threedstype/app/ConnectionState.class" \
      "$WORK/android-classes/dev/threedstype/app/KeyboardCaptureService.class" \
      "$WORK/android-classes/dev/threedstype/app/SettingsActivity.class"

    cp "$WORK/app-unsigned.apk" "$WORK/app-presigned.apk"
    (cd "$WORK/dex" && zip "$WORK/app-presigned.apk" classes.dex)

    keytool -genkeypair \
      -keystore "$WORK/keystore/debug.keystore" \
      -alias androiddebugkey \
      -keyalg RSA -keysize 2048 \
      -validity 10000 \
      -storepass android \
      -keypass android \
      -dname "CN=Android Debug,O=Android,C=US"

    cp "$WORK/app-presigned.apk" "$WORK/app-debug.apk"
    jarsigner \
      -keystore "$WORK/keystore/debug.keystore" \
      -storepass android \
      -keypass android \
      "$WORK/app-debug.apk" \
      androiddebugkey

    cp "$WORK/app-debug.apk" "$out/app-debug.apk"
  '';

  verify = {
    apk-builds   = ''test -f "$out/app-debug.apk"'';
    path-persists = ''"$out/bin/run-tests" SettingsActivityTest.pathPersists'';
  };
}
