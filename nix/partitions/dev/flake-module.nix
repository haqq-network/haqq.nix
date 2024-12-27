{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];

  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
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
