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
      sha256 = "12r1k5hw8plz1hnr7h827l9hjxr9j2pi75whcsvl6k4772wf6s0l";
    }))
  ];

  xdg.configFile = makeFtPlugins
    {
      # TODO move all filetype settings to autocmd_filetype
      xml = ''
        setl formatprg=prettier\ --stdin-filepath\ %";
      '';
      sh = ''
        setl makeprg=shellcheck\ -f\ gcc\ %
        nnoremap <buffer> <localleader>m :silent make<cr>
      '';
      rust = ''
        setl formatprg=rustfmt
        setl makeprg=cargo\ check
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      purescript = ''
        setl formatprg=purty\ format\ -
        nnoremap <buffer> <localleader>t :!spago docs --format ctags
      '';
      json = ''
        setl formatprg=prettier\ --stdin-filepath\ %
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      yaml = ''
        setl formatprg=prettier\ --stdin-filepath\ %
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      fzf = ''
        setl laststatus=0 noshowmode noruler
        aug fzf | au! BufLeave <buffer> set laststatus& showmode ruler | aug END
      '';
      qf = ''
        nnoremap <buffer> <left> :colder<cr>
        nnoremap <buffer> <right> :cnewer<cr>
      '';
      clojure = ''
        packadd conjure
        packadd parinfer
        setl errorformat=%f:%l:%c:\ Parse\ %t%*[^:]:\ %m,%f:%l:%c:\ %t%*[^:]:\ %m
        setl makeprg=clj-kondo\ --lint\ %
        setl wildignore+=*.clj-kondo*
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      javascript = ''
        setl formatprg=prettier\ --stdin-filepath\ %
        setl wildignore+=*node_modules*,package-lock.json,yarn-lock.json
        setl errorformat=%f:\ line\ %l\\,\ col\ %c\\,\ %m,%-G%.%#
        setl makeprg=${pkgs.nodePackages.eslint}/bin/eslint\ --format\ compact
        nnoremap <buffer> <silent> <localleader>f :!${pkgs.nodePackages.eslint}/bin/eslint --fix %<cr>
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      typescript = ''
        setl formatexpr=
        setl formatprg=prettier\ --parser\ typescript\ --stdin-filepath\ %
        setl wildignore+=*node_modules*,package-lock.json,yarn-lock.json
        setl errorformat=%f:\ line\ %l\\,\ col\ %c\\,\ %m,%-G%.%#
        setl makeprg=${pkgs.nodePackages.eslint}/bin/eslint\ --format\ compact
        nnoremap <buffer> <silent> <localleader>f :!${pkgs.nodePackages.eslint}/bin/eslint --fix %<cr>
        nnoremap <buffer> <silent> <localleader>F :%!prettier --parser typescript --stdin-filepath %<cr>
        nnoremap <buffer> <silent> <localleader>d :!prettier --version<cr>
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      css = ''
        setl formatprg=prettier\ --parser\ css\ --stdin-filepath\ %
      '';
      scss = ''
        setl formatprg=prettier\ --parser\ scss\ --stdin-filepath\ %
      '';
      nix = ''
        setl formatprg=nixpkgs-fmt
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      dhall = ''
        setl formatprg=dhall\ format
      '';
      make = ''
        setl noexpandtab
      '';
      lua = ''
        setl makeprg=luacheck\ --formatter\ plain
        nnoremap <buffer> <localleader>m :make %<cr>
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
        set formatprg=stylua\ -
      '';
      python = ''
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      sql = ''
        setl formatprg=${pkgs.pgformatter}/bin/pg_format
      '';
      go = ''
        setl formatprg=gofmt makeprg=go\ build\ -o\ /dev/null
        nnoremap <buffer> <localleader>m :make %<cr>
        function! GoImports()
            let saved = winsaveview()
            %!goimports
            call winrestview(saved)
        endfunction
        nnoremap <buffer> <localleader>i :call GoImports()<cr>
        nnoremap <buffer> <localleader>t :execute ':silent !for f in ./{cmd, internal, pkg}; if test -d $f; ctags -R $f; end; end'<CR>
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
      '';
      haskell = ''
        setl formatprg=ormolu
        nnoremap <buffer> <localleader>t :silent !fast-tags -R .<cr>
      '';
      markdown = ''
        setl formatprg=prettier\ --stdin-filepath\ %
      '';
    };
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

      # Todo for loop
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
      # (lib.strings.fileContents ./vimfiles/wslyank.vim)

      # this allows you to add lua config files
      # ${lib.strings.fileContents ./lua/morpheus/options.lua}
      ''
        lua << EOF
        ${lib.strings.fileContents ./nvim/init.nix.lua}
        ${lib.strings.fileContents ./nvim/lua/morpheus/hydra.lua}
        EOF
      ''
    ];

    # install needed binaries here
    extraPackages = with pkgs; [

      tree-sitter

      # LSP servers
      rnix-lsp
      nodePackages.typescript
      sumneko-lua-language-server
      nodePackages.typescript-language-server
      gopls
      nodePackages.pyright
      nodePackages.prettier
      black
      rust-analyzer
    ];

    plugins = with pkgs.vimPlugins; [
      # syntax highlight with tree-sitter
      (nvim-treesitter.withPlugins (p: pkgs.tree-sitter.allGrammars))

      # LSP
      { plugin = nvim-lspconfig; optional = true; }
      vim-nix

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
      # (plugin "neovim/nvim-lspconfig")
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
      (plugin "tzachar/cmp-tabnine")
      (plugin "junegunn/fzf")
      (plugin "junegunn/fzf.vim")
      (plugin "ojroques/nvim-lspfuzzy")
      (plugin "onsails/diaglist.nvim")
      (plugin "nvim-lualine/lualine.nvim")
      # (plugin "norcalli/nvim-colorizer.lua")
      (plugin "norcalli/nvim_utils")
      (plugin "nvim-treesitter/nvim-treesitter-refactor")
      (plugin "nvim-treesitter/nvim-treesitter-textobjects")
      (plugin "anuvyklack/hydra.nvim#foreign-keys")
      (plugin "phaazon/hop.nvim")
      (plugin "bfredl/nvim-miniyank")
      # (plugin "nvim-treesitter/nvim-treesitter-playground")
      (plugin "anuvyklack/keymap-layer.nvim")
    ];
  };
}
