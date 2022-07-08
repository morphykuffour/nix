{ pkgs, config, lib, ... }:

{
  services.picom = {
    enable = true;
    package = pkgs.picom.overrideAttrs (o: {
      src = pkgs.fetchFromGitHub {
        #repo = "picom";
        #owner = "pijulius";
        #rev = "982bb43e5d4116f1a37a0bde01c9bda0b88705b9";
        #sha256 = "YiuLScDV9UfgI1MiYRtjgRkJ0VuA1TExATA2nJSJMhM=";
        repo = "picom";
        owner = "jonaburg";
        rev = "e3c19cd7d1108d114552267f302548c113278d45";
        sha256 = "0000000000000000000000000000000000000000000000000000";
      };
    });
    backend = "glx";
    vSync = true;
    inactiveOpacity = 0.93;
    activeOpacity = 1.0;
    menuOpacity = 0.93;

    opacityRules = [
      "100:name = 'brave-browser'"
      "100:name = 'Picture in picture'"
      "100:name = 'Picture-in-Picture'"
      "100:class_g = 'rofi'"
      "70:class_g = 'kitty'"
      "70:class_g = 'nvim'"
      "70:class_g = 'vim'"
    ];


    fade = true;
    shadow = true;
    fadeDelta = 4;
    fadeSteps = [ 0.02 0.02 ];
    settings = {
      blur = true;
      frame-opacity = 1;
      blur-background = true;
      inactive-opacity-override = false;
      blur-kern = "7x7box";
      blur-background-exclude = [ "class_g = 'brave-browser'" ];
      inactiveDim = "0.2";
      focus-exclude = [
        "class_g = 'brave-browser'"
        "class_g = 'firefox'"
        "class_g = 'Google-chrome'"
      ];
    };

    # extraOptions = ''
    # '';

  };
}
