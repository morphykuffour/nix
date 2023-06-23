{
  config,
  pkgs,
  agenix,
  ...
}: {
  # use agenix for passwordFile
  age.identityPaths = [
    "/root/.ssh/id_ed25519"
  ];
  age.secrets.b2-backup-xps17-nixos.file = ../../secrets/b2-backup-xps17-nixos.age;

  environment.systemPackages = [pkgs.restic];

  services.restic.backups = {
    local-system_drive_backup-xps17-nixos = {
      exclude = [
        "/home/*/.cache"
      ];
      initialize = true;
      passwordFile = config.age.secrets.b2-backup-xps17-nixos.path;
      paths = [
        "/home"
      ];
      repository = "/run/media/morph/T7";
    };

    # cloud-system_drive_backup-xps17-nixos = {
    #   exclude = [
    #     "/home/*/.cache"
    #   ];
    #   initialize = true;
    #   passwordFile = config.age.secrets.b2-backup-xps17-nixos.path;
    #   paths = [
    #     "/home"
    #   ];
    #   repository = "b2:xps17-nixos-backup";
    #   timerConfig = {
    #     OnUnitActiveSec = "1d";
    #   };

    #   # keep 7 daily, 5 weekly, and 10 annual backups
    #   pruneOpts = [
    #     "--keep-daily 7"
    #     "--keep-weekly 5"
    #     "--keep-yearly 10"
    #   ];
    # };

    # Sync = {
    #   initialize = true;
    #   passwordFile = config.age.secrets.b2-backup-xps17-nixos.path;
    #   paths = [
    #     "/home/morph/Org"
    #     "/home/morph/Dropbox"
    #     "/home/morph/iCloud"
    #   ];
    #   repository = "b2:xps17-nixos-backup";
    #   timerConfig = {
    #     OnUnitActiveSec = "1d";
    #   };

    #   # keep 7 daily, 5 weekly, and 10 annual backups
    #   pruneOpts = [
    #     "--keep-daily 7"
    #     "--keep-weekly 5"
    #     "--keep-yearly 10"
    #   ];
    # };
  };

  # systemd.services.restic-backups-morph = {
  #   environment = {
  #     B2_ACCOUNT_ID = "my_account_id_abc123";
  #     B2_ACCOUNT_KEY = "my_account_key_def456";
  #   };
  # };
}
