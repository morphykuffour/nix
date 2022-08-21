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
- After removing appropriate old generations you can run the garbage collector as follows:
```bash
nix-store --gc
```

- deduplicate nix store it scans the store for regular files with identical contents, and replaces them with hard links to a single instance.
```bash
nix store optimise - replace identical files in the store by hard links
```

- install packages using nix package manager
```bash
nix-env -iA nixos.firefox
```

-- updating and upgrading
```bash
nix-channel --update
sudo nixos-rebuild --upgrade
```

-- get sha256 for remote pkgs
```bash
# nix-prefetch-url --unpack https://github.com/nix-community/NUR/archive/master.tar.gz
nix-prefetch-url --unpack #<url>
```
