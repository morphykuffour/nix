# nix

system-wide dotfiles for WSL, Linux and Mac OS X

- [x] TODO test on Linux #WORKING
- [-] TODO test on WSL #BUILDS
- [ ] TODO test on macos 

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
