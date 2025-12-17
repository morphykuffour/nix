{
  config,
  lib,
  pkgs,
  ...
}: {
  # https://github.com/NixOS/nixpkgs/issues/59603#issuecomment-1356844284
  systemd.services.NetworkManager-wait-online.enable = false;

  # Use the official NixOS keyd module
  # This automatically handles socket permissions and group setup
  services.keyd = {
    enable = false;
    keyboards = {
      default = {
        ids = ["*"];  # Match all keyboards
        settings = {
          main = {
            # Paste with insert
            insert = "S-insert";

            # Maps capslock to escape when pressed and control when held
            capslock = "overload(ctrl_vim, esc)";

            # Remaps the escape key to capslock
            esc = "capslock";
          };

          # ctrl_vim modifier layer; inherits from 'Ctrl' modifier layer
          "ctrl_vim:C" = {
            space = "swap(vim_mode)";
          };

          # vim_mode modifier layer; also inherits from 'Ctrl' modifier layer
          "vim_mode:C" = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
            # forward word
            w = "C-right";
            # backward word
            b = "C-left";
          };
        };
      };
    };
  };
}
