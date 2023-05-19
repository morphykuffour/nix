{
  config,
  lib,
  pkgs,
  ...
}: let
  keyd = pkgs.callPackage ../../pkgs/keyd {};
  keydConfig = builtins.readFile ../../pkgs/keyd/keymaps.conf;
in {
  systemd.services = {
    # https://github.com/NixOS/nixpkgs/issues/59603#issuecomment-1356844284
    NetworkManager-wait-online.enable = false;

    keyd = {
      enable = true;
      description = "keyd key remapping daemon";
      unitConfig = {
        Requires = "local-fs.target";
        After = "local-fs.target";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.keyd}/bin/keyd";
      };
    };
  };

  environment.etc."keyd/default.conf".text = keydConfig;
}
