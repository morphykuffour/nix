# https://github.com/vimjoyer/lf-nix-video
{
  pkgs,
  config,
  ...
}: let
  fzf_search = builtins.readFile ./fzf_search;
in {
  # Download the icons file
  # nix run nixpkgs#wget -- "https://raw.githubusercontent.com/gokcehan/lf/master/etc/icons.example" -O icons
  xdg.configFile."lf/icons".source = ./icons;

  programs.lf = {
    enable = true;
    commands = {
      dragon-out = ''dragon -a -x "$fx"'';
      editor-open = ''$$EDITOR $f'';
      mkdir = ''
        ''${{
          printf "Directory Name: "
          read DIR
          mkdir $DIR
        }}
      '';
      fzf_jump = ''
        ''${{
            res="$(find . -maxdepth 1 | fzf --reverse --header='Jump to location')"
            if [ -n "$res" ]; then
                if [ -d "$res" ]; then
                    cmd="cd"
                else
                    cmd="select"
                fi
                res="$(printf '%s' "$res" | sed 's/\\/\\\\/g;s/"/\\"/g')"
                lf -remote "send $id $cmd \"$res\""
            fi
        }}
      '';

      fzf_search = ''${fzf_search}'';

      replace-space-in-dirs = ''
        ''${{
            REPLACE_SCRIPT="$HOME/.local/bin/replace_spaces"
            if [ ! -f "$REPLACE_SCRIPT" ]; then
                echo "Error: $REPLACE_SCRIPT not found" >&2
                exit 1
            fi
            [ -x "$REPLACE_SCRIPT" ] || chmod +x "$REPLACE_SCRIPT" 2>/dev/null
            if [ ! -x "$REPLACE_SCRIPT" ]; then
                echo "Error: $REPLACE_SCRIPT is not executable" >&2
                exit 1
            fi
            if [ -z "$fx" ]; then
                echo "No files selected" >&2
                exit 1
            fi
            printf '%s\n' "$fx" | while IFS= read -r d; do
                [ -n "$d" ] || continue
                if [ -d "$d" ]; then
                    echo "Processing: $d"
                    (cd "$d" && "$REPLACE_SCRIPT") || echo "Failed to process: $d" >&2
                else
                    echo "Skipping (not a directory): $d" >&2
                fi
            done
            lf -remote "send $id reload"
        }}
      '';

      open-file = ''
        ''${{
            case $(uname) in
                Linux)
                    if [[ "$fx" == *.pdf ]]; then
                        zathura "$fx" >/dev/null 2>&1 &
                    else
                        xdg-open "$fx" >/dev/null 2>&1 &
                    fi
                    ;;
                Darwin)
                    if [[ "$fx" == *.pdf ]]; then
                        open -a Zathura "$fx" >/dev/null 2>&1 &
                    else
                        open "$fx" >/dev/null 2>&1 &
                    fi
                    ;;
                CYGWIN*|MINGW*|MSYS*) explorer "$(cygpath -w "$fx")" ;;
            esac
        }}
      '';

      copy-path = ''
        ''${{
            case $(uname) in
                Linux) printf '%s' "$fx" | xclip -selection clipboard ;;
                Darwin) printf '%s' "$fx" | pbcopy ;;
            esac
            lf -remote "send $id echo 'Path copied to clipboard'"
        }}
      '';

      edir-bulk = ''
        ''${{
            set -f
            edir -a
            lf -remote "send $id reload"
        }}
      '';
    };

    keybindings = {
      "\\\"" = "";
      o = "open-file";
      c = "mkdir";
      "." = "set hidden!";
      "`" = "mark-load";
      "\\'" = "mark-load";
      "<enter>" = "open";
      "<c-f>" = "fzf_jump";
      "<c-s>" = "fzf_search";
      "<c-d>" = "dragon-out";
      "g~" = "cd";
      gh = "cd";
      "g/" = "/";

      ee = "editor-open";
      V = ''$bat --paging=always "$f"'';
      Y = "copy-path";
      R = "edir-bulk";

      # ...
    };

    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
    };

    extraConfig = let
      previewer = pkgs.writeShellScriptBin "pv.sh" ''
        file=$1
        w=$2
        h=$3
        x=$4
        y=$5

        if [[ "$( ${pkgs.file}/bin/file -Lb --mime-type "$file")" =~ ^image ]]; then
            ${pkgs.kitty}/bin/kitty +kitten icat --silent --stdin no --transfer-mode file --place "''${w}x''${h}@''${x}x''${y}" "$file" < /dev/null > /dev/tty
            exit 1
        fi

        ${pkgs.pistol}/bin/pistol "$file"
      '';
      cleaner = pkgs.writeShellScriptBin "clean.sh" ''
        ${pkgs.kitty}/bin/kitty +kitten icat --clear --stdin no --silent --transfer-mode file < /dev/null > /dev/tty
      '';
    in ''
      set cleaner ${cleaner}/bin/clean.sh
      set previewer ${previewer}/bin/pv.sh
    '';
  };
}
