{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      # Terminal
      pfetch
    ];
    stateVersion = "22.05";
  };

  # programs = { };
}
