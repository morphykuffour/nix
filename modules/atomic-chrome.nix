{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.services.atomic-chrome;
  isDarwin = options ? launchd;
  
  # Script to start atomic-chrome server
  startScript = pkgs.writeScript "start-atomic-chrome" ''
    #!${pkgs.bash}/bin/bash
    
    # Wait for Emacs to be ready
    for i in {1..30}; do
      if ${cfg.emacsPackage}/bin/emacsclient --eval "(progn t)" >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done
    
    # Start atomic-chrome server
    ${cfg.emacsPackage}/bin/emacsclient --eval '(progn
      (require (quote atomic-chrome) nil t)
      (setq atomic-chrome-default-major-mode (quote markdown-mode))
      (setq atomic-chrome-buffer-open-style (quote frame))
      (setq atomic-chrome-url-major-mode-alist
            (quote (("github\\.com" . gfm-mode)
                    ("reddit\\.com" . markdown-mode)
                    ("gitlab\\.com" . gfm-mode))))
      (atomic-chrome-start-server)
      (message "Atomic Chrome server started on port 64292"))' || exit 1
  '';
in
{
  options.services.atomic-chrome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the atomic-chrome server for browser integration";
    };

    emacsPackage = mkOption {
      type = types.package;
      default = pkgs.emacs;
      description = "The Emacs package to use";
    };

    startDelay = mkOption {
      type = types.int;
      default = 5;
      description = "Seconds to wait after login before starting the server";
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    launchd.user.agents.atomic-chrome = {
      path = [ cfg.emacsPackage pkgs.coreutils ];
      serviceConfig = {
        ProgramArguments = [ "${startScript}" ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardErrorPath = "/tmp/atomic-chrome.err";
        StandardOutPath = "/tmp/atomic-chrome.out";
        Label = "org.nixos.atomic-chrome";
        StartInterval = 300; # Retry every 5 minutes if it fails
      };
    };
  };
}