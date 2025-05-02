# source:https://github.com/DMaroo/fakwin/issues/3
{
  config,
  lib,
  pkgs,
  ...
}:
# Example: https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/i3-sway/i3.nix
let
  fakwin = pkgs.stdenv.mkDerivation rec {
    pname = "fakwin";
    version = "1.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "DMaroo";
      repo = "fakwin";
      rev = "master";
      hash = "sha256-oEMSuy2NMbd3Q7wtGSVz9vrqNWFeZLrNDM3KAsLgUOw=";
    };

    nativeBuildInputs = [pkgs.cmake pkgs.qt6.wrapQtAppsHook];

    buildInputs = [pkgs.qt6.qtbase];

    installPhase = ''
      mkdir -p $out/bin
      cp fakwin $out/bin/
    '';

    meta = with pkgs.lib; {
      description = "A fake KWin dbus interface for Plasma6 running without KWin";
      license = licenses.mit;
      maintainers = with maintainers; ["DMaroo"];
      platforms = platforms.linux;
    };
  };
in {
  environment.systemPackages = [fakwin];

  systemd.services.fakwin = {
    description = "Plasma Fake KWin dbus interface";
    wantedBy = [ "graphical-session.target" ];
    after = [ "plasma-workspace.service" ];
    requires = [ "dbus.socket" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${fakwin}/bin/fakwin";
      Restart = "always";
      RestartSec = "1";
      Environment = "DISPLAY=:0";
    };
  };
}
