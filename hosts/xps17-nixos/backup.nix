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
      # very large paths
      # "/var/lib/docker"
      # "/var/lib/systemd"
      # "/var/lib/libvirt"

      # temporary files created by cargo and `go build`
      # "**/target"
      # "/home/*/go/bin"
      # "/home/*/go/pkg"
    ];
    repo = "o6h6zl22@o6h6zl22.repo.borgbase.com:repo";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.age.secrets.borgbackup-xps17-nixos.path}";
      # "cat /root/borgbackup/passphrase";
    };
    environment.BORG_RSH = "ssh -i /root/borgbackup/ssh_key";
    compression = "auto,lzma";
    startAt = "daily";
  };
}
