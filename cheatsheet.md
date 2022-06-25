- rebuild system and switch to new build
```bash
sudo nixos-rebuild switch
```

- list generations
```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

- change to a generation
```bash
nixos-rebuild switch --rollback=2
```

- clean up
```bash
nix-collect-garbage -d
```

- install packages using nix package manager
```bash
nix-env -iA nixos.firefox
```
