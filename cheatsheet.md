- rebuild system and switch to new build
sudo nixos-rebuild switch

- list generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

- change to a generation
nixos-rebuild switch --rollback=2

- clean up
nix-collect-garbage -d
