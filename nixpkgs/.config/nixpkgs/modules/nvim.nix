{ config, pkgs, lib, ... }:

with lib;
with types;
let
  makeFtPlugins = ftplugins: with attrsets;
    mapAttrs'
      (key: value: nameValuePair "nvim/after/ftplugin/${key}.vim" ({ text = value; }))
      ftplugins;
  # installs a vim plugin from git with a given tag / branch
  pluginGit = ref: repo: pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "${lib.strings.sanitizeDerivationName repo}";
    version = ref;
    src = builtins.fetchGit {
      url = "https://github.com/${repo}.git";
      ref = ref;
    };


  };

  # always installs latest version
  plugin = pluginGit "HEAD";
in
{

  #imports = [  ./tree-sitter.nix ];
  # install neovim
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
      sha256 = "11fhy9vz9nbdcpn6xkf06w3vixvzcbhmsrfllaw03l2q78cip1pn";
    }))
  ];

  # TODO move to neovim.nix
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    # read in the vim config from filesystem
    # extraConfig = builtins.concatStringsSep "\n" [
    #
    #   # Todo for loop
    #   (lib.strings.fileContents ./nvim/vimfiles/beautify.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/binary.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/build.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/cscope_maps.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/cyclist.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/functions.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/mappings.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/netrw.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/newbiecructches.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/scratch.vim)
    #   (lib.strings.fileContents ./nvim/vimfiles/startup.vim)
    #   # (lib.strings.fileContents ./nvim/vimfiles/wilder.vim)
    #   # (lib.strings.fileContents ./vimfiles/wslyank.vim)
    #
    #   # this allows you to add lua config files
    #   # ${lib.strings.fileContents ./lua/morpheus/options.lua}
    #   # ${lib.strings.fileContents ./nvim/init.lua}
    #
    #   ''
    #     lua << EOF
    #     ${lib.strings.fileContents ./nvim/init.nix.lua}
    #     ${lib.strings.fileContents ./nvim/lua/morpheus/hydra.lua}
    #     ${lib.strings.fileContents ./nvim/lua/morpheus/plugins.lua}
    #     EOF
    #   ''
    # ];

    # install needed binaries here
    extraPackages = with pkgs; [
      tree-sitter
      # LSP servers
      rnix-lsp
      nodePackages.typescript
      sumneko-lua-language-server
      nodePackages.typescript-language-server
      nodePackages.bash-language-server
      gopls
      nodePackages.pyright
      nodePackages.prettier
      black
      rust-analyzer
    ];

    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: pkgs.tree-sitter.allGrammars))
      # LSP
      # { plugin = nvim-lspconfig; optional = true; }
      vim-nix
    ];
  };
}
