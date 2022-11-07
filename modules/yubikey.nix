{
  config,
  pkgs,
  ...
}: {
  services.udev.packages = with pkgs; [libu2f-host yubikey-personalization];
  services.pcscd.enable = true;
  environment.shellInit = ''
    export GPG_TTY="$(tty)"
  '';
  services.yubikey-agent.enable = config.cadey.gui.enable;
}
