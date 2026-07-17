{
  # amonite task — encapsulated environment for one unit of work.
  #
  # The agent implementing this task works inside `nix develop ./tasks/T007`
  # and sees ONLY the toolchain granted in task.nix. The same task.nix is
  # imported by the project flake for aggregate verification, so this flake
  # is a development capsule, not a fork of truth.
  description = "amonite task capsule — T007: 3DS project scaffold";

  inputs = {
    amonite.url = "path:/home/egor/Code/amonite";
    nixpkgs.follows = "amonite/nixpkgs";
    devkitNix.url = "github:bandithedoge/devkitNix";
    devkitNix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, amonite, devkitNix }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      task = pkgs:
        let pkgs' = pkgs.extend devkitNix.overlays.default;
        in import ./task.nix { pkgs = pkgs'; amonite = amonite.lib { pkgs = pkgs'; }; };
    in
    {
      packages = forAllSystems (pkgs: { default = task pkgs; });
      checks = forAllSystems (pkgs: { task = task pkgs; });
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = (task pkgs).nativeBuildInputs or [ ];
        };
      });
    };
}
