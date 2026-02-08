{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.services.emacs-daemon;
  # Check if we're on Darwin by looking for Darwin-specific options
  isDarwin = options ? launchd;
in
{
  options.services.emacs-daemon = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the Emacs daemon service";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.emacs;
      description = "The Emacs package to use for the daemon";
    };

    socketActivation = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to use socket activation (start on demand)";
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    launchd.user.agents.emacs-daemon = {
      path = [ cfg.package ];
      serviceConfig = {
        ProgramArguments = [ "${cfg.package}/bin/emacs" "--daemon" ];
        RunAtLoad = false;  # Don't auto-start to avoid conflicts
        KeepAlive = false;  # Don't restart on failure
        StandardErrorPath = "/tmp/emacs-daemon.err";
        StandardOutPath = "/tmp/emacs-daemon.out";
        Label = "org.nixos.emacs-daemon";
      };
    };
  };
}