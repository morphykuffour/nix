# https://git.2li.ch/Nebucatnetzer/nixos/src/commit/e5fa7e159f7aa5ba0bef13ce233834e4da0059a5/home-manager/software/grobi/default.nix
# https://michael.stapelberg.ch/posts/2025-05-10-grobi-x11-monitor-autoconfig/
{pkgs, ...}: {
  services.grobi = {
    enable = true;

    rules = [
      # Internal panel only
      {
        name = "laptop-internal-only";
        outputs_connected = ["eDP-1"];
        configure_single = "eDP-1@2560x1600";
        primary = true;
        atomic = true;
        execute_after = [];
      }

      # Laptop + single external monitor on the left
      {
        name = "laptop-with-monitor2-left";
        outputs_connected = ["eDP-1" "DP-1"];
        configure_row = ["DP-1" "eDP-1@2560x1600"];
        primary = "eDP-1";
        atomic = true;
        execute_after = [];
      }

      # Fallback: if nothing else matched, at least bring up the internal panel.
      {
        name = "fallback";
        configure_single = "eDP-1@2560x1600";
      }
    ];
  };
}
