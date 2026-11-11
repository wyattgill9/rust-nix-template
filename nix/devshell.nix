{...}: {
  perSystem = {
    pkgs,
    rustToolchain,
    commonArgs,
    wildRustflags,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      inherit (commonArgs) buildInputs;

      nativeBuildInputs =
        commonArgs.nativeBuildInputs
        ++ [
          rustToolchain
          pkgs.lldb
          pkgs.sccache
          pkgs.cargo-nextest
        ];

      # Same wild flags as the package build, so `cargo` here links with wild too.
      CARGO_BUILD_RUSTFLAGS = wildRustflags;

      RUSTC_WRAPPER = "sccache";
    };
  };
}
