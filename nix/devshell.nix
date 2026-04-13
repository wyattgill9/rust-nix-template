{ ... }:
{
  perSystem =
    {
      pkgs,
      rustToolchain,
      craneLib,
      lib,
      config,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          rustToolchain
          pkgs.pkg-config

          pkgs.mold
          pkgs.sccache
          pkgs.clang
          pkgs.lldb

          pkgs.cargo-nextest
          pkgs.cargo-llvm-cov
        ];

        buildInputs =
          with pkgs;
          [
            # openssl
          ]
          ++ lib.optionals pkgs.stdenv.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.Security
            pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
          ];

        RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

        shellHook = ''
          export RUSTC_WRAPPER=sccache
          export RUSTFLAGS="''${RUSTFLAGS:-} -C link-arg=-fuse-ld=mold"
        '';
      };
    };
}
