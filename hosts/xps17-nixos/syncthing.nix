{
  config,
  pkgs,
  user,
  ...
}: {
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    dataDir = "/home/morph/.local/share/syncthing";
    configDir = "/home/morph/.config/syncthing";
    user = "morph";
    group = "users";
    guiAddress = "127.0.0.1:8384";
    overrideDevices = true;
    overrideFolders = true;
    settings.devices = {
      "macmini-darwin" = {id = "OK4365M-ZZC4CDT-A6W2YF2-MPIX3GR-FYZIWWJ-5QS6RYM-5KYU35K-SLYBHQO";};
    };

    settings.folders = {
      "Org" = {
        path = "/home/morph/Org/";
        id = "Org";
        devices = ["xps17-nixos" "ubuntu" "macmini-darwin"];
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "15768000";
          };
        };
      };

      "iCloud" = {
        path = "/home/morph/iCloud/";
        id = "iCloud";
        devices = ["xps17-nixos" "ubuntu" "macmini-darwin"];
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "15768000";
          };
        };
      };
    };
  };
}
