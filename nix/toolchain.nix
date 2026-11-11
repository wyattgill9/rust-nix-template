{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [inputs.rust-overlay.overlays.default];
    };

    rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;

    craneLib = (inputs.crane.mkLib pkgs).overrideToolchain (_: rustToolchain);

    # Force rustc onto wild (Linux/ELF only) by pointing gcc at wild's `ld` via
    # -B. CI proves it: `readelf -p .comment result/bin/cli` -> "Linker: Wild".
    #
    # x86_64 also has to switch off rustc's self-contained lld first, which is
    # the default there. Only there: no other target bundles lld, and rustc
    # rejects these two flags as unstable on aarch64.
    wildRustflags = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux (
      pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isx86_64 "-C linker-features=-lld -C link-self-contained=-linker "
      + "-C link-arg=-B${pkgs.wild}/bin"
    );
  in {
    _module.args = {
      inherit pkgs rustToolchain craneLib wildRustflags;
    };
  };
}
