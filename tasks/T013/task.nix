# T013: 3DS DraftManager list + launch-screen UI
# On app launch: scans /3ds/typewriter/*.txt, sorts by mtime descending,
# renders a scrollable list on the top screen (D-Up/D-Down to move,
# A to open, Start for new draft). Host-side test verifies sort order
# with 3 stub files. Cross-compile verifies the full app builds with
# the launch screen integrated.
# Depends: T007 (3DS scaffold), T012 (DraftManager save / file format)
{ pkgs, amonite }:

amonite.mkTask {
  id = "T013";
  title = "3DS DraftManager list + launch-screen — sorted by mtime desc, D-pad nav, A/Start";

  src = ../..;

  env = with pkgs; [
    gcc
    gnumake
    xxd
    coreutils
  ];

  build = ''echo "T013 not yet implemented" >&2 && exit 1'';

  verify = {
    list-sort = ''
      "$out/bin/draft_list_test"
    '';
    cross-compile = ''
      test -f "$out/typewriter.3dsx"
    '';
    magic-3dsx = ''
      ${pkgs.xxd}/bin/xxd -l 4 "$out/typewriter.3dsx" | grep -q "3344 5358"
    '';
  };
}
