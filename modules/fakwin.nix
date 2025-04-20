# source: https://github.com/DMaroo/fakwin/issues/3
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
  home.packages = [fakwin];

  systemd.user.services."fakwin" = {
    Unit = {
      Description = "Plasma Fake KWin dbus interface";
      After = ["multi-user.target"];
    };
    Install = {
      WantedBy = ["default.target"];
    };
    Service = {
      ExecStart = "${fakwin}/bin/fakwin";
      Slice = "session.slice";
      Restart = "on-failure";
    };
  };

  home.activation = {
    ensureFakwinActive = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.systemd}/bin/systemctl --user enable fakwin.service
    '';
  };
}
