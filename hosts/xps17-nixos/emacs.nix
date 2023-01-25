{
  config,
  pkgs,
  ...
}: {
  services.emacs = {
    package = pkgs.emacsNativeComp;
    install = true;
    enable = true;
  };
}
