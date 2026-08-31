{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [inputs.rust-overlay.overlays.default];
    };

    rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;

    # wild is Linux-only; the adapter throws on darwin, so guard it.
    wildStdenv =
      if pkgs.stdenv.hostPlatform.isLinux
      then pkgs.stdenvAdapters.useWildLinker pkgs.stdenv
      else pkgs.stdenv;

    craneLib =
      ((inputs.crane.mkLib pkgs).overrideToolchain (_: rustToolchain))
      .overrideScope (_final: _prev: {
        stdenvSelector = _p: wildStdenv;
      });
  in {
    _module.args = {
      inherit pkgs rustToolchain craneLib wildStdenv;
    };
  };
}
