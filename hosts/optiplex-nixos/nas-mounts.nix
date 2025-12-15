{ config, pkgs, ... }:

{
  # Install CIFS utilities for SMB/CIFS mounting
  environment.systemPackages = [ pkgs.cifs-utils ];

  # Define agenix secret for TrueNAS SMB credentials
  age.secrets.truenas-smb = {
    file = ../../secrets/truenas-smb.age;
    mode = "600";
    owner = "root";
    group = "root";
  };

  # Optional: Create a dedicated 'nas' group for shared NAS access
  # Uncomment these lines if you want a dedicated group:
  # users.groups.nas = {};
  # users.users.morph.extraGroups = [ "nas" ];

  # Configure SMB/CIFS mounts for TrueNAS SCALE
  # Movies share
  fileSystems."/mnt/nas/movies" = {
    device = "//192.168.1.73/movies";
    fsType = "cifs";
    options = [
      # Systemd automount options for reliable boot
      "x-systemd.automount"           # Use automount for on-demand mounting
      "nofail"                         # Don't fail boot if mount fails
      "x-systemd.idle-timeout=60"     # Unmount after 60 seconds of inactivity
      "x-systemd.device-timeout=10s"  # Timeout for device availability
      "_netdev"                        # Network filesystem (wait for network)

      # Authentication
      "credentials=${config.age.secrets.truenas-smb.path}"

      # Ownership and permissions (files owned by morph)
      "uid=${toString config.users.users.morph.uid}"
      "gid=${toString config.users.users.morph.gid}"
      "file_mode=0664"
      "dir_mode=0775"

      # SMB protocol version (3.0 is widely compatible)
      "vers=3.0"

      # Additional stability options
      "seal"                           # Enable SMB3 encryption
      "resilient"                      # Enable resilient handles for better reconnection
    ];
  };

  # TV Shows share
  fileSystems."/mnt/nas/tv_shows" = {
    device = "//192.168.1.73/tv_shows";
    fsType = "cifs";
    options = [
      # Systemd automount options for reliable boot
      "x-systemd.automount"           # Use automount for on-demand mounting
      "nofail"                         # Don't fail boot if mount fails
      "x-systemd.idle-timeout=60"     # Unmount after 60 seconds of inactivity
      "x-systemd.device-timeout=10s"  # Timeout for device availability
      "_netdev"                        # Network filesystem (wait for network)

      # Authentication
      "credentials=${config.age.secrets.truenas-smb.path}"

      # Ownership and permissions (files owned by morph)
      "uid=${toString config.users.users.morph.uid}"
      "gid=${toString config.users.users.morph.gid}"
      "file_mode=0664"
      "dir_mode=0775"

      # SMB protocol version (3.0 is widely compatible)
      "vers=3.0"

      # Additional stability options
      "seal"                           # Enable SMB3 encryption
      "resilient"                      # Enable resilient handles for better reconnection
    ];
  };

  # Ensure mount points exist
  systemd.tmpfiles.rules = [
    "d /mnt/nas 0755 root root - -"
    "d /mnt/nas/movies 0755 root root - -"
    "d /mnt/nas/tv_shows 0755 root root - -"
  ];
}
