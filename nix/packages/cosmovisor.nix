{
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  lib,
}:
buildGoModule rec {
  pname = "cosmovisor";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "cosmos";
    repo = "cosmos-sdk";
    rev = "refs/tags/cosmovisor/v${version}";
    hash = "sha256-3+yQTka62jiZ0asgzrj+43EE4E2NODQAr5vfoyYcOuc=";
  };
  sourceRoot = "${src.name}/tools/cosmovisor";

  vendorHash = "sha256-lyJgsVSX41RPzTVRCwnWYt2MxxrjvvbkOlXZ9kK/Xek=";

  nativeBuildInputs = [ installShellFiles ];

  subPackages = [ "cmd/cosmovisor" ];

  ldflags = [
    "-w"
    "-s"
  ];

  postInstall = ''
    installShellCompletion --cmd cosmovisor \
      --bash <($out/bin/cosmovisor completion bash) \
      --fish <($out/bin/cosmovisor completion fish) \
      --zsh <($out/bin/cosmovisor completion zsh)
  '';

  meta = {
    description = ''
      Cosmovisor is a process manager for Cosmos SDK application binaries that
      automates application binary switch at chain upgrades
    '';
    homepage = "https://docs.cosmos.network/main/build/tooling/cosmovisor";
    license = builtins.attrValues { inherit (lib.licenses) gpl3 lgpl3; };
    mainProgram = "cosmovisor";
  };
}
