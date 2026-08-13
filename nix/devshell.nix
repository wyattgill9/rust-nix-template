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
          pkgs.lldb
          pkgs.sccache
          pkgs.cargo-nextest

          pkgs.pkg-config
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wild ];

        buildInputs = with pkgs; [
          # openssl
        ];

        RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

        shellHook = ''
          export RUSTC_WRAPPER=sccache
        ''
        + lib.optionalString pkgs.stdenv.isLinux ''
          export RUSTFLAGS="''${RUSTFLAGS:-} -C link-arg=-fuse-ld=wild"
        '';
      };
    };
}
