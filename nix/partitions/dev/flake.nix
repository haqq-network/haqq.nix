{
  inputs = {
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        flake-compat.follows = "";
        gitignore.follows = "";
        nixpkgs.follows = "";
      };
    };
  };

  outputs = _: { };
}
