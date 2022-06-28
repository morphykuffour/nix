{ config, pkgs, lib, ... }:


let
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

  # install neovim
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
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
    extraConfig = builtins.concatStringsSep "\n" [

      (lib.strings.fileContents ./nvim/vimfiles/beautify.vim)
      (lib.strings.fileContents ./nvim/vimfiles/binary.vim)
      (lib.strings.fileContents ./nvim/vimfiles/build.vim)
      (lib.strings.fileContents ./nvim/vimfiles/cscope_maps.vim)
      (lib.strings.fileContents ./nvim/vimfiles/cyclist.vim)
      (lib.strings.fileContents ./nvim/vimfiles/functions.vim)
      (lib.strings.fileContents ./nvim/vimfiles/mappings.vim)
      (lib.strings.fileContents ./nvim/vimfiles/netrw.vim)
      (lib.strings.fileContents ./nvim/vimfiles/newbiecructches.vim)
      (lib.strings.fileContents ./nvim/vimfiles/scratch.vim)
      (lib.strings.fileContents ./nvim/vimfiles/startup.vim)
      (lib.strings.fileContents ./nvim/vimfiles/wilder.vim)
      # (lib.strings.fileContents ./nvim/vimfiles/wslyank.vim)

      # this allows you to add lua config files
      # ${lib.strings.fileContents ./nvim/lua/morpheus/options.lua}
      ''
        lua << EOF
        ${lib.strings.fileContents ./nvim/init.lua}
        EOF
      ''
    ];

    # install needed binaries here
    extraPackages = with pkgs; [
      tree-sitter
      # LSPs
      rnix-lsp
      nodePackages.typescript
      sumneko-lua-language-server
      nodePackages.typescript-language-server
      gopls
      nodePackages.pyright
      black
      rust-analyzer
    ];

    plugins = with pkgs.vimPlugins; [
      # TODO move all of lsp into one file
      # TODO move all of config to one file
      (plugin "nvim-lua/popup.nvim")
      (plugin "nvim-lua/plenary.nvim")
      (plugin "christoomey/vim-tmux-navigator")
      (plugin "AndrewRadev/bufferize.vim")
      (plugin "francoiscabrol/ranger.vim")
      (plugin "rbgrouleff/bclose.vim")
      (plugin "szw/vim-maximizer")
      (plugin "windwp/nvim-autopairs")
      (plugin "gelguy/wilder.nvim")
      (plugin "mzlogin/vim-markdown-toc")
      (plugin "SidOfc/mkdx")
      (plugin "vim-pandoc/vim-rmarkdown")
      (plugin "vim-pandoc/vim-pandoc")
      (plugin "vim-pandoc/vim-pandoc-syntax")
      (plugin "nvim-orgmode/orgmode")
      (plugin "lukas-reineke/headlines.nvim")
      (plugin "kyazdani42/nvim-web-devicons")
      (plugin "moll/vim-bbye")
      (plugin "antoinemadec/FixCursorHold.nvim")
      (plugin "kevinhwang91/nvim-bqf")
      (plugin "mhinz/vim-startify")
      (plugin "voldikss/vim-floaterm")
      (plugin "junegunn/goyo.vim")
      (plugin "projekt0n/github-nvim-theme")
      (plugin "folke/tokyonight.nvim")
      (plugin "tpope/vim-sensible")
      (plugin "tpope/vim-fugitive")
      (plugin "tpope/vim-surround")
      (plugin "tpope/vim-repeat")
      (plugin "tpope/vim-eunuch")
      (plugin "tpope/vim-unimpaired")
      (plugin "tpope/vim-dadbod")
      (plugin "tpope/vim-commentary")
      (plugin "TimUntersberger/neogit")
      (plugin "sindrets/diffview.nvim")
      (plugin "lewis6991/gitsigns.nvim")
      (plugin "ellisonleao/gruvbox.nvim")
      (plugin "lunarvim/darkplus.nvim")
      (plugin "marko-cerovac/material.nvim")
      (plugin "hrsh7th/cmp-path")
      (plugin "hrsh7th/cmp-cmdline")
      (plugin "hrsh7th/cmp-nvim-lua")
      (plugin "saadparwaiz1/cmp_luasnip")
      (plugin "tjdevries/complextras.nvim")
      (plugin "neovim/nvim-lspconfig")
      (plugin "hrsh7th/cmp-nvim-lsp")
      (plugin "hrsh7th/cmp-buffer")
      (plugin "hrsh7th/nvim-cmp")
      (plugin "onsails/lspkind.nvim")
      (plugin "nvim-lua/lsp_extensions.nvim")
      (plugin "simrat39/symbols-outline.nvim")
      (plugin "jose-elias-alvarez/null-ls.nvim")
      (plugin "L3MON4D3/LuaSnip")
      (plugin "rafamadriz/friendly-snippets")
      (plugin "nvim-telescope/telescope.nvim")
      (plugin "nvim-telescope/telescope-fzy-native.nvim")
      (plugin "nvim-telescope/telescope-cheat.nvim")
      (plugin "nvim-telescope/telescope-file-browser.nvim")
      (plugin "dhruvmanila/telescope-bookmarks.nvim")
      (plugin "tyru/open-browser.vim")
      (plugin "milisims/nvim-luaref")
      (plugin "numToStr/Comment.nvim")
      (plugin "nvim-treesitter/nvim-treesitter")
      (plugin "p00f/nvim-ts-rainbow")
      (plugin "ii14/nrepl.nvim")
      (plugin "nathom/filetype.nvim")
      (plugin "mfussenegger/nvim-dap")
      (plugin "rcarriga/nvim-dap-ui")
      (plugin "theHamsta/nvim-dap-virtual-text")
      (plugin "mfussenegger/nvim-dap-python")
      (plugin "wesleimp/stylua.nvim")
      (plugin "nvim-telescope/telescope-file-browser.nvim")
    ];
  };
}
