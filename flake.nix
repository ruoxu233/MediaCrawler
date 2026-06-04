{
  description = "MediaCrawler dev environment (NixOS): uv-managed Python + runtime libs for binary wheels";

  # Pinned to the same nixpkgs rev as the save_net monorepo so the runtime
  # libs (libGL, glib, X libs) are already in the local store — no re-download.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/549bd84d6279f9852cae6225e372cc67fb91a4c1";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        # Native libs that MediaCrawler's binary wheels dlopen at runtime.
        # opencv-python (cv2) needs libGL + glib + the X client libs; the rest
        # cover the usual manylinux-wheel expectations on NixOS.
        runtimeLibs = with pkgs; [
          stdenv.cc.cc.lib   # libstdc++
          zlib
          libGL              # libGL.so.1 (libglvnd) — cv2
          glib               # libgthread/libglib — cv2
          libsm
          libice
          libxext
          libxrender
        ];
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python311   # MediaCrawler pins 3.11 (.python-version); uv also honors this
            uv
            nodejs      # required by the zhihu / douyin sign JS
          ];
          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            echo "MediaCrawler devShell: LD_LIBRARY_PATH set (libGL/glib/X). Run: uv sync && uv run main.py --help"
          '';
        };
      });
}
