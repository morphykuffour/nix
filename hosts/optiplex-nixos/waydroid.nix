{
  config,
  pkgs,
  ...
}: {
  # Waydroid requires specific kernel modules
  boot.kernelModules = ["binder_linux"];
  boot.extraModprobeConfig = ''
    options binder_linux devices="binder,hwbinder,vndbinder"
  '';

  # Enable Waydroid virtualisation service
  virtualisation.waydroid.enable = true;

  # Add user to required groups for hardware access
  users.users.morph.extraGroups = ["video" "render"];

  # Enable hardware graphics acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit Android apps
  };

  # Bluetooth for printer connectivity (JADENS thermal printer)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # System packages for waydroid management
  environment.systemPackages = with pkgs; [
    waydroid
    # wl-clipboard for clipboard support in waydroid
    wl-clipboard
  ];
}
