# source:https://github.com/DMaroo/fakwin/issues/3
{
  config,
  lib,
  pkgs,
  fakwin, # Flake input - source is managed by flake.lock
  ...
}:
# Example: https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/i3-sway/i3.nix
let
  fakwinPkg = pkgs.stdenv.mkDerivation rec {
    pname = "fakwin";
    version = "1.0.0";

    # Use flake input - hash is managed in flake.lock
    # Update with: nix flake lock --update-input fakwin
    src = fakwin;

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
  home.packages = [fakwinPkg];

  systemd.user.services.fakwin = {
    Unit = {
      Description = "Plasma Fake KWin dbus interface";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session-pre.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${fakwinPkg}/bin/fakwin";
      Restart = "always";
      RestartSec = "1";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  # Optional: add this to your i3 config to ensure fakwin starts with i3
  # Note: fakwin is also started via systemd user service above
  xsession.windowManager.i3.config.startup = [
    {
      command = "${fakwinPkg}/bin/fakwin";
      always = true;
      notification = false;
    }
  ];
}
