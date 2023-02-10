# NixOS configuration

system-wide configuration for WSL, Linux and Mac OS X

## Clone and install configuration

Clone the repo using the following command in bash
```bash
git clone https://github.com/morphykuffour/nix.git
```

Build nixos and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo nixos-rebuild switch --flake .#xps17-nixos
```

Build darwin and switch to new configuration. `<flake-uri> = pwd`
```bash
nix build .#darwinConfigurations.macmini-darwin.system
sudo ./result/sw/bin/darwin-rebuild switch --flake .
```

Build wsl and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo nixos-rebuild switch --flake .#win-wsl
```

Build nixos on zfs and switch to new configuration. `<flake-uri> = pwd`
```bash
sudo nixos-rebuild switch --flake .#optiplex-nixos
```
