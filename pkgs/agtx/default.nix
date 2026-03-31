{
  rustPlatform,
  agtx-src,
  git,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "agtx";
  version = "0.1.0";
  src = agtx-src;
  cargoLock = {
    lockFile = "${agtx-src}/Cargo.lock";
  };
  nativeCheckInputs = [ git ];
  meta = {
    description = "Terminal-native kanban board for managing coding agents";
    mainProgram = "agtx";
  };
}
