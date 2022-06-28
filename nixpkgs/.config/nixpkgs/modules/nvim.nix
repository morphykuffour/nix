# morpheus.plugins

{ config, pkgs, lib, ... }: {
  # Add my config
  xdg.configFile.nvim = {
    source = ./nvim;
    recursive = true;
  };

  home.activation.nvim = lib.hm.dag.entryAfter ["writeBoundry"] ''
    $DRY_RUN_CMD nvim --headless -c 'autocmd User PackerComplete quitall' -c 'lua require "plugin-config"' -c "PackerSync" -u NONE
  '';
}
