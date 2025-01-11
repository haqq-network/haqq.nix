{ lib, ... }:
{
  imports = [
    ./modules
    ./overlays.nix
    ./packages
    ./partitions
    ./tests
  ];

  systems = lib.systems.flakeExposed;
}
