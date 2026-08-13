{ inputs, ... }:
{
  perSystem =
    {
      system,
      lib,
      ...
    }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.rust-overlay.overlays.default ];
      };

      toolchainFile = builtins.fromTOML (builtins.readFile ../rust-toolchain.toml);

      # Devshell: everything rust-toolchain.toml asks for (rust-analyzer, rust-src, ...).
      rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;

      # Builds: same channel and targets, but only what a build actually runs.
      # The `default` profile drags rust-docs (695 MiB), llvm-tools-preview (404 MiB)
      # and rust-src (72 MiB) into the closure of every derivation crane produces.
      buildToolchain = pkgs.rust-bin.fromRustupToolchain {
        inherit (toolchainFile.toolchain) channel;
        targets = toolchainFile.toolchain.targets or [ ];
        profile = "minimal";
        components = [
          "clippy"
          "rustfmt"
        ];
      };

      craneLib = (inputs.crane.mkLib pkgs).overrideToolchain (_: buildToolchain);
    in
    {
      _module.args = {
        inherit pkgs rustToolchain craneLib;
      };
    };
}
