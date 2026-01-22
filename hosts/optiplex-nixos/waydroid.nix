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

  # System packages for waydroid management
  environment.systemPackages = with pkgs; [
    waydroid
    # wl-clipboard for clipboard support in waydroid
    wl-clipboard
  ];
}
