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

          pkgs.sccache
          pkgs.lldb

          pkgs.cargo-nextest
        ]
        # mold and wild are ELF-only, so Linux-only.
        ++ lib.optionals pkgs.stdenv.isLinux [
          pkgs.mold
          pkgs.wild
        ];

        # Darwin SDK frameworks come from the stdenv now — no apple_sdk stubs.
        buildInputs = with pkgs; [
          # openssl
        ];

        RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

        shellHook = ''
          # No-op until the workspace has dependencies: sccache can't cache bin crates
          # (they link) or incremental units. Pays off ~-40% on release rebuilds later.
          export RUSTC_WRAPPER=sccache
        ''
        + lib.optionalString pkgs.stdenv.isLinux ''
          # Pick the linker with LINKER=wild (or LINKER=lld, LINKER=bfd, ...).
          export RUSTFLAGS="''${RUSTFLAGS:-} -C link-arg=-fuse-ld=''${LINKER:-mold}"
        '';
      };
    };
}
