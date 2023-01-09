{
  config,
  pkgs,
  agenix,
  ...
}: 
{

  # use agenix for passCommand
  age.identityPaths = [
    "/home/morp/.ssh/id_ed25519_borgbase"
  ];
  age.secrets.borgbackup-xps17-nixos.file = ../../secrets/borgbackup-xps17-nixos.age;
    services.borgbackup.jobs = {
    dropbox-backup = {
        paths = [ "/" ];
        exclude = [ "'**/.cache'" ];
        repo = "a1gm1p14@a1gm1p14.repo.borgbase.com:repo";
          encryption = {
          mode = "repokey-blake2";
          passCommand = "cat ${config.age.secrets.borgbackup-xps17-nixos.path}";
        };
        environment = { BORG_RSH = "ssh -i ~/.ssh/id_ed25519_borgbase "; };
        compression = "auto,zstd";
        startAt = "daily";
    };
  };
}
  # services.borgbackup.jobs.dropbox-backup = {
  #   paths = "/home/morp/Dropbox/";
  #   environment.BORG_RSH = "ssh -i /home/morp/.ssh/id_ed25519";
  #   encryption.mode = "none";
  #   repo = "a1gm1p14@a1gm1p14.repo.borgbase.com:repo";
  #   # repo = "ssh://a1gm1p14@a1gm1p14.repo.borgbase.com/./repo";
  #   compression = "auto,zstd";
  #   startAt = "daily";
  # };
# }

# {
#   services.borgbackup.enable = true;
#   services.borgbackup.backupUser = "morpkuff@protonmail.com";
#   services.borgbackup.backupHost = "borgbase.com";
#   services.borgbackup.repository = "a1gm1p14@a1gm1p14.repo.borgbase.com:repo";
#   services.borgbackup.backupPoints = [
#     {
#       # source = "/path/to/your/important/files";
#       source = "/home/morp/Dropbox/";
#       # exclusions = [
#       #   "/path/to/your/important/files/tmp"
#       # ];
#     }
#   ];
#   services.borgbackup.jobs = [
#     {
#       name = "daily";
#       schedule = "0 0 * * *";
#       retentionPolicy = "7D";
#     }
#   ];
# }
