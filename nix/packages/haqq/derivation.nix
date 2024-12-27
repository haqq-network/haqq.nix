{
  fetchurl,
  hash ? null,
  lib,
  stdenv,
  url ? null,
  version ? null,
}:
stdenv.mkDerivation {
  pname = "haqq";
  inherit version;

  src = fetchurl { inherit url hash; };
  sourceRoot = ".";

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${lib.makeLibraryPath [ stdenv.cc.libc ]}" \
      bin/haqqd
    install -Dm755 -t $out/bin bin/haqqd

    $out/bin/haqqd init default --home . --chain-id haqq_11235-1
    install -Dm644 -t $out/share/haqqd/config config/app.toml
    install -Dm644 -t $out/share/haqqd/config config/client.toml
    install -Dm644 -t $out/share/haqqd/config config/config.toml

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Shariah-compliant Web3 platform";
    longDescription = ''
      Haqq is a scalable, high-throughput Proof-of-Stake blockchain that is
      fully compatible and interoperable with Ethereum. It's built using the
      Cosmos SDK which runs on top of CometBFT consensus engine. Ethereum
      compatibility allows developers to build applications on Haqq using the
      existing Ethereum codebase and toolset, without rewriting smart contracts
      that already work on Ethereum or other Ethereum-compatible networks.
      Ethereum compatibility is done using modules built by Tharsis for their
      Evmos network.
    '';
    homepage = "https://haqq.network";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "haqqd";
  };
}
