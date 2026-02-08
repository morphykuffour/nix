{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.services.atomic-chrome;
  isDarwin = options ? launchd;
  
  # Script to start and monitor atomic-chrome server
  startScript = pkgs.writeScript "start-atomic-chrome" ''
    #!${pkgs.bash}/bin/bash
    
    # Function to check if server is running
    check_server() {
      ${pkgs.lsof}/bin/lsof -i :64292 >/dev/null 2>&1
    }
    
    # Function to start the server
    start_server() {
      ${cfg.emacsPackage}/bin/emacsclient --eval '(progn
        ;; Load atomic-chrome if not already loaded
        (require (quote atomic-chrome) nil t)
        
        ;; Configure atomic-chrome
        (setq atomic-chrome-default-major-mode (quote markdown-mode))
        (setq atomic-chrome-buffer-open-style (quote frame))
        (setq atomic-chrome-url-major-mode-alist
              (quote (("github\\.com" . gfm-mode)
                      ("reddit\\.com" . markdown-mode)
                      ("gitlab\\.com" . gfm-mode)
                      ("stackoverflow\\.com" . markdown-mode)
                      ("leetcode\\.com" . prog-mode))))
        
        ;; Enable buffer persistence with transparency
        (setq atomic-chrome-buffer-frame-alist
              (quote ((width . 80) 
                      (height . 25)
                      (alpha . (${toString cfg.frameTransparency.active} . ${toString cfg.frameTransparency.inactive}))  ;; Active . Inactive transparency
                      (background-color . "black")
                      (foreground-color . "white"))))
        
        ;; Custom function to handle reconnections
        (defun my/atomic-chrome-server-ensure ()
          "Ensure atomic-chrome server is running, restart if needed."
          (condition-case err
              (atomic-chrome-start-server)
            (error 
             (atomic-chrome-stop-server)
             (sleep-for 1)
             (atomic-chrome-start-server)
             (message "Restarted atomic-chrome server after error: %s" err))))
        
        ;; Custom function to set frame transparency
        (defun my/atomic-chrome-set-frame-alpha (frame)
          "Set transparency for atomic-chrome frames."
          (when frame
            (set-frame-parameter frame 'alpha '(${toString cfg.frameTransparency.active} . ${toString cfg.frameTransparency.inactive}))
            ;; Optional: Set dark background for better transparency effect
            (with-selected-frame frame
              (set-background-color "#1a1a1a")
              (set-foreground-color "#e0e0e0"))))
        
        ;; Hook to apply transparency to new atomic-chrome frames
        (add-hook 'atomic-chrome-edit-mode-hook
                  (lambda ()
                    (when (and (boundp 'atomic-chrome-buffer-frame)
                               atomic-chrome-buffer-frame
                               (frame-live-p atomic-chrome-buffer-frame))
                      (my/atomic-chrome-set-frame-alpha atomic-chrome-buffer-frame))))
        
        ;; Start or restart the server
        (my/atomic-chrome-server-ensure)
        
        ;; Set up auto-restart on server errors
        (defadvice atomic-chrome-server-sentinel (after restart-on-error activate)
          "Restart server if it stops unexpectedly."
          (when (and (not (process-live-p atomic-chrome-server))
                     (not atomic-chrome-server-stop-flag))
            (run-with-timer 2 nil (quote my/atomic-chrome-server-ensure))))
        
        (message "Atomic Chrome server started/restarted on port 64292"))' 2>&1
    }
    
    # Wait for Emacs to be ready
    echo "Waiting for Emacs..."
    for i in {1..30}; do
      if ${cfg.emacsPackage}/bin/emacsclient --eval "(progn t)" >/dev/null 2>&1; then
        echo "Emacs is ready"
        break
      fi
      sleep 1
    done
    
    # Main monitoring loop
    while true; do
      if ! check_server; then
        echo "$(date): Server not running, starting..."
        start_server
        sleep 2
      fi
      sleep ${toString cfg.checkInterval}
    done
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

    checkInterval = mkOption {
      type = types.int;
      default = 30;
      description = "Seconds between server health checks";
    };

    enableSessionPersistence = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to persist atomic-chrome buffer sessions";
    };

    frameTransparency = mkOption {
      type = types.submodule {
        options = {
          active = mkOption {
            type = types.int;
            default = 85;
            description = "Transparency level when frame is active (0-100, 100 = opaque)";
          };
          inactive = mkOption {
            type = types.int;
            default = 75;
            description = "Transparency level when frame is inactive (0-100, 100 = opaque)";
          };
        };
      };
      default = {};
      description = "Transparency settings for atomic-chrome frames";
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    launchd.user.agents.atomic-chrome = {
      path = [ cfg.emacsPackage pkgs.coreutils pkgs.lsof ];
      serviceConfig = {
        ProgramArguments = [ "${startScript}" ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;  # Keep running even after successful exit
          Crashed = true;          # Restart if crashed
        };
        StandardErrorPath = "/tmp/atomic-chrome.err";
        StandardOutPath = "/tmp/atomic-chrome.out";
        Label = "org.nixos.atomic-chrome";
        # Remove StartInterval as we're using KeepAlive instead
        ThrottleInterval = 10;     # Wait 10 seconds before restart on crash
      };
    };
  };
}