{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.emacs-daemon;
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

  config = mkIf cfg.enable (mkMerge [
    (mkIf pkgs.stdenv.isDarwin {
      launchd.user.agents.emacs-daemon = {
        path = [ cfg.package ];
        serviceConfig = {
          ProgramArguments = [ "${cfg.package}/bin/emacs" "--daemon" ];
          RunAtLoad = !cfg.socketActivation;
          KeepAlive = !cfg.socketActivation;
          StandardErrorPath = "/tmp/emacs-daemon.err";
          StandardOutPath = "/tmp/emacs-daemon.out";
          Label = "org.nixos.emacs-daemon";
        };
      };
    })

    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.emacs = {
        description = "Emacs text editor";
        documentation = [ "info:emacs" "man:emacs(1)" "https://gnu.org/software/emacs/" ];
        
        serviceConfig = {
          Type = "forking";
          ExecStart = "${cfg.package}/bin/emacs --daemon";
          ExecStop = "${cfg.package}/bin/emacsclient --eval '(kill-emacs)'";
          Restart = "on-failure";
        };
        
        wantedBy = mkIf (!cfg.socketActivation) [ "default.target" ];
      };

      systemd.user.sockets.emacs = mkIf cfg.socketActivation {
        description = "Emacs text editor";
        documentation = [ "info:emacs" "man:emacs(1)" "https://gnu.org/software/emacs/" ];
        
        socketConfig = {
          ListenStream = "%t/emacs";
          FileDescriptorName = "server";
          SocketMode = "0600";
        };
        
        wantedBy = [ "sockets.target" ];
      };
    })
  ]);
}