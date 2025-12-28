{
  config,
  lib,
  pkgs,
  rawtalk,
  ...
}:
with lib; let
  cfg = config.services.rawtalk;
in {
  options.services.rawtalk = {
    enable = mkEnableOption "Rawtalk QMK Layer Switcher service";

    package = mkOption {
      type = types.package;
      default = rawtalk.packages.aarch64-darwin.default;
      description = "The rawtalk package to use";
    };
  };

  config = mkIf cfg.enable {
    # Create launchd agent to run rawtalk as a background service
    launchd.user.agents.rawtalk = {
      serviceConfig = {
        Label = "com.rawtalk.service";
        ProgramArguments = ["${cfg.package}/bin/rawtalk"];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
          Crashed = true;
        };
        StandardOutPath = "/tmp/rawtalk.log";
        StandardErrorPath = "/tmp/rawtalk.error.log";
        EnvironmentVariables = {
          PATH = "${pkgs.coreutils}/bin:/usr/bin:/bin";
          HOME = "/Users/morph";
        };
      };
    };
  };
}
