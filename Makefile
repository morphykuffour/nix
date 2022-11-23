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
	SWITCH_CMD := exec darwin-rebuild switch --flake .
endif

switch:
	$(SWITCH_CMD)

build:
	$(BUILD_CMD)

update:
	sudo nix flake update

fmt:
	alejandra .

clean:
	sudo nix-collect-garbage --delete-older-than 14d
	nix-collect-garbage --delete-older-than 14d
