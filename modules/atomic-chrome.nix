{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.services.atomic-chrome;
  isDarwin = options ? launchd;
  
  # Script to start atomic-chrome server once
  startScript = pkgs.writeScript "start-atomic-chrome" ''
    #!${pkgs.bash}/bin/bash
    
    echo "$(date): Starting atomic-chrome server setup"
    
    # Wait for Emacs to be ready (max 30 seconds)
    for i in {1..30}; do
      if ${cfg.emacsPackage}/bin/emacsclient --eval "(progn t)" >/dev/null 2>&1; then
        echo "$(date): Emacs is ready"
        break
      fi
      sleep 1
    done
    
    # Start the server and monitoring
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
        
        ;; Periodic polling to ensure server is running
        (defvar my/atomic-chrome-polling-timer nil
          "Timer for periodic atomic-chrome server checks.")
        
        (defun my/atomic-chrome-check-and-restart ()
          "Check if atomic-chrome server is running and restart if needed."
          (unless (and (boundp 'atomic-chrome-server)
                       atomic-chrome-server
                       (process-live-p atomic-chrome-server))
            (message "Atomic-chrome server not running, restarting...")
            (my/atomic-chrome-server-ensure)))
        
        ;; Cancel any existing timer
        (when (and (boundp 'my/atomic-chrome-polling-timer)
                   my/atomic-chrome-polling-timer)
          (cancel-timer my/atomic-chrome-polling-timer))
        
        ;; Start periodic polling (every 60 seconds by default)
        (setq my/atomic-chrome-polling-timer
              (run-with-timer 30 ${toString cfg.pollingInterval} 
                              'my/atomic-chrome-check-and-restart))
        
        ;; Also check server health when Emacs gains focus
        (add-hook 'focus-in-hook 'my/atomic-chrome-check-and-restart)
        
        ;; Function to test server connectivity
        (defun my/atomic-chrome-test-server ()
          "Test if atomic-chrome server is responsive."
          (condition-case err
              (let ((test-process 
                     (make-network-process
                      :name "atomic-chrome-test"
                      :host "localhost"
                      :service 64292
                      :nowait t)))
                (when test-process
                  (delete-process test-process)
                  t))
            (error 
             (message "Atomic-chrome server test failed: %s" err)
             (my/atomic-chrome-server-ensure)
             nil)))
        
        ;; Final status message
        (message "Atomic Chrome server started/restarted on port 64292")
        
        ;; Load enhanced monitoring if available
        (when (file-exists-p "~/.emacs.d/atomic-chrome-monitor.el")
          (load-file "~/.emacs.d/atomic-chrome-monitor.el")
          (message "Loaded atomic-chrome enhanced monitoring"))
        
        ;; Return success
        t)' 2>&1
    
    if [ $? -eq 0 ]; then
      echo "$(date): Atomic-chrome server initialized successfully"
      # Keep the process alive for launchd (exit will trigger restart)
      exec sleep infinity
    else
      echo "$(date): Failed to initialize atomic-chrome server"
      exit 1
    fi
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

    pollingInterval = mkOption {
      type = types.int;
      default = 120;
      description = "Seconds between Emacs internal server health checks";
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    launchd.user.agents.atomic-chrome = {
      path = [ cfg.emacsPackage pkgs.coreutils ];
      serviceConfig = {
        ProgramArguments = [ "${startScript}" ];
        RunAtLoad = true;
        # Simple setup: just run once at startup
        # Emacs internal monitoring will handle keeping the server alive
        KeepAlive = false;
        StandardErrorPath = "/tmp/atomic-chrome.err";
        StandardOutPath = "/tmp/atomic-chrome.out";
        Label = "org.nixos.atomic-chrome";
      };
    };
  };
}