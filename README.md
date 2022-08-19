# nix

system-wide dotfiles for WSL, Linux and Mac OS X

- [ ] TODO test on macos and WSL

Build nixos to check
```bash
sudo nixos-rebuild build --flake .#xps17
```

Build nixos and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo nixos-rebuild switch --flake .#xps17
```

Build darwin and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo darwin-rebuild switch --flake .#mac_mini
```
