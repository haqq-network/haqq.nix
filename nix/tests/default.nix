{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      legacyPackages.nixosTests = {
        haqqd-basic = pkgs.callPackage ./basic.nix {
          imports = [ inputs.self.nixosModules.haqqd ];
        };
      };
    };
}
