{
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = ["nvidia"]; # Unfree.

  hardware.nvidia.prime = {
    sync.enable = true;

    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}
# lspci -vk
# 00:02.0 VGA compatible controller: Intel Corporation CometLake-H GT2 [UHD Graphics] (rev 05) (prog-if 00 [VGA controller])
# 01:00.0 VGA compatible controller: NVIDIA Corporation TU106M [GeForce RTX 2060 Max-Q] (rev a1) (prog-if 00 [VGA controller])

