# Task T002 — Android project scaffold
# Produces: $out/app-debug.apk
# Strategy: manual APK assembly using Android SDK tools (no Gradle, no network).
#   1. aapt2 compile + link  → binary manifest + resource table + unsigned APK
#   2. javac                 → .class files for KeyboardCaptureService stub
#   3. d8 (via java -cp)     → classes.dex
#   4. zip                   → add classes.dex to APK
#   5. jarsigner             → self-signed debug signature
{ pkgs, amonite }:

let
  # Re-import nixpkgs with unfree + Android license accepted.
  # This is necessary because the project flake passes legacyPackages (no
  # allowUnfree config) but the Android SDK is unfree and requires explicit
  # license acceptance.
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

  # Resolve the SDK root path at evaluation time so we can hardcode it.
  sdkRoot = "${androidSdk}/libexec/android-sdk";

in amonite.mkTask {
  id    = "T002";
  title = "Android project scaffold — app-debug.apk with KeyboardCaptureService";

  # The android/ subtree is the only source this task needs.
  src = ../../android;

  env = with pkgs; [
    androidSdk
    jdk21
    zip
    unzip
    coreutils
  ];

  build = ''
    set -euo pipefail

    SDK="${sdkRoot}"
    BUILD_TOOLS="$SDK/build-tools/34.0.0"
    PLATFORM="$SDK/platforms/android-34"

    WORK="$TMPDIR/apk-build"
    mkdir -p "$WORK"/{classes,dex,keystore}

    # ── 1. Compile resources ─────────────────────────────────────────────────
    "$BUILD_TOOLS/aapt2" compile \
      --dir "$src/res" \
      -o "$WORK/compiled.zip"

    # ── 2. Link resources + binary AndroidManifest ───────────────────────────
    "$BUILD_TOOLS/aapt2" link \
      "$WORK/compiled.zip" \
      -I "$PLATFORM/android.jar" \
      --manifest "$src/AndroidManifest.xml" \
      -o "$WORK/app-unsigned.apk"

    # ── 3. Compile Java stub ─────────────────────────────────────────────────
    javac \
      -source 8 -target 8 \
      -Xlint:-options \
      -cp "$PLATFORM/android.jar" \
      -d "$WORK/classes" \
      "$src/src/dev/threedstype/app/KeyboardCaptureService.java"

    # ── 4. Convert .class → .dex ─────────────────────────────────────────────
    java -cp "$BUILD_TOOLS/lib/d8.jar" com.android.tools.r8.D8 \
      --lib "$PLATFORM/android.jar" \
      --output "$WORK/dex" \
      "$WORK/classes/dev/threedstype/app/KeyboardCaptureService.class"

    # ── 5. Add classes.dex to APK ────────────────────────────────────────────
    cp "$WORK/app-unsigned.apk" "$WORK/app-presigned.apk"
    (cd "$WORK/dex" && zip "$WORK/app-presigned.apk" classes.dex)

    # ── 6. Generate debug signing key ────────────────────────────────────────
    keytool -genkeypair \
      -keystore "$WORK/keystore/debug.keystore" \
      -alias androiddebugkey \
      -keyalg RSA -keysize 2048 \
      -validity 10000 \
      -storepass android \
      -keypass android \
      -dname "CN=Android Debug,O=Android,C=US"

    # ── 7. Sign APK ──────────────────────────────────────────────────────────
    cp "$WORK/app-presigned.apk" "$WORK/app-debug.apk"
    jarsigner \
      -keystore "$WORK/keystore/debug.keystore" \
      -storepass android \
      -keypass android \
      "$WORK/app-debug.apk" \
      androiddebugkey

    # ── 8. Install artifact ──────────────────────────────────────────────────
    mkdir -p "$out"
    cp "$WORK/app-debug.apk" "$out/app-debug.apk"
  '';

  verify = {
    apk-exists    = ''test -f "$out/app-debug.apk"'';
    apk-valid-zip = ''unzip -t "$out/app-debug.apk"'';
  };
}
