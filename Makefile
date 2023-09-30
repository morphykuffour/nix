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

clean:
	sudo nix-collect-garbage --delete-older-than 14d
	nix-collect-garbage --delete-older-than 14d
	if [-e "result" ]; then
		unlink result
	else
		echo "`result` symlink does not exist."
	fi
