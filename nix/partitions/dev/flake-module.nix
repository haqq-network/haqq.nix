{ inputs, lib, ... }:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  systems = lib.systems.flakeExposed;

  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        shellHook = config.pre-commit.installationScript;
      };

      pre-commit.settings.hooks = {
        convco.enable = true;
        deadnix.enable = true;
        editorconfig-checker.enable = true;
        markdownlint.enable = true;
        nixfmt-rfc-style.enable = true;
        statix.enable = true;
        treefmt.enable = true;
        typos = {
          enable = true;
          pass_filenames = false;
        };
      };

      treefmt.programs = {
        actionlint.enable = true;
        deadnix.enable = true;
        dos2unix.enable = true;
        mdformat.enable = true;
        nixfmt.enable = true;
        statix.enable = true;
        typos.enable = true;
      };
    };
}
