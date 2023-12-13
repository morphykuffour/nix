# https://www.arthurkoziel.com/restic-backups-b6-nixos/
{
  config,
  pkgs,
  agenix,
  ...
}: {

  # use agenix for passwordFile
  age.identityPaths = [
    "/home/morph/.ssh/id_ed25519"
  ];

  age.secrets = {
    "restic/env".file = ../../secrets/restic/env.age;
    "restic/repo".file = ../../secrets/restic/repo.age;
    "restic/password".file = ../../secrets/restic/password.age;
  };

  # install restic package 
  environment.systemPackages = [pkgs.restic];

  services.restic.backups = {
    daily = {
      initialize = true;

      environmentFile = config.age.secrets."restic/env".path;
      repositoryFile = config.age.secrets."restic/repo".path;
      passwordFile = config.age.secrets."restic/password".path;

      paths = [
        "/home/morph/iCloud"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
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
