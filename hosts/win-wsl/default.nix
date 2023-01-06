{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./configuration.nix
    # ../../modules/emacs
  ];
}
