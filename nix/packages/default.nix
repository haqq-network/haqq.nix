_: {
  perSystem =
    { pkgs, ... }:
    {
      legacyPackages = {
        cosmovisor = pkgs.callPackage ./cosmovisor.nix { };
        haqqPackages = pkgs.callPackages ./haqq { };
      };
    };
}
