# https://discourse.nixos.org/t/restic-backups-on-b2-with-nixos-agenix/36196
{
  config,
  pkgs,
  agenix,
  user,
  ...
}: {
  # use agenix for passCommand
  age.identityPaths = [
    "/root/.ssh/id_ed25519_borgbase"
  ];
  age.secrets.borgbackup-xps17-nixos.file = ../../secrets/borgbackup-xps17-nixos.age;
  services.borgbackup.jobs = {
    dropbox_backup = {
      user = "root";
      paths = ["/home/${user}/iCloud/"];
      exclude = ["'**/.cache'"];
      repo = "r0el6zc7@r0el6zc7.repo.borgbase.com:repo";
      encryption.mode = "none";
      # encryption = {
      #   mode = "repokey-blake2";
      #   # passphrase = "cat ${config.age.secrets.borgbackup-xps17-nixos.path}";
      #   passCommand = "cat ${config.age.secrets.borgbackup-xps17-nixos.path}";
      #   # passCommand = "cat ../../../secrets/passphrase";
      # };
      environment = {BORG_RSH = "ssh -i /root/.ssh/id_ed25519_borgbase ";};
      compression = "auto,zstd";
      startAt = "daily";
    };
  };
}
