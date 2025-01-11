{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } { imports = [ ./nix ]; };
}
