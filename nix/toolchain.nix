{inputs, ...}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.rust-overlay.overlays.default
        # provides `buildDynamicCrate` and `writeExtern`
        inputs.cargo-dyndrv.overlays.default
      ];
    };

    rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;

    # Force rustc onto wild (Linux/ELF only). rustc defaults to self-contained
    # lld; disable it and point gcc at wild's `ld` via -B (gcc 15 rejects
    # -fuse-ld=wild). Proof: `readelf -p .comment result/bin/cli` -> "Linker: Wild".
    # When nixpkgs' default gcc reaches 16, collapse to "-C link-arg=-fuse-ld=wild".
    #
    # NOTE: this reaches the devshell only. cargo-dyndrv builds each unit by
    # invoking rustc itself, and Cargo's `--unit-graph` does not carry rustflags,
    # so the package build below does NOT link with wild. See README.
    wildRustflags =
      if pkgs.stdenv.hostPlatform.isLinux
      then "-C linker-features=-lld -C link-self-contained=-linker -C link-arg=-B${pkgs.wild}/bin"
      else "";
  in {
    _module.args = {
      inherit pkgs rustToolchain wildRustflags;
    };
  };
}
