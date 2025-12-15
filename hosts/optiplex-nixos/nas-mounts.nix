{ config, pkgs, lib, ... }:

let
  # Get morph's UID and GID
  morphUid = toString config.users.users.morph.uid;
  morphGid = toString config.users.groups.users.gid;

  # Common mount options for both shares (without x-systemd options)
  cifsOptions = lib.concatStringsSep "," [
    "credentials=${config.age.secrets.truenas-smb.path}"
    "uid=${morphUid}"
    "gid=${morphGid}"
    "file_mode=0664"
    "dir_mode=0775"
    "vers=3.0"
    "seal"
    "_netdev"
  ];
in
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

  # Ensure mount points exist
  systemd.tmpfiles.rules = [
    "d /mnt/nas 0755 root root - -"
    "d /mnt/nas/movies 0755 root root - -"
    "d /mnt/nas/tv_shows 0755 root root - -"
  ];

  # Define systemd mount units explicitly
  systemd.mounts = [
    {
      description = "TrueNAS Movies Share";
      what = "//192.168.1.73/movies";
      where = "/mnt/nas/movies";
      type = "cifs";
      options = cifsOptions;
      wantedBy = [ ];  # Don't auto-start, let automount trigger it
    }
    {
      description = "TrueNAS TV Shows Share";
      what = "//192.168.1.73/tv_shows";
      where = "/mnt/nas/tv_shows";
      type = "cifs";
      options = cifsOptions;
      wantedBy = [ ];  # Don't auto-start, let automount trigger it
    }
  ];

  # Define systemd automount units
  systemd.automounts = [
    {
      description = "Automount TrueNAS Movies Share";
      where = "/mnt/nas/movies";
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "60";
      };
    }
    {
      description = "Automount TrueNAS TV Shows Share";
      where = "/mnt/nas/tv_shows";
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "60";
      };
    }
  ];
}
