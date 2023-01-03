# https://xeiaso.net/blog/borg-backup-2021-01-09
{
  config,
  pkgs,
  agenix,
  ...
}: {
  services.borgbackup.jobs."borgbase" = {
    paths = ["/home/morp/Dropbox/"];
    repo = "a1gm1p14@a1gm1p14.repo.borgbase.com:repo";
    encryption.mode = "none";
    environment.BORG_RSH = "ssh -i /home/morp/.ssh/id_ed25519";
    compression = "auto,zstd";
    startAt = "daily";
  };
}
