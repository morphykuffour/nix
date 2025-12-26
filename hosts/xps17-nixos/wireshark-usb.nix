# Wireshark USB capture configuration for Beagle Protocol Analyzer
# Based on: https://morphykuffour.github.io/linux/wireshark/2025/02/19/Wireshark-USB-Capture-Setup.html
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Load usbmon kernel module at boot for USB packet capture
  boot.kernelModules = ["usbmon"];

  # Enable Wireshark with proper permissions
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # GUI version
  };

  # udev rules for USB capture
  services.udev.extraRules = ''
    # usbmon devices - allow wireshark group to capture USB traffic
    SUBSYSTEM=="usbmon", MODE="0660", GROUP="wireshark"

    # Total Phase Beagle USB Protocol Analyzers
    # Vendor ID: 1679 (Total Phase)
    SUBSYSTEM=="usb", ATTR{idVendor}=="1679", MODE="0666", GROUP="wireshark"

    # Beagle USB 12 (Product ID: 2001)
    SUBSYSTEM=="usb", ATTR{idVendor}=="1679", ATTR{idProduct}=="2001", MODE="0666", GROUP="wireshark", SYMLINK+="beagle_usb12"

    # Beagle USB 480 (Product ID: 2002)
    SUBSYSTEM=="usb", ATTR{idVendor}=="1679", ATTR{idProduct}=="2002", MODE="0666", GROUP="wireshark", SYMLINK+="beagle_usb480"

    # Beagle USB 5000 v2 (Product ID: 2003)
    SUBSYSTEM=="usb", ATTR{idVendor}=="1679", ATTR{idProduct}=="2003", MODE="0666", GROUP="wireshark", SYMLINK+="beagle_usb5000"
  '';
}
