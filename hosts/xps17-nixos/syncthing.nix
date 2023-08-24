{
  config,
  pkgs,
  user,
  ...
}: {
  services. syncthing = {
    enable = true;
    dataDir = "/home/morph";
    openDefaultPorts = true;
    configDir = "/home/morph/.config/syncthing";
    user = "morph";
    group = "users";
    guiAddress = "127.0.0.1:8384";
    overrideDevices = true;
    overrideFolders = true;
    devices = {
      "xps17-nixos" = {id = "7AB6YRE-AYP7FOX-7PWJLDV-TRMJ6B6-S5OGOD3-GQ5HFPT-DCPMHYS-IBQKJQK";};
      "ubuntu" = {id = "TTEQED5-YB5HDQQ-4OYRRUE-PQMO7XF-TWCNSQ7-4SFRM5X-N6C3IBY-ELN2XQV";};
      "macmini-darwin" = {id = "OK4365M-ZZC4CDT-A6W2YF2-MPIX3GR-FYZIWWJ-5QS6RYM-5KYU35K-SLYBHQO";};
      # "workstation-windows" = {id = "OT562TI-J4NCYP6-7SCXJL6-PWDVBGX-EJA5G7S-3Q4G4TG-UR7RN3F-V3OVAAH";};
    };

    folders = {
      "Dropbox" = {
        path = "/home/morph/Dropbox";
        id = "Dropbox";
        devices = ["xps17-nixos" "ubuntu" "macmini-darwin"];
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "15768000";
          };
        };
      };

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
