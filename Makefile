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
endif
ifeq ($(UNAME_S),Darwin)
	BUILD_CMD  := nix build --experimental-features 'nix-command flakes' '.\#darwinConfigurations.macmini-darwin.system'
	SWITCH_CMD := ./result/sw/bin/darwin-rebuild switch --flake .
endif

edit:
	nvim hosts/$(HOSTNAME)/configuration.nix

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
