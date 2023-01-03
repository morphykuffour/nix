{
  config,
  pkgs,
  agenix,
  ...
}: {
  age.identityPaths = [
    "/home/morp/.ssh/id_ed25519"
  ];
  age.secrets.borgbackup-xps17-nixos.file = ../../secrets/borgbackup-xps17-nixos.age;

  services.borgbackup.jobs."borgbase" = {
    paths = [
      "/home/morp/Dropbox/"
    ];
    exclude = [
      # "/var/lib/docker"
      # "**/target"
      # "/home/*/go/bin"
    ];
    # repo = "o6h6zl22@o6h6zl22.repo.borgbase.com:repo";
    repo = "ssh://a1gm1p14@a1gm1p14.repo.borgbase.com/./repo";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.age.secrets.borgbackup-xps17-nixos.path}";
    };
    environment.BORG_RSH = "ssh -i /home/morp/.ssh/id_ed25519";
    compression = "auto,zstd";
    startAt = "daily";
  };
}
