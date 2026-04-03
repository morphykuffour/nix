{
  config,
  lib,
  pkgs,
  ...
} @ args: let
  cfg = config.services.kanata-remapper;
  isDarwin = builtins.hasAttr "launchd" (args.options or {});
  kanataConfigFile = pkgs.writeText "kanata.kbd" cfg.config;
in {
  options.services.kanata-remapper = {
    enable = lib.mkEnableOption "Kanata key remapping daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kanata;
      defaultText = lib.literalExpression "pkgs.kanata";
      description = "The kanata package to use.";
    };

    config = lib.mkOption {
      type = lib.types.lines;
      default = builtins.readFile ./kanata.kbd;
      description = ''
        Kanata keyboard configuration in .kbd format.
        Defaults to the shared kanata.kbd (migrated from keyd).
      '';
    };

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Linux only: list of /dev/input device paths.
        Empty list means all devices.
      '';
    };

    extraDefCfg = lib.mkOption {
      type = lib.types.str;
      default = "process-unmapped-keys yes";
      description = "Extra defcfg options passed to kanata.";
    };
  };

  config = lib.mkIf cfg.enable (
    if isDarwin
    then {
      # ── macOS (nix-darwin) ─────────────────────────────────────────
      environment.systemPackages = [cfg.package];

      # Copy kanata binary to a stable path so macOS TCC (Input Monitoring)
      # permissions persist across nix rebuilds that change /nix/store paths.
      system.activationScripts.postActivation.text = ''
        mkdir -p /usr/local/bin
        cp -f ${cfg.package}/bin/kanata /usr/local/bin/kanata
        chmod 755 /usr/local/bin/kanata
      '';

      launchd.daemons.kanata = {
        serviceConfig = {
          Label = "org.kanata.daemon";
          ProgramArguments = [
            "/usr/local/bin/kanata"
            "--cfg"
            "${kanataConfigFile}"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/kanata.log";
          StandardErrorPath = "/tmp/kanata.err.log";
        };
      };
    }
    else {
      # ── Linux (NixOS) ──────────────────────────────────────────────
      boot.kernelModules = ["uinput"];
      hardware.uinput.enable = true;

      services.udev.extraRules = ''
        KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
      '';

      users.groups.uinput = {};

      systemd.services.kanata-internalKeyboard.serviceConfig = {
        SupplementaryGroups = ["input" "uinput"];
      };

      services.kanata = {
        enable = true;
        keyboards.internalKeyboard = {
          devices = cfg.devices;
          extraDefCfg = cfg.extraDefCfg;
          config = cfg.config;
        };
      };
    }
  );
}
