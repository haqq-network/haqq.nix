{ config, inputs, ... }:
{
  flake.nixosModules = {
    default = config.flake.nixosModules.haqqd;

    haqqd = {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
      imports = [ ./haqqd ];
    };
  };
}
