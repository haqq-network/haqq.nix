{ inputs, lib, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  systems = lib.systems.flakeExposed;

  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      pre-commit.settings.hooks = {
        convco.enable = true;
        deadnix.enable = true;
        nixfmt-rfc-style.enable = true;
        statix.enable = true;
        typos = {
          enable = true;
          pass_filenames = false;
        };
      };

      devShells.default = pkgs.mkShell { shellHook = config.pre-commit.installationScript; };
    };
}
