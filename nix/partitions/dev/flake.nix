{
  inputs = {
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "";
    };
  };

  outputs = _: { };
}
