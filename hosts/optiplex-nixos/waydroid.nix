# Waydroid configuration for running Android apps (JADENS thermal printer)
# Requires Wayland - this module enables Wayland for GDM/GNOME
{
  config,
  pkgs,
  lib,
  ...
}: {
  # ============================================
  # WAYLAND - Required for Waydroid
  # ============================================
  # Override rustdesk-client.nix X11 setting
  services.displayManager.gdm.wayland = lib.mkForce true;

  # ============================================
  # WAYDROID - Android container
  # ============================================
  virtualisation.waydroid.enable = true;

  # ============================================
  # BLUETOOTH - for JADENS thermal printer
  # ============================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true; # Better device compatibility
        # Allow pairing without input capability (useful for printers)
        Class = "0x000100"; # Computer class
        DiscoverableTimeout = 0; # Always discoverable when enabled
        PairableTimeout = 0; # Always pairable when enabled
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Blueman GUI for Bluetooth management
  services.blueman.enable = true;

  # ============================================
  # USER GROUPS
  # ============================================
  users.users.morph.extraGroups = lib.mkAfter [
    "video" # Graphics access
    "render" # GPU rendering
    "bluetooth" # Bluetooth access for Waydroid
    "lp" # Printer access
  ];

  # ============================================
  # GRAPHICS - Intel HD 530 optimization
  # ============================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit support for Android apps
  };

  # Use modern Intel iris driver
  environment.variables = {
    MESA_LOADER_DRIVER_OVERRIDE = "iris";
  };

  # ============================================
  # PACKAGES
  # ============================================
  environment.systemPackages = with pkgs; [
    # Waydroid tools
    waydroid

    # Bluetooth tools
    bluez
    bluez-tools

    # Wayland clipboard (for copy/paste with Android)
    wl-clipboard

    # Android debugging (optional)
    android-tools # adb
  ];

  # ============================================
  # SYSTEMD - Waydroid container service
  # ============================================
  # Waydroid needs to start after graphical session
  # The virtualisation.waydroid.enable handles this, but we add bluetooth dependency
  systemd.services.waydroid-container = {
    after = ["bluetooth.service"];
    wants = ["bluetooth.service"];
  };
}
