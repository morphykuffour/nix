{
  config,
  pkgs,
  agenix,
  ...
}: {
  # use agenix for passCommand
  age.identityPaths = [
    "/home/morp/.ssh/id_ed25519_borgbase"
  ];
  age.secrets.borgbackup-xps17-nixos.file = ../../secrets/borgbackup-xps17-nixos.age;
  services.borgbackup.jobs = {
    dropbox_backup = {
      paths = ["/home/morp/Dropbox/"];
      exclude = ["'**/.cache'"];
      repo = "r0el6zc7@r0el6zc7.repo.borgbase.com:repo";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.age.secrets.borgbackup-xps17-nixos.path}";
      };
      environment = {BORG_RSH = "ssh -i ~/.ssh/id_ed25519_borgbase ";};
      compression = "auto,zstd";
      startAt = "daily";
    };
  };
}
