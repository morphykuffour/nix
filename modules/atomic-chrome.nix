{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.services.atomic-chrome;
  isDarwin = options ? launchd;
in
{
  options.services.atomic-chrome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to start Emacs at login for atomic-chrome browser integration.";
    };

    emacsPackage = mkOption {
      type = types.package;
      default = pkgs.emacs;
      description = ''
        The Emacs package to launch. This should be an emacsWithPackages
        derivation that includes atomic-chrome and websocket packages.
        The atomic-chrome server configuration lives in init.el.
      '';
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    launchd.user.agents.atomic-chrome = {
      serviceConfig = {
        # Launch the Nix-wrapped Emacs binary directly.
        # The wrapper sets EMACSLOADPATH so all Nix-managed packages
        # (including atomic-chrome and websocket) are available.
        # init.el handles starting the WebSocket server on port 64292.
        ProgramArguments = [
          "${cfg.emacsPackage}/bin/emacs"
          "--no-splash"
        ];
        RunAtLoad = true;
        # Restart Emacs if it crashes (but not on clean exit)
        KeepAlive = {
          SuccessfulExit = false;
        };
        ProcessType = "Interactive";
        StandardErrorPath = "/tmp/emacs-launchd.err";
        StandardOutPath = "/tmp/emacs-launchd.out";
      };
    };
  };
}
