# https://git.2li.ch/Nebucatnetzer/nixos/src/commit/e5fa7e159f7aa5ba0bef13ce233834e4da0059a5/home-manager/software/grobi/default.nix
# https://michael.stapelberg.ch/posts/2025-05-10-grobi-x11-monitor-autoconfig/
{ pkgs, ... }: {
  services.grobi = {
    enable = true;

    # Grobi rules for xps17-nixos
    #
    # Setup 1: Docked with macmini-darwin / desktop-bqtgj9g / xps17-nixos
    #          (no external monitors in use on Linux) → only eDP-1 enabled.
    # Setup 2: One external monitor ("Monitor 2") to the *left* of the laptop.
    # Setup 3: Laptop on its own (no external displays) → only eDP-1 enabled.
    #
    # NOTE: These rules assume the internal panel is called "eDP-1" and the
    # external monitor you plug into the dock is "DP-1". If your connector
    # names differ, run e.g. `swaymsg -t get_outputs` or `xrandr` and replace
    # the strings below accordingly.

    rules = [
      # Internal panel only (covers both Setup 1 and Setup 3 as far as outputs
      # are concerned – Deskflow handles the multi‑machine aspect).
      {
        name = "laptop-internal-only";
        outputs_connected = [ "eDP-1" ];
        configure_single = "eDP-1";
        primary = true;
        atomic = true;
        execute_after = [ ];
      }

      # Laptop + single external monitor on the left (Setup 2).
      {
        name = "laptop-with-monitor2-left";
        outputs_connected = [ "eDP-1" "DP-1" ];
        configure_row = [ "DP-1" "eDP-1" ];
        primary = "eDP-1";
        atomic = true;
        execute_after = [ ];
      }

      # Fallback: if nothing else matched, at least bring up the internal panel.
      {
        name = "fallback";
        configure_single = "eDP-1";
      }
    ];
  };
}
