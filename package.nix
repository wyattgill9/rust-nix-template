{
  pkgs,
  craneLib,
}: 
let
  capnpFilter = path: _type: builtins.match ".*\.capnp$" path != null;
  capnpOrCargo = path: type:
    (capnpFilter path type) || (craneLib.filterCargoSources path type);
in
  src = craneLib.cleanSourceWith {
    src = ./.;
    filter = capnpOrCargo;
    name = "source";
  }

  commonArgs = {
    inherit src;
    strictDeps = true;

    nativeBuildInputs = 
    [
      pkgs.capnproto
    ];

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
