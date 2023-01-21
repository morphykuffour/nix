{
  config,
  pkgs,
  ...
}: {
  services.emacs = {
    package = pkgs.emacs;
    install = true;
    enable = true;
  };
}
