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
    
    eachSystem = f: nixpkgs.lib.genAttrs systems (system: f {
      inherit system;
      pkgs = nixpkgs.legacyPackages.${system};
      toolchain = fenix.packages.${system}.stable.toolchain;
      craneLib = (crane.mkLib nixpkgs.legacyPackages.${system}).overrideToolchain 
        fenix.packages.${system}.stable.toolchain;
    });
  in {
    packages = eachSystem ({pkgs, craneLib, ...}: {
      default = import ./package.nix {inherit pkgs craneLib;};
    });
  };
}
