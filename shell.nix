{
  pkgs,
  system,
}: {
  ${system} = {
    python = pkgs.mkShell {
      buildInputs = with pkgs; [
        mypy
        black
        python3
      ];

      shellHook = "${pkgs.zsh}/bin/zsh; exit";
    };

    cuda = pkgs.mkShell {
      buildInputs = with pkgs; [
        cudatoolkit
        linuxPackages.nvidia_x11
      ];

      shellHook = "export CUDA_PATH=${pkgs.cudatoolkit}; ${pkgs.zsh}/bin/zsh; exit";
    };
  };
}
