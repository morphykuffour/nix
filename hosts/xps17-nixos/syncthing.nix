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
      "optiplex-nixos" = {id = "ZXN6ICB-6DIAJ3E-LSOBFNF-VBAPZOA-DYHC2CE-TE4KYD5-CGHRJWL-GCFP3AJ";};
      "desktop-bqtgj9g" = {id = "TWWE3ND-3VVVCVF-BRLFCJN-FY52C2R-6CKQFBX-NLABCDI-H2BNSSU-4P6OOAP";};
    };

    settings.folders = {
      "Org" = {
        path = "/home/morph/Org/";
        id = "Org";
        devices = ["desktop-bqtgj9g" "optiplex-nixos" "macmini-darwin"];
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "15768000";
          };
        };
      };

      # "Sync" = {
      #   path = "/home/morph/Sync/";
      #   id = "Sync";
      #   devices = ["desktop-bqtgj9g" "optiplex-nixos" "macmini-darwin"];
      #   versioning = {
      #     type = "staggered";
      #     params = {
      #       cleanInterval = "3600";
      #       maxAge = "15768000";
      #     };
      #   };
      # };
    };
  };
}
