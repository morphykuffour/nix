SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

HOSTNAME ?= $(shell hostname)
UNAME_S := $(shell uname -s)


ifeq ($(UNAME_S),Linux)
	SWITCH_CMD := sudo nixos-rebuild --use-remote-sudo -I nixos-config="machines/$(HOSTNAME)/configuration.nix" switch --flake '.\#' --impure 
	BUILD_CMD  := sudo nixos-rebuild --use-remote-sudo -I nixos-config="machines/$(HOSTNAME)/configuration.nix" build --flake '.\#'
	EDIT_HOME := nvim hosts/$(HOSTNAME)/configuration.nix
	EDIT_CONF := nvim home.nix
endif
ifeq ($(UNAME_S),Darwin)
	BUILD_CMD  := nix build --experimental-features 'nix-command flakes' '.\#darwinConfigurations.macmini-darwin.system' --impure
	SWITCH_CMD := ./result/sw/bin/darwin-rebuild switch --flake .
	EDIT_HOME := nvim hosts/$(HOSTNAME)/configuration.nix
	EDIT_CONF := nvim hosts/$(HOSTNAME)/home.nix
endif

eh:
	$(EDIT_CONF)
ec:
	$(EDIT_HOME)

switch:
	$(SWITCH_CMD)

build:
	$(BUILD_CMD)

action-build:
	nixos-rebuild build --flake .#xps17-nixos --impure

update:
	sudo nix flake update

fmt:
	alejandra .

clean:
	sudo nix-collect-garbage --delete-older-than 14d
	nix-collect-garbage --delete-older-than 14d
