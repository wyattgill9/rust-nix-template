{...}: {
  perSystem = {
    pkgs,
    rustToolchain,
    commonArgs,
    wildStdenv,
    ...
  }: {
    devShells.default = (pkgs.mkShell.override {stdenv = wildStdenv;}) {
      inherit (commonArgs) buildInputs;

      nativeBuildInputs =
        commonArgs.nativeBuildInputs
        ++ [
          rustToolchain
          pkgs.lldb
          pkgs.sccache
          pkgs.cargo-nextest
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [pkgs.wild];

      RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
      RUSTC_WRAPPER = "sccache";
    };
  };
}
