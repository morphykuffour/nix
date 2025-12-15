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

  # TrueNAS server address - use Tailscale hostname if available, otherwise IP
  # truenasHost = "truenas-scale";  # Change to "192.168.1.73" if Tailscale not available

  # TODO: Remove this once Tailscale is working properly on truenas-scale
  truenasHost = "192.168.1.73";  

  # Ensure mount points exist
  systemd.tmpfiles.rules = [
    "d /mnt/nas 0755 root root - -"
    "d /mnt/nas/media 0755 root root - -"
    "d /mnt/nas/downloads 0755 root root - -"
  ];

  # Define systemd mount units explicitly
  systemd.mounts = [
    {
      description = "TrueNAS Media Share";
      what = "//${truenasHost}/media";
      where = "/mnt/nas/media";
      type = "cifs";
      options = cifsOptions;
      wantedBy = [ ];  # Don't auto-start, let automount trigger it
    }
    {
      description = "TrueNAS Downloads Share";
      what = "//${truenasHost}/downloads";
      where = "/mnt/nas/downloads";
      type = "cifs";
      options = cifsOptions;
      wantedBy = [ ];  # Don't auto-start, let automount trigger it
    }
  ];

  # Define systemd automount units
  systemd.automounts = [
    {
      description = "Automount TrueNAS Media Share";
      where = "/mnt/nas/media";
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "60";
      };
    }
    {
      description = "Automount TrueNAS Downloads Share";
      where = "/mnt/nas/downloads";
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "60";
      };
    }
  ];
}
