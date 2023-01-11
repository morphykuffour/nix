** install as a nix-channel

```bash
nix-channel --add https://github.com/nix-community/emacs-overlay/archive/master.tar.gz emacs-overlay
nix-channel --update
```

** install into env

```bash
git clone https://github.com/nix-community/emacs-overlay.git
cd emacs-overlay
nix-build --expr 'with (import <nixpkgs> { overlays = [ (import ./.) ]; }); emacsGit
nix-env -iA result
```

You can use the nix-store command to find a package in the Nix store by querying the dependencies of the package. Here's an example of how you can use the nix-store command to find a package you built:

Run the nix-build --expr 'with (import <nixpkgs> { overlays = [ (import ./.) ]; }); emacsGit' command again to build the emacsGit package

Once the build is complete, you can use the nix-store --query --references command to list all store paths that depend on the package. This will include the package you just built, along with any dependencies that it has. For example:

```nix
nix-store --query --references $(nix-build --no-out-link -E 'with import <nixpkgs> { overlays = [ (import ./emacs-overlay) ]; } ; emacsGit')
```

This command will give you the store path to the emacsGit package built

Use nix-env -iA <store-path-from-step-2> to install the package into your user environment, where <store-path-from-step-2> is the path to the package in the Nix store that you obtained from step 2.
This command will make the package available for use in your user environment and the emacs command will now point to the package you just built
