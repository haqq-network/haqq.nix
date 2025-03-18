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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "";
    };
  };

  outputs = _: { };
}
