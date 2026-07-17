# Task definition — the single source of truth for this task.
# Referenced by BOTH this capsule's flake (for encapsulated dev/verify)
# and the project flake (for aggregate verification and clustering).
{ pkgs, amonite }:

amonite.mkTask {
  id = "T004";
  title = "Android SettingsRepository + foreground service + notification states";

  src = ../..;

  env = with pkgs; [
    jdk17
    coreutils
  ];

  build = ''
    set -euo pipefail
    WORK=$TMPDIR/t004
    mkdir -p $WORK/classes $out/bin

    javac -d $WORK/classes \
      $src/android/src/dev/threedstype/app/ConnectionState.java \
      $src/android/src/dev/threedstype/app/SettingsRepository.java \
      $src/android/src/dev/threedstype/app/KeyboardService.java \
      $src/android/test/dev/threedstype/app/SettingsRepositoryTest.java \
      $src/android/test/dev/threedstype/app/KeyboardServiceTest.java

    cp -r $WORK/classes $out/classes

    cat > $out/bin/run-tests << WRAPPER
#!${pkgs.bash}/bin/bash
IFS='.' read -r CLASS METHOD <<< "\$1"
exec ${pkgs.jdk17}/bin/java -cp "$out/classes" "dev.threedstype.app.\$CLASS" "\$METHOD"
WRAPPER
    chmod +x $out/bin/run-tests
  '';

  verify = {
    settings-round-trip = ''"$out/bin/run-tests" SettingsRepositoryTest.roundTrip'';
    keyboard-notification-states = ''"$out/bin/run-tests" KeyboardServiceTest.notificationStates'';
  };
}
