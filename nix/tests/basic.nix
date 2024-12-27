{
  imports,
  jq,
  moreutils,
  nixosTest,
}:
let
  moniker = "haqqd-basic";
  chain-id = "haqq_11111-1";
in
nixosTest {
  name = "haqqd-basic";

  nodes.server = _: {
    inherit imports;

    services.haqqd = {
      enable = true;

      enableMutableSettings = true;
      settings = {
        app = {
          api = {
            enable = true;
            address = "tcp://0.0.0.0:1317";
          };
          grpc = {
            enable = true;
            address = "0.0.0.0:9090";
          };
          grpc-web = {
            enable = true;
            address = "0.0.0.0:9091";
          };
          json-rpc = {
            enable = true;
            address = "0.0.0.0:8545";
            ws-address = "0.0.0.0:8546";
          };
        };

        config = {
          inherit moniker;
          p2p = {
            laddr = "tcp://0.0.0.0:26656";
            seeds = "";
            persistent_peers = "";
            pex = false;
          };
          rpc.laddr = "tcp://0.0.0.0:26657";
        };

        client = {
          inherit chain-id;
          node = "tcp://127.0.0.1:26657";
        };
      };

      extraPreStartup = ''
        haqqd config keyring-backend test
        haqqd config chain-id ${chain-id}
        haqqd keys add test --keyring-backend test
      '';

      extraPostStartup = ''
        g() {
          local genesis="$DAEMON_HOME/config/genesis.json"
          jq "$1" "$genesis" | sponge "$genesis"
        }
        g '.chain_id = "${chain-id}"'
        g '.app_state["coinomics"]["max_supply"]["amount"] = "100000000000000000000000000000"'
        g '.app_state["coinomics"]["max_supply"]["denom"] = "aISLM"'
        g '.app_state["coinomics"]["params"]["enable_coinomics"] = true'
        g '.app_state["coinomics"]["params"]["mint_denom"] = "aISLM"'
        g '.app_state["crisis"]["constant_fee"]["amount"] = "50000000000000000000000"'
        g '.app_state["crisis"]["constant_fee"]["denom"] = "aISLM"'
        g '.app_state["evm"]["params"]["evm_denom"] = "aISLM"'
        g '.app_state["gov"]["params"]["min_deposit"][0]["amount"] = "5000000000000000000000"'
        g '.app_state["gov"]["params"]["min_deposit"][0]["denom"] = "aISLM"'
        g '.app_state["staking"]["params"]["bond_denom"] = "aISLM"'

        addr="$(haqqd keys show test -a --keyring-backend test)"
        haqqd add-genesis-account "$addr" 20000000000000000000000000000aISLM

        haqqd gentx test 1000000000000000000000aISLM --keyring-backend test --chain-id ${chain-id}
        haqqd collect-gentxs

        haqqd validate-genesis
      '';
    };

    systemd.services.haqqd.path = [
      jq
      moreutils
    ];
  };

  testScript = ''
    import json

    with subtest("Ensure bootstrap is successful"):
      server.wait_for_file("/var/lib/haqqd/.haqqd/.bootstrapped")

    with subtest("Ensure the systemd service is operational"):
      server.wait_for_unit("haqqd.service")

    with subtest("Ensure all ports are open and connectable"):
      server.wait_for_open_port(26656)
      server.wait_for_open_port(26657)
      server.wait_for_open_port(1317)
      server.wait_for_open_port(9090)
      server.wait_for_open_port(9091)
      server.wait_for_open_port(8545)
      server.wait_for_open_port(8546)

    with subtest("Ensure haqqctl is working as expected"):
      moniker = json.loads(server.succeed("haqqctl status"))["NodeInfo"]["moniker"]
      assert moniker == "${moniker}"
  '';
}
