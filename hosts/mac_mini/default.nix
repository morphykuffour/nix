#
#  These are the different profiles that can be used when building on MacOS
#
#  flake.nix
#   └─ ./darwin
#       ├─ ./default.nix *
#       ├─ configuration.nix
#       └─ home.nix
#

{ lib, inputs, nixpkgs, home-manager, darwin, user, ...}:

let
  system = "x86_64-darwin";                                
in
{
  macbook = darwin.lib.darwinSystem {                       
    inherit system;
    specialArgs = { inherit user inputs; };
    modules = [                                           
      ./configuration.nix
      
      home-manager.darwinModules.home-manager {          
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit user; }; 
        home-manager.users.${user} = import ./home.nix;
      }
    ];
  };
}
