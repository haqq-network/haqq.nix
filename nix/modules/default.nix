{ config, inputs, ... }:
{
  flake.nixosModules = {
    default = config.flake.nixosModules.haqqd;

    haqqd = {
      imports = [ ./haqqd ];
      nixpkgs.overlays = [ inputs.self.overlays.default ];
    };
  };
}
