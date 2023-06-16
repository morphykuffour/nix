{pkgs, ...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "Monocraft:size=9";
        dpi-aware = "no";
        pad = "8x2";
      };
      colors = {
        alpha = 0.95;
      };
    };
  };
}
