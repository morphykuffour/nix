let
  # Your SSH public key (converted to age format by agenix automatically)
  xps17-nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIISjAu3KwCZ7iEHmfHmY+EtUJhOXixax9iarMZpYYaqc morph@xps17-nixos";
  macmini-darwin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVpvLJJJ9smtoSoKr44/1w+ycmMlSVGL+vdP7TTiIjp my-mac";
  optiplex-nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICfHWXdhc5lgq/TWe8LfsVi7SsDTKjqD/GSSZtR5lPbx morph@nixos";

  # Define all users who should have access to secrets
  allUsers = [xps17-nixos macmini-darwin optiplex-nixos];
in {
  # OpenAI API key for nvim
  "secrets/openai.age".publicKeys = allUsers;

  # TrueNAS SMB credentials for optiplex-nixos
  "secrets/truenas-smb.age".publicKeys = allUsers;

  # Existing secrets (add them here for completeness)
  "secrets/ts-xps17-nixos.age".publicKeys = allUsers;
  "secrets/ts-t480-nixos.age".publicKeys = allUsers;
  "secrets/ts-optiplex-nixos.age".publicKeys = allUsers;
  "secrets/ts-win-wsl.age".publicKeys = allUsers;
  "secrets/ts-rpi3b-nixos.age".publicKeys = allUsers;
  "secrets/mullvadvpn-xps17-nixos.age".publicKeys = allUsers;
  "secrets/wireguard-xps17-nixos.age".publicKeys = allUsers;
  "secrets/borgbackup-xps17-nixos.age".publicKeys = allUsers;
  "secrets/b2-backup-xps17-nixos.age".publicKeys = allUsers;
  "secrets/sync-xps17-nixos.age".publicKeys = allUsers;
  "secrets/xps17-nixos-vpn.age".publicKeys = allUsers;
  "secrets/xps17-nixos-vpn-pub.age".publicKeys = allUsers;
  "secrets/qbittorrent-optiplex-nixos.age".publicKeys = allUsers;
  "secrets/silverbullet-optiplex-nixos.age".publicKeys = allUsers;
  "secrets/restic/env.age".publicKeys = allUsers;
  "secrets/restic/password.age".publicKeys = allUsers;
  "secrets/restic/repo.age".publicKeys = allUsers;

  # VNC password for GNOME Remote Desktop on optiplex-nixos
  "secrets/vnc-optiplex-nixos.age".publicKeys = allUsers;

  # RustDesk password for optiplex-nixos
  "secrets/rustdesk-optiplex-nixos.age".publicKeys = allUsers;
}
