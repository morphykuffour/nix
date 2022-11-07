# code from https://github.com/Xe/nixos-configs/blob/master/ops/metadata/peers.nix
{ writeTextFile, lib, ... }:

let
  metadata = lib.importTOML ./hosts.toml;
in {
  inherit metadata;
  raw = metadata.hosts;
}
