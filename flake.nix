{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    crane,
    fenix,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-darwin"];

    forAllSystems = f:
      builtins.foldl' (
        attrs: system: let
          ret = f system;
        in
          builtins.foldl' (
            attrs: key:
              attrs
              // {
                ${key} =
                  (attrs.${key} or {})
                  // {
                    ${system} = ret.${key};
                  };
              }
          )
          attrs (builtins.attrNames ret)
      ) {}
      systems;
  in
    forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        toolchain = fenix.packages.${system}.stable.toolchain;

        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

        commonArgs = {
          src = craneLib.cleanCargoSource ./.;
          strictDeps = true;

          buildInputs = []
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.libiconv
            ];
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        rust-package = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });
      in {
        formatter = pkgs.alejandra;

        checks = {
          inherit rust-package;
        };

        packages.default = rust-package;

        devShells.default = pkgs.mkShell {
          packages = [
            toolchain
          ];

          buildInputs = commonArgs.buildInputs;

          RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
        };
      }
    );
}
