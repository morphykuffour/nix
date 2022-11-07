# nix

system-wide dotfiles for WSL, Linux and Mac OS X

- [x] TODO test on Linux #works
- [x] TODO test on Linux on ZFS #works
- [x] TODO test on WSL #works
    - [ ] TODO add wsl github repo as a submodule without nix complaining
    - [ ] TODO fix DBus error
	    - https://x410.dev/cookbook/wsl/sharing-dbus-among-wsl2-consoles/
    - [ ] TODO fix openssh error
- [ ] TODO get macos and nix working together

Clone the repo using the following command in bash
```bash
git clone --recurse-submodules https://github.com/morphykuffour/nix.git
```
Build nixos and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo nixos-rebuild switch --flake .#xps17-nixos
```

Build darwin and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo darwin-rebuild switch --flake .#mac_mini
```

Build wsl and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo nixos-rebuild switch --flake .#win-wsl
```

Build nixos on zfs and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo nixos-rebuild switch --flake .#optiplex-nixos
```
