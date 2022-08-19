# nix

system-wide dotfiles for WSL, Linux and Mac OS X

- [ ] TODO test on macos and WSL

Build nixos to test in VM
```bash
sudo nixos-rebuild build --flake .#xps17
```

Build nixos and switch to new configuration.
```bash
sudo nixos-rebuild switch --flake .#xps17
```
