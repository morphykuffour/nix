{
  rustPlatform,
  agtx-src,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "agtx";
  version = "0.1.0";
  src = agtx-src;
  cargoLock = {
    lockFile = "${agtx-src}/Cargo.lock";
  };
  meta = {
    description = "Terminal-native kanban board for managing coding agents";
    mainProgram = "agtx";
  };
}
