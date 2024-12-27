{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

  perSystem =
    { config, ... }:
    {
      overlayAttrs = config.legacyPackages;
    };
}
