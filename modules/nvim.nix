{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with types; let
  genBlockLua = title: content: ''
    -- ${title} {{{
    ${content}
    -- }}}
  '';

  luaPlugin = attrs:
    attrs
    // {
      type = "lua";
      config = lib.optionalString (attrs ? config) (genBlockLua attrs.plugin.pname attrs.config);
    };

  makeFtPlugins = ftplugins:
    with attrsets;
      mapAttrs'
      (key: value: nameValuePair "nvim/after/ftplugin/${key}.vim" {text = value;})
      ftplugins;

  # installs a vim plugin from git with a given tag / branch
  pluginGit = ref: repo:
    pkgs.vimUtils.buildVimPluginFrom2Nix {
      pname = "${lib.strings.sanitizeDerivationName repo}";
      version = ref;
      src = builtins.fetchGit {
        url = "https://github.com/${repo}.git";
        ref = ref;
      };
    };

  # always installs latest version
  plugin = pluginGit "HEAD";
in {
  # install neovim
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
      sha256 = "0wlirmfb119n9ka8r4qmd9yv7jfibgld85za3vh8n4xjbp3bjiq9";
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
      ''
        lua << EOF
        ${lib.strings.fileContents ./nvim/init.nix.lua}
        ${lib.strings.fileContents ./nvim/lua/morpheus/hydra.lua}
        ${lib.strings.fileContents ./nvim/lua/morpheus/plugins.lua}
        EOF
      ''
    ];

    extraPackages = with pkgs; [
      tree-sitter
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
      (luaPlugin {
        plugin = packer-nvim;
        # config = ''
        #   local packer_group = vim.api.nvim_create_augroup("Packer", { clear = true })
        #   vim.api.nvim_create_autocmd("BufWritePost", {
        #     command = "source <afile> | PackerCompile",
        #     group = packer_group,
        #     pattern = vim.fn.expand("$HOME") .. "/nix/nixpkgs/.config/nixpkgs/modules/nvim/init.nix.lua",
        #   })
        # '';
      })
      (nvim-treesitter.withPlugins (p: pkgs.tree-sitter.allGrammars))
      vim-nix
    ];
  };
}
