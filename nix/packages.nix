{...}: {
  perSystem = {
    pkgs,
    config,
    lib,
    ...
  }: let
    src = lib.cleanSource ../.;

    # Native deps go here; the devshell inherits both lists.
    commonArgs = {
      nativeBuildInputs = with pkgs; [];
      buildInputs = with pkgs; [];
    };

    # `builtins.outputOf` only exists when the `dynamic-derivations`
    # experimental feature is on. Without it the failure surfaces deep inside
    # nixpkgs' trivial builders as "attribute 'outputOf' missing", which names
    # neither the feature nor the daemon setting that is actually wrong.
    checkNixSupport = lib.throwIf (!(builtins ? outputOf)) ''
      cargo-dyndrv needs Nix's dynamic derivations, which are not enabled here.

      This must be set for the DAEMON, not just the client -- passing
      --extra-experimental-features on the command line is not enough,
      because the daemon does the check. In /etc/nix/nix.conf (or
      nix.settings on NixOS):

          experimental-features = nix-command flakes ca-derivations dynamic-derivations
          system-features       = ... ca-derivations builder-rpc-v0

      You also need a Nix that implements `builder-rpc-v0`. It merged in
      NixOS/nix#15793 on 2026-07-21 and is NOT in any tagged release
      (2.35.2 included). Use pkgs.nixVersions.git (2.36pre or newer).

      See README.md, "Nix requirements".
    '';

    # One Nix derivation per Cargo compilation unit, submitted at build time
    # over Nix's builder-rpc and resolved with `builtins.outputOf`. No IFD.
    #
    # `outputs` must name each ROOT unit's `target.name` from the unit graph;
    # `cargoBuildFlags` is what scopes the graph down to those roots. A package
    # with both a lib and a bin of the same name needs one build per target
    # until cargo-dyndrv disambiguates colliding root names.
    mkCrate = pname:
      checkNixSupport (pkgs.buildDynamicCrate (
        commonArgs
        // {
          inherit pname src;
          version = "0.1.0";
          cargoLock.lockFile = ../Cargo.lock;
          cargoBuildFlags = ["-p" pname];
          outputs = [pname];
        }
      ));
  in {
    packages = {
      cli = mkCrate "cli";
      default = config.packages.cli;
    };

    # No `checks` here. cargo-dyndrv has no clippy path, and `cargo test` is
    # not yet supported (its unit graph fails to parse, and test units are not
    # given --test). `nix flake check` runs treefmt only. Use `cargo clippy`
    # and `cargo nextest run` in the devshell.

    _module.args = {inherit commonArgs;};
  };
}
