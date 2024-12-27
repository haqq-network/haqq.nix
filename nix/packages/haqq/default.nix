{ callPackage, lib, ... }:
let
  versions = builtins.fromJSON (builtins.readFile ./versions.json);

  latestVersion = lib.last (builtins.sort lib.versionOlder (builtins.attrNames versions));

  fullName = version: "haqq_${builtins.replaceStrings [ "." ] [ "_" ] version}";

  packages = lib.mapAttrs' (
    version: attr:
    lib.nameValuePair (fullName version) (
      callPackage ./derivation.nix {
        inherit version;
        inherit (attr) url hash;
      }
    )
  ) versions;
in
packages // { haqq = builtins.getAttr (fullName latestVersion) packages; }
