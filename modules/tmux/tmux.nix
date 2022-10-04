{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.open
      tmuxPlugins.yank
      tmuxPlugins.resurrect
    ];
    shortcut = "t";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    # terminal = "screen-256color";
    extraConfig = lib.strings.fileContents ./.tmux.conf;
  };
}
