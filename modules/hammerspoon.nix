{
  config,
  pkgs,
  libs,
  ...
}: let
  # defaults write org.hammerspoon.Hammerspoon MJConfigFile ~/.config/hammerspoon/init.lua
  hammerspoonPath = "${config.xdg.configHome}/hammerspoon";
in {
  # Note: Hammerspoon must be installed manually or via Homebrew
  # brew install --cask hammerspoon

  home.file."${hammerspoonPath}/Spoons/SpoonInstall.spoon/init.lua".source = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/Hammerspoon/Spoons/master/Source/SpoonInstall.spoon/init.lua";
    sha256 = "0bm2cl3xa8rijmj6biq5dx4flr2arfn7j13qxbfi843a8dwpyhvk";
  };

  # Install additional Spoons via activation scripts
  home.activation = {
    # PaperWM.spoon - tiling window manager
    installPaperWM = {
      after = [];
      before = ["checkLinkTargets"];
      data = ''
        if [ ! -d "${hammerspoonPath}/Spoons/PaperWM.spoon" ]; then
          echo "Installing PaperWM.spoon..."
          ${pkgs.git}/bin/git clone https://github.com/mogenson/PaperWM.spoon "${hammerspoonPath}/Spoons/PaperWM.spoon"
        else
          echo "PaperWM.spoon already installed"
        fi
      '';
    };

    # ActiveSpace.spoon - Show active and layout of Mission Control spaces in the menu bar
    installActiveSpace = {
      after = [];
      before = ["checkLinkTargets"];
      data = ''
        if [ ! -d "${hammerspoonPath}/Spoons/ActiveSpace.spoon" ]; then
          echo "Installing ActiveSpace.spoon..."
          ${pkgs.git}/bin/git clone https://github.com/mogenson/ActiveSpace.spoon "${hammerspoonPath}/Spoons/ActiveSpace.spoon"
        else
          echo "ActiveSpace.spoon already installed"
        fi
      '';
    };

    # WarpMouse.spoon - Move mouse cursor between screen edges to simulate side-by-side screens
    installWarpMouse = {
      after = [];
      before = ["checkLinkTargets"];
      data = ''
        if [ ! -d "${hammerspoonPath}/Spoons/WarpMouse.spoon" ]; then
          echo "Installing WarpMouse.spoon..."
          ${pkgs.git}/bin/git clone https://github.com/mogenson/WarpMouse.spoon "${hammerspoonPath}/Spoons/WarpMouse.spoon"
        else
          echo "WarpMouse.spoon already installed"
        fi
      '';
    };

    # Swipe.spoon - Perform actions when trackpad swipe gestures are recognized
    installSwipe = {
      after = [];
      before = ["checkLinkTargets"];
      data = ''
        if [ ! -d "${hammerspoonPath}/Spoons/Swipe.spoon" ]; then
          echo "Installing Swipe.spoon..."
          ${pkgs.git}/bin/git clone https://github.com/mogenson/Swipe.spoon "${hammerspoonPath}/Spoons/Swipe.spoon"
        else
          echo "Swipe.spoon already installed"
        fi
      '';
    };

    # FocusMode.spoon - Helps you stay in flow by dimming everything except what you're working on
    installFocusMode = {
      after = [];
      before = ["checkLinkTargets"];
      data = ''
        if [ ! -d "${hammerspoonPath}/Spoons/FocusMode.spoon" ]; then
          echo "Installing FocusMode.spoon..."
          ${pkgs.git}/bin/git clone https://github.com/selimacerbas/FocusMode.spoon "${hammerspoonPath}/Spoons/FocusMode.spoon"
        else
          echo "FocusMode.spoon already installed"
        fi
      '';
    };
  };
  home.file."${hammerspoonPath}/init.lua".source = ./hammerspoon/init.lua;
}
