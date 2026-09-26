# Pin the upstream Linux binary and resolve its libraries through Nix.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libX11,
  libXi,
  libxkbcommon,
}:

stdenv.mkDerivation rec {
  pname = "cua-driver";
  version = "0.29.1";

  src = fetchurl {
    url =
      "https://github.com/trycua/cua/releases/download/"
      + "cua-driver-rs-v${version}/"
      + "cua-driver-rs-${version}-linux-x86_64-binary.tar.gz";
    hash = "sha256-zzrNjXts5EkXN0RjdYq26uDB5SlVkqlo/UlsfIs9NvE=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    libX11
    libXi
    libxkbcommon
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 cua-driver $out/bin/cua-driver
    install -Dm755 cua-cursor-theme $out/bin/cua-cursor-theme
    runHook postInstall
  '';

  meta = {
    description = "Desktop automation driver with CLI and MCP interfaces";
    homepage = "https://cua.ai/docs/how-to-guides/driver/install";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cua-driver";
  };
}
