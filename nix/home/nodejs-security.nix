{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "nodejs";
  version = "24.22.2";

  src = fetchurl {
    url = "https://nodejs.org/dist/v${version}/node-v${version}-darwin-arm64.tar.xz";
    sha256 = "1f5ac075be50bed4780ea3be19a007fda95ea4d527d28d76d0b91de47d915115";
  };

  dontBuild = true;
  # Preserve the upstream signed binary and its bundled libraries.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R bin include lib share LICENSE "$out/"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/node" --version)" = "v${version}"
    "$out/bin/node" -e '
      const assert = require("node:assert/strict");
      const zlib = require("node:zlib");
      const input = Buffer.from("Node security runtime check");
      assert.deepEqual(zlib.brotliDecompressSync(zlib.brotliCompressSync(input)), input);
    '
    "$out/bin/node" "$out/lib/node_modules/npm/bin/npm-cli.js" --version
    runHook postInstallCheck
  '';

  meta = {
    description = "Node.js security release pinned to the official macOS arm64 binary";
    homepage = "https://nodejs.org/";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "node";
  };
}
