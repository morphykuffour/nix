{
  config,
  pkgs,
  libs,
  ...
}: let
  # defaults write org.hammerspoon.Hammerspoon MJConfigFile ~/.config/hammerspoon/init.lua
  hammerspoonPath = "${config.xdg.configHome}/hammerspoon";
in {
  home.packages = with pkgs; [
    hammerspoon
  ];

  home.file."${hammerspoonPath}/Spoons/SpoonInstall.spoon/init.lua".source = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/Hammerspoon/Spoons/master/Source/SpoonInstall.spoon/init.lua";
    sha256 = "0bm2cl3xa8rijmj6biq5dx4flr2arfn7j13qxbfi843a8dwpyhvk";
  };
  home.file."${hammerspoonPath}/Spoons/PassChooser.spoon/init.lua".source = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/maaslalani/PassChooser.spoon/cdf1b996036934c7b9f3a836906204d68bc6e861/init.lua";
    sha256 = "0wchpl1cb9nm7n9bwnmhy4mvwl70jzfmihxwjj688z8f18vsr188";
  };

  # PaperWM.spoon - tiling window manager
  home.activation.installPaperWM = {
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
  home.file."${hammerspoonPath}/init.lua".source = ./hammerspoon/init.lua;

  # Configure Hammerspoon to start automatically
  launchd.agents.hammerspoon = {
    enable = true;
    config = {
      ProgramArguments = ["${pkgs.hammerspoon}/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon"];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
