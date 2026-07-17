# Task definition — the single source of truth for this task.
# Referenced by BOTH this capsule's flake (for encapsulated dev/verify)
# and the project flake (for aggregate verification and clustering).
{ pkgs, amonite }:

amonite.mkTask {
  id = "T005"; # amonite task id, matches tasks.md
  title = "Android DraftStorage module";

  # Source this task builds from. Usually the project root filtered to
  # what the task may see — keep the aperture as narrow as possible.
  src = ../..;

  # Encapsulation boundary: everything this task's build and dev shell
  # may use. Nothing else is available.
  env = with pkgs; [
    jdk17
    coreutils
    bash
  ];

  # Build: produce the task's artifacts under $out.
  build = ''
    set -euo pipefail
    WORK=$TMPDIR/t005
    mkdir -p $WORK/classes $out/bin

    javac -d $WORK/classes \
      $src/android/src/dev/threedstype/app/DraftStorage.java \
      $src/android/test/dev/threedstype/app/DraftStorageTest.java

    cp -r $WORK/classes $out/classes

    cat > $out/bin/run-tests << 'WRAPPER'
#!/usr/bin/env bash
IFS='.' read -r CLASS METHOD <<< "$1"
exec java -cp "$(dirname "$0")/../classes" "dev.threedstype.app.$CLASS" "$METHOD"
WRAPPER
    chmod +x $out/bin/run-tests
    patchShebangs $out/bin/run-tests
  '';

  # Acceptance criteria from tasks.md, made mechanical. Every entry must
  # exit 0 or the task does not exist as a derivation.
  verify = {
    writeAndReadBack = ''"$out/bin/run-tests" DraftStorageTest.writeAndReadBack'';
    pathConfigurable = ''"$out/bin/run-tests" DraftStorageTest.pathConfigurable'';
  };
}
