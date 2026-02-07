SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

HOSTNAME ?= $(shell hostname)
UNAME_S := $(shell uname -s)

EDIT_FLAKE := nvim flake.nix

ifeq ($(UNAME_S),Linux)
	# Local NixOS rebuild for the current host
	SWITCH_CMD := nixos-rebuild switch --flake '.\#$(HOSTNAME)' --impure --sudo
	BUILD_CMD  := nixos-rebuild build  --flake '.\#$(HOSTNAME)'
	EDIT_HOME := nvim hosts/$(HOSTNAME)/configuration.nix
	EDIT_CONF := nvim hosts/$(HOSTNAME)/home.nix
	EDIT_DEF := nvim hosts/$(HOSTNAME)/default.nix
endif
ifeq ($(UNAME_S),Darwin)
	BUILD_CMD  := nix build --experimental-features 'nix-command flakes' '.\#darwinConfigurations.macmini-darwin.system' --impure
	SWITCH_CMD := sudo sh -c 'rm -rf /etc/shells && ./result/sw/bin/darwin-rebuild switch --flake .'
	EDIT_HOME := nvim hosts/$(HOSTNAME)/configuration.nix
	EDIT_CONF := nvim hosts/$(HOSTNAME)/home.nix
	EDIT_DEF := nvim hosts/$(HOSTNAME)/default.nix
endif

# Allow customizing SSH behavior (works fine over Tailscale IP or MagicDNS)
export NIX_SSHOPTS ?= -o ServerAliveInterval=30 -o ServerAliveCountMax=10

ef:
	$(EDIT_FLAKE)

ed:
	$(EDIT_DEF)
eh:
	$(EDIT_CONF)
ec:
	$(EDIT_HOME)

switch: build
	$(SWITCH_CMD)

build:
	$(BUILD_CMD)

wsl-build:
	nix build .#nixosConfigurations.win-wsl.config.system.build.installer
	echo "The rootfs tarball can then be found under ./result/tarball/nixos-wsl-x86_64-linux.tar.gz"
	echo "croc send ./result/tarball/nixos-wsl-x86_64-linux.tar.gz"

push-cachix:
	$(BUILD_CMD) | cachix push jedimaster

update:
	sudo nix flake update

fmt:
	alejandra .

# Build-and-switch targets for each host
# These combine build + switch for local execution on each host

# macmini-darwin (Darwin)
macmini-build-and-switch:
	nix build --experimental-features 'nix-command flakes' '.\#darwinConfigurations.macmini-darwin.system' --impure
	sudo sh -c 'rm -rf /etc/shells && ./result/sw/bin/darwin-rebuild switch --flake .'

# xps17-nixos (NixOS)
xps17-build-and-switch:
	nixos-rebuild build --flake '.\#xps17-nixos'
	nixos-rebuild switch --flake '.\#xps17-nixos' --impure --sudo

# optiplex-nixos (NixOS)
optiplex-build-and-switch:
	nixos-rebuild build --flake '.\#optiplex-nixos'
	nixos-rebuild switch --flake '.\#optiplex-nixos' --impure --sudo

# t480-nixos (NixOS)
t480-build-and-switch:
	nixos-rebuild build --flake '.\#t480-nixos'
	nixos-rebuild switch --flake '.\#t480-nixos' --impure --sudo

# Remote building for xps17-nixos from any machine (including Mac)
# Requires: SSH access to xps17-nixos via tailscale or direct connection
REMOTE_HOST ?= xps17-nixos
REMOTE_USER ?= morph
REMOTE_NIX_DIR ?= ~/nix
REMOTE := $(REMOTE_USER)@$(REMOTE_HOST)

remote-switch:
	@echo "Building and switching on $(REMOTE_HOST)..."
	ssh $(REMOTE) "cd $(REMOTE_NIX_DIR) && git pull && make switch"

remote-build:
	@echo "Building on $(REMOTE_HOST)..."
	ssh $(REMOTE) "cd $(REMOTE_NIX_DIR) && git pull && make build"

# Build xps17-nixos config locally on Mac and deploy via SSH
# This uses nixos-rebuild's --target-host to deploy to remote
# Requires: linux-builder or remote builder configured on Mac
xps-deploy:
	nix run nixpkgs#nixos-rebuild -- switch --flake '.#xps17-nixos' \
		--target-host $(REMOTE) \
		--build-host $(REMOTE) \
		--sudo

optiplex-deploy:
	nix run nixpkgs#nixos-rebuild -- switch --flake '.#optiplex-nixos' \
		--target-host morph@optiplex-nixos \
		--build-host morph@optiplex-nixos \
		--sudo

optiplex-build-remote:
	nix run nixpkgs#nixos-rebuild -- build --flake '.#optiplex-nixos' \
		--build-host morph@optiplex-nixos

# Build only (no switch) on remote builder
xps-build-remote:
	nix run nixpkgs#nixos-rebuild -- build --flake '.#xps17-nixos' \
		--build-host $(REMOTE)

clean:
	sudo nix-collect-garbage --delete-older-than 14d
	nix-collect-garbage --delete-older-than 14d
	if [ -e "result" ]; then \
		unlink result; \
	else \
		echo "'result' symlink does not exist."; \
	fi
