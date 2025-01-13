_: {
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      legacyPackages = {
        cosmovisor = pkgs.callPackage ./cosmovisor.nix { };
        haqqPackages = pkgs.callPackages ./haqq { };
      };

      checks = config.legacyPackages.haqqPackages;
    };
}
