SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

HOSTNAME ?= $(shell hostname)
UNAME_S := $(shell uname -s)

EDIT_FLAKE := nvim flake.nix

ifeq ($(UNAME_S),Linux)
	SWITCH_CMD := sudo nixos-rebuild --use-remote-sudo -I nixos-config="machines/$(HOSTNAME)/configuration.nix" switch --flake '.\#' --impure 
	BUILD_CMD  := sudo nixos-rebuild --use-remote-sudo -I nixos-config="machines/$(HOSTNAME)/configuration.nix" build --flake '.\#'
	EDIT_HOME := nvim hosts/$(HOSTNAME)/configuration.nix
	EDIT_CONF := nvim hosts/$(HOSTNAME)/home.nix
	EDIT_DEF := nvim hosts/$(HOSTNAME)/default.nix
endif
ifeq ($(UNAME_S),Darwin)
	BUILD_CMD  := nix build --experimental-features 'nix-command flakes' '.\#darwinConfigurations.macmini-darwin.system' --impure
	SWITCH_CMD := sudo rm -rf /etc/shells && ./result/sw/bin/darwin-rebuild switch --flake .
	EDIT_HOME := nvim hosts/$(HOSTNAME)/configuration.nix
	EDIT_CONF := nvim hosts/$(HOSTNAME)/home.nix
	EDIT_DEF := nvim hosts/$(HOSTNAME)/default.nix
endif

ef:
	$(EDIT_FLAKE)

ed:
	$(EDIT_DEF)
eh:
	$(EDIT_CONF)
ec:
	$(EDIT_HOME)

switch:
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

# Remote building for xps17-nixos from any machine (including Mac)
# Requires: SSH access to xps17-nixos via tailscale or direct connection
REMOTE_HOST ?= xps17-nixos
REMOTE_USER ?= morph
REMOTE_NIX_DIR ?= ~/nix

remote-switch:
	@echo "Building and switching on $(REMOTE_HOST)..."
	ssh $(REMOTE_USER)@$(REMOTE_HOST) "cd $(REMOTE_NIX_DIR) && git pull && make switch"

remote-build:
	@echo "Building on $(REMOTE_HOST)..."
	ssh $(REMOTE_USER)@$(REMOTE_HOST) "cd $(REMOTE_NIX_DIR) && git pull && make build"

# Build xps17-nixos config locally on Mac and deploy via SSH
# This uses nixos-rebuild's --target-host to deploy to remote
# Requires: linux-builder or remote builder configured on Mac
xps-deploy:
	nixos-rebuild switch --flake '.#xps17-nixos' \
		--target-host $(REMOTE_USER)@$(REMOTE_HOST) \
		--build-host $(REMOTE_USER)@$(REMOTE_HOST) \
		--use-remote-sudo
#
# Remote deploy for optiplex-nixos from macOS (no SSHing in / no git pull on target)
# Uses nixos-rebuild with --target-host and --build-host so evaluation happens locally,
# build happens on the remote Linux, and the closure is pushed + switched remotely.
optiplex-deploy:
	nix run nixpkgs#nixos-rebuild -- switch --flake '.#optiplex-nixos' \
		--target-host morph@optiplex-nixos \
		--build-host morph@optiplex-nixos \
		--use-remote-sudo

optiplex-build-remote:
	nix run nixpkgs#nixos-rebuild -- build --flake '.#optiplex-nixos' \
		--build-host morph@optiplex-nixos

# Build only (no switch) on remote builder
xps-build-remote:
	nixos-rebuild build --flake '.#xps17-nixos' \
		--build-host $(REMOTE_USER)@$(REMOTE_HOST)

clean:
	sudo nix-collect-garbage --delete-older-than 14d
	nix-collect-garbage --delete-older-than 14d
	if [-e "result" ]; then
		unlink result
	else
		echo "`result` symlink does not exist."
	fi
