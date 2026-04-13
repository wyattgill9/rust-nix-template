{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      craneLib,
      lib,
      ...
    }:
    let
      src = craneLib.cleanCargoSource ../.;

      commonArgs = {
        inherit src;
        strictDeps = true;

        nativeBuildInputs = with pkgs; [
          pkg-config
        ];

        buildInputs =
          with pkgs;
          [
            openssl
          ]
          ++ lib.optionals pkgs.stdenv.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.Security
            pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
          ];
      };

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      mkCrate =
        pname:
        craneLib.buildPackage (
          commonArgs
          // {
            inherit cargoArtifacts;
            cargoExtraArgs = "-p ${pname}";
          }
        );
    in
    {
      packages = {
        cli = mkCrate "cli";
        default = mkCrate "cli";
      };

      _module.args = {
        inherit commonArgs cargoArtifacts src;
      };
    };
}
