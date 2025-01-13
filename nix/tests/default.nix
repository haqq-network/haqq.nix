{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      legacyPackages.nixosTests = {
        haqqd-basic = pkgs.callPackage ./basic.nix {
          imports = [ inputs.self.nixosModules.haqqd ];
        };
      };

      checks = config.legacyPackages.nixosTests;
    };
}
