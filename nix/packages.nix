{...}: {
  perSystem = {
    pkgs,
    craneLib,
    config,
    wildRustflags,
    ...
  }: let
    src = craneLib.cleanCargoSource ../.;

    commonArgs = {
      inherit src;
      strictDeps = true;

      # wild linker for every crate (deps, bin, tests, clippy).
      CARGO_BUILD_RUSTFLAGS = wildRustflags;

      # Native deps go here; the devshell inherits both lists.
      nativeBuildInputs = with pkgs; [];
      buildInputs = with pkgs; [];
    };

    cargoArtifacts = craneLib.buildDepsOnly commonArgs;

    mkCrate = pname:
      craneLib.buildPackage (
        commonArgs
        // {
          inherit cargoArtifacts pname;
          cargoExtraArgs = "-p ${pname}";
        }
      );
  in {
    packages = {
      cli = mkCrate "cli";
      default = config.packages.cli;
    };

    # `nix flake check` runs these plus treefmt (added by the treefmt-nix module).
    checks = {
      clippy = craneLib.cargoClippy (
        commonArgs
        // {
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        }
      );

      test = craneLib.cargoNextest (
        commonArgs
        // {
          inherit cargoArtifacts;
        }
      );
    };

    _module.args = {inherit commonArgs;};
  };
}
