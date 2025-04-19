# https://git.2li.ch/Nebucatnetzer/nixos/src/commit/e5fa7e159f7aa5ba0bef13ce233834e4da0059a5/home-manager/software/grobi/default.nix
{pkgs, ...}: {
  services.grobi = {
    enable = true;
    rules = [
      {
        name = "docked";
        outputs_connected = ["DP-2-3"];
        atomic = true;
        configure_row = ["DP-2-3"];
        primary = "DP-1-1";
        execute_after = [];
      }
      {
        name = "undocked";
        outputs_disconnected = ["DP-2-3"];
        configure_single = "eDP-1";
        primary = true;
        atomic = true;
        execute_after = [];
      }
      {
        name = "fallback";
        configure_single = "eDP-1";
      }
    ];
  };
}
