{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.services.haqqd;

  toml = pkgs.formats.toml { };
in
{
  options.services.haqqd = {
    enable = lib.mkEnableOption "shariah-compliant Web3 platform daemon";

    packages = {
      upgrades = lib.mkOption {
        type = with lib.types; listOf package;
        default = lib.mapAttrsToList (_: package: package) pkgs.haqqPackages;
        description = ''
          A list of packages to be used by Cosmovisor for upgrades. By default
          includes all available releases.
        '';
      };

      genesis = lib.mkOption {
        type = lib.types.package;
        default = lib.head cfg.packages.upgrades;
        description = ''
          A package that will be used for the initial start of the node. Managed
          by Cosmovisor.
        '';
      };

      config = lib.mkOption {
        type = lib.types.package;
        default = lib.last cfg.packages.upgrades;
        description = ''
          A package that will be used for node configuration. You probably will
          never have to change this.
        '';
      };
    };

    enableMutableSettings = lib.mkEnableOption ''
      copying configuration files from the store instead of linking them. This
      can be enabled if there's a need to dynamically alter these files. For
      example to calculate block and hash to initialise the daemon from state
      sync.
    '';

    settings = {
      app = lib.mkOption {
        inherit (toml) type;
        default = { };
        description = ''
          User-defined configuration for $DAEMON_HOME/config/app.toml. This will
          override any default values from that file.
        '';
        example = {
          pruning = "custom";
          pruning-interval = 10;
          pruning-keep-recent = 30000;
          min-retain-blocks = 30000;
          api = {
            enable = true;
            address = "tcp://0.0.0.0:1317";
          };
          json-rpc = {
            enable = true;
            address = "0.0.0.0:8545";
            ws-address = "0.0.0.0:8546";
          };
        };
      };

      config = lib.mkOption {
        inherit (toml) type;
        default = { };
        description = ''
          User-defined configuration for $DAEMON_HOME/config/config.toml. This
          will override any default values from that file.
        '';
        example = {
          moniker = "haqq-on-nixos";
          p2p = {
            laddr = "tcp://0.0.0.0:26656";
            seeds = "";
            persistent_peers = "";
            pex = false;
          };
          rpc.laddr = "tcp://0.0.0.0:26657";
          statesync = {
            enable = true;
            rpc_servers = "https://rpc.tm.haqq.network:443,https://rpc.haqq.sh:443";
          };
          instrumentation = {
            prometheus = true;
            prometheus_listen_addr = "127.0.0.1:26660";
          };
        };
      };

      client = lib.mkOption {
        inherit (toml) type;
        default = { };
        description = ''
          User-defined configuration for $DAEMON_HOME/config/client.toml. This
          will override any default values from that file.
        '';
        example = {
          chain-id = "haqq_11235-1";
          node = "tcp://127.0.0.1:26657";
        };
      };
    };

    finalSettings =
      let
        generateTOML =
          name:
          let
            default = lib.importTOML "${cfg.packages.config}/share/haqqd/config/${name}.toml";
          in
          lib.pipe cfg.settings.${name} [
            (lib.recursiveUpdate default)
            (toml.generate "${name}.toml")
          ];
      in
      {
        app = lib.mkOption {
          inherit (options.services.haqqd.settings.app) type;
          default = generateTOML "app";
          readOnly = true;
          description = ''
            Final derivation for $DAEMON_HOME/config/app.toml. This fill will be
            used by the service.
          '';
        };

        config = lib.mkOption {
          inherit (options.services.haqqd.settings.config) type;
          default = generateTOML "config";
          readOnly = true;
          description = ''
            Final derivation for $DAEMON_HOME/config/config.toml. This fill will
            be used by the service.
          '';
        };

        client = lib.mkOption {
          inherit (options.services.haqqd.settings.client) type;
          default = generateTOML "client";
          readOnly = true;
          description = ''
            Final derivation for $DAEMON_HOME/config/client.toml. This fill will
            be used by the service.
          '';
        };
      };

    extraPreStartup = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra commands to be executed during early stages of startup. Don't
        forget to make configuration files mutable before trying to change them.
      '';
      example = lib.literalExpression ''
        if [ ! -f "$DAEMON_HOME/.bootstrapped" ]; then
          index="https://pub-70119b7efa294225aa1b869b2a15c7f4.r2.dev/index.json"
          snapshot="$(curl -s "$index" | jq -r .pruned[0].link)"
          wget -qO- "$snapshot" | \
            lz4 -d - | \
            tar -C "$DAEMON_HOME" -x -f -
        fi
      '';
    };

    extraPostStartup = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra commands to be executed during late stages of startup. Don't
        forget to make configuration files mutable before trying to change them.
      '';
      example = lib.literalExpression ''
        if [ ! -f "$DAEMON_HOME/.bootstrapped" ]; then
          block_url="https://rpc.tm.haqq.network/block"
          height="$(curl -s "$block_url" | jq -r '.result.block.header.height')"
          trust_height="$((height - 3000))"
          height_url="https://rpc.tm.haqq.network/block?height=$trust_height"
          trust_hash="$(curl -s "$height_url" | jq -r '.result.block_id.hash')"

          jq -nR \
            --arg trust_height "$trust_height" \
            --arg trust_hash "$trust_hash" \
            '{trust_height: $trust_height, trust_hash: $trust_hash}' \
            >"$DAEMON_HOME/state-sync.json"
        else
          trust_height="$(jq -r .trust_height <"$DAEMON_HOME/state-sync.json")"
          trust_hash="$(jq -r .trust_hash <"$DAEMON_HOME/state-sync.json")"
        fi

        dasel put -f "$DAEMON_HOME/config/config.toml" \
          -t int -v "$trust_height" statesync.trust_height
        dasel put -f "$DAEMON_HOME/config/config.toml" \
          -t string -v "$trust_hash" statesync.trust_hash
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "haqqd";
      description = ''
        User that will run the service.
      '';
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "haqqd";
      description = ''
        Group that will run the service.
      '';
    };

    stateDirectory = lib.mkOption {
      type = with lib.types; nullOr str;
      default = "/var/lib/haqqd";
      description = ''
        A directory to hold service state. For cosmovisor and haqqd to work it
        will be treated as a $HOME directory. If set to null, the systemd
        service will run as a DynamicUser.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users = lib.mkIf (cfg.user == "haqqd") {
        ${cfg.user} = {
          isSystemUser = true;
          home = if cfg.stateDirectory != null then cfg.stateDirectory else "/var/empty";
          createHome = cfg.stateDirectory != null;
          inherit (cfg) group;
        };
      };

      groups = lib.mkIf (cfg.group == "haqqd") { ${cfg.group} = { }; };
    };

    environment.systemPackages = [
      (pkgs.writeScriptBin "haqqctl" ''
        exec systemd-run \
          --quiet \
          --pipe \
          --pty \
          --wait \
          --collect \
          --service-type=exec \
          --property=User=${cfg.user} \
          -- \
          ${lib.getExe cfg.packages.config} "$@"
      '')
    ];

    systemd.services.haqqd = {
      path = [ cfg.packages.config ];

      preStart = ''
        set -euxo pipefail

        mkdir -p "$DAEMON_HOME"

        ${cfg.extraPreStartup}

        if [ ! -f "$DAEMON_HOME/.bootstrapped" ]; then
          haqqd init ${
            # editorconfig-checker-disable
            # TODO(azahi): File a nixfmt bug report about soft line width not respected for
            # conditionals.
            if lib.hasAttr "moniker" cfg.settings.config then cfg.settings.config.moniker else "haqqd"
          } --chain-id "${
            if lib.hasAttr "chain-id" cfg.settings.client then cfg.settings.client.chain-id else "haqq_11235-1"
            # editorconfig-checker-enable
          }"
        fi

        ${
          if cfg.enableMutableSettings then
            ''
              cp -vf ${cfg.finalSettings.app} "$DAEMON_HOME/config/app.toml"
              cp -vf ${cfg.finalSettings.config} "$DAEMON_HOME/config/config.toml"
              cp -vf ${cfg.finalSettings.client} "$DAEMON_HOME/config/client.toml"
            ''
          else
            ''
              ln -vfs ${cfg.finalSettings.app} "$DAEMON_HOME/config/app.toml"
              ln -vfs ${cfg.finalSettings.config} "$DAEMON_HOME/config/config.toml"
              ln -vfs ${cfg.finalSettings.client} "$DAEMON_HOME/config/client.toml"
            ''
        }

        mkdir -p "$DAEMON_HOME/cosmovisor/genesis/bin"
        ln -sf "${cfg.packages.genesis}/bin/haqqd" "$DAEMON_HOME/cosmovisor/genesis/bin/haqqd"
        ${lib.concatMapStrings (
          package:
          let
            base = "$DAEMON_HOME/cosmovisor/upgrades/v${package.version}/bin";
          in
          ''
            mkdir -p "${base}"
            ln -sf "${package}/bin/haqqd" "${base}/haqqd"
          ''
        ) cfg.packages.upgrades}

        ${cfg.extraPostStartup}

        touch "$DAEMON_HOME/.bootstrapped"
      '';

      script = ''
        exec ${lib.getExe pkgs.cosmovisor} run start
      '';

      environment = rec {
        HOME = if cfg.stateDirectory != null then cfg.stateDirectory else "/var/lib/haqqd";
        DAEMON_NAME = "haqqd";
        DAEMON_HOME = "${HOME}/.haqqd";
        DAEMON_ALLOW_DOWNLOAD_BINARIES = "false";
        DAEMON_RESTART_AFTER_UPGRADE = "true";
        COSMOVISOR_COLOR_LOGS = "false";
        UNSAFE_SKIP_BACKUP = "true";
      };

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;

        DynamicUser = cfg.stateDirectory == null;
        StateDirectory = if cfg.stateDirectory != null then cfg.stateDirectory else "haqqd";

        Restart = "always";
        RestartSec = 5;

        AmbientCapabilities = [ "" ];
        CapabilityBoundingSet = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # This is required for the application to work.
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "full";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };
  };
}
