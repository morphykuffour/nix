{
  pkgs,
  config,
  home,
  ...
}: {
  home.packages = with pkgs; [
    pkgs.nerd-fonts.jetbrains-mono
  ];
}
