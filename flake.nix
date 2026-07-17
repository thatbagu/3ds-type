{
  description = "amonite project — meta environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    amonite.url = "path:/home/egor/Code/amonite"; # switch to github:Amonite-AI/amonite after push
    amonite.inputs.nixpkgs.follows = "nixpkgs";
    devkitNix.url = "github:bandithedoge/devkitNix";
    devkitNix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, amonite, devkitNix }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Single computation of the task/cluster graph, shared by packages,
      # checks, and the graph output.
      graphFor = pkgs:
        let
          pkgs' = pkgs.extend devkitNix.overlays.default;
          am = amonite.lib { pkgs = pkgs'; };
          tasks = am.loadTasks { root = ./.; amonite = am; };
          clustersFile = ./clusters.nix;
          clusters =
            if builtins.pathExists clustersFile
            then import clustersFile { pkgs = pkgs'; inherit tasks; amonite = am; }
            else { };
        in
        { inherit am tasks clusters; };
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # amonite:toolchain — keep minimal; task tools go in task.nix env
          packages = [
            amonite.packages.${pkgs.system}.default  # amonite CLI always available
            pkgs.git
            pkgs.jdk17           # Gradle + JVM unit test runner
            pkgs.android-tools   # adb for APK sideloading (gate.live)
            # devkitPro/devkitARM → task envs only (T007+)
          ];
        };
      });

      # Every tasks/*/task.nix, loaded and exposed:
      #   nix build .#task-T001      → build + verify one task
      #   nix flake check            → verify everything decomposed so far
      packages = forAllSystems (pkgs:
        let inherit (graphFor pkgs) tasks clusters;
        in
        nixpkgs.lib.mapAttrs' (id: drv: { name = "task-${id}"; value = drv; }) tasks
        // nixpkgs.lib.mapAttrs' (id: drv: { name = "cluster-${id}"; value = drv; }) clusters
        // nixpkgs.lib.optionalAttrs (clusters ? APP) { default = clusters.APP; });

      checks = forAllSystems (pkgs: self.packages.${pkgs.system});

      # Serializable derivation hierarchy for tooling:
      #   nix eval .#graph.<system> --json   (consumed by `amonite dashboard`)
      graph = forAllSystems (pkgs:
        let inherit (graphFor pkgs) am tasks clusters;
        in am.mkGraph { inherit tasks clusters; });
    };
}
