{pkgs, toolchain, ...}:

pkgs.mkShell {
  buildInputs = [
    toolchain
    pkgs.capnproto
  ];

  shellHook = ''
    echo "Cargo: $(cargo --version | head -n1)"
    echo "Rust: $(rustc --version)"
    echo "capnp: $(capnp --version)"
  '';
}
