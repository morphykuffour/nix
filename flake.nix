{
  description = "an ambitous flake for linux, macos, win11-wsl";

  inputs = {
    # utils.url = "github:morphykuffour/nix";

    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NUR packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS 
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # windows wsl
    wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim.url = "github:neovim/neovim?dir=contrib";
  };

  outputs =
    inputs@{ self
      # , utils
    , nixpkgs
    , home-manager
    , nur
    , darwin
    , wsl
    , neovim
    , ...
    }:
    let
      #variables
      user = "morp";

    in
    {
      # NixOS configurations
      nixosConfigurations = (
        import ./nixos {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs home-manager nur user;
        }
      );

      # macos configurations
      # darwinConfigurations = (
      #   import ./darwin {
      #     inherit (nixpkgs) lib;
      #     inherit inputs nixpkgs home-manager darwin user;
      #   }
      # );

      # wsl configurations
      # wslConfigurations = (
      #   import ./wsl {
      #     inherit (nixpkgs) lib;
      #     inherit inputs nixpkgs home-manager nur user;
      #   }
      # );

      # os-agnotisc configurations
      # homeConfigurations = (
      #   import ./home.nix {
      #     inherit (nixpkgs) lib;
      #     inherit inputs nixpkgs home-manager user;
      #   }
      # );
    };
}
