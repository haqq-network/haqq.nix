# haqq.nix

This repository aims to provide Nix and NixOS entrypoints for the Haqq
ecosystem.

> [!WARNING]
> We only support `x86_64-linux` target. Support for anything over than that is
> not planned at this point in time. Contributions are welcome.

## Quick Start

> [!NOTE]
> A user must be somewhat proficient with Nix and NixOS. If not, please consider
> following our [official installation
> instructions](https://docs.haqq.network/network/run-node/).

Add `haqq.nix` to your `flake.nix` and import desired module. For example:

``` nix
{
  description = "My Haqq node";
  inputs = {
    haqq.url = "github:haqq-network/haqq.nix";
    nixpkgs.follows = "haqq";
  };
  outputs = inputs: {
    nixosConfigurations.myHaqqNode = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.haqq.nixosModules.haqqd
        ({ pkgs, ... }: {
          services.haqqd = {
            enable = true;
            settings = {
              app = {
                pruning = "custom";
                pruning-interval = 10;
                pruning-keep-recent = 30000;
                min-retain-blocks = 30000;
                api = {
                  enable = true;
                  address = "tcp://0.0.0.0:1317";
                };
              };
              config = {
                moniker = "my-haqq-node";
                p2p.laddr = "tcp://0.0.0.0:26656";
                rpc.laddr = "tcp://0.0.0.0:26657";
              }
            };
            extraPreStartup = ''
              if [ ! -f "$DAEMON_HOME/.bootstrapped" ]; then
                index="https://pub-70119b7efa294225aa1b869b2a15c7f4.r2.dev/index.json"
                snapshot="$(curl -s "$index" | jq -r .pruned[0].link)"
                wget -qO- "$snapshot" | \
                  lz4 -d - | \
                  tar -C "$DAEMON_HOME" -x -f -
              fi
            '';
          };
          systemd.services.haqqd.path = with pkgs; [ curl jq wget lz4 gnutar ];
        })
      ];
    };
  };
}
```

This will enable and launch a `haqqd.service` systemd service, which will
download a latest pruned snapshot on the first start. You can look up available
options in the source code for the module.

We plan on adding more documentation and guides in the future.

## License

[Apache 2.0](./LICENSE)
