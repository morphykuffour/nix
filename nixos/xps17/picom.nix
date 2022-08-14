{ pkgs, ... }:

{
  services.picom = {
    enable = true;
    inactiveOpacity = 0.8;
    activeOpacity = 1.0;
    opacityRules = [
      "100:class_g *= 'brave-browser'"
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
    backend = "glx";
    vSync = true;

    # extraOptions = ''
    # '';

  };
}
