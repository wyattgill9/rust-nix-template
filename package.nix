{
  pkgs,
  craneLib,
}: let
  src = craneLib.cleanCargoSource ./.;

  commonArgs = {
    inherit src;
    strictDeps = true;

    buildInputs =
      []
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pkgs.libiconv
      ];
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
  craneLib.buildPackage (commonArgs
    // {
      inherit cargoArtifacts;
    })
