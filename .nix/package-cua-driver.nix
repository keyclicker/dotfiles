# Use Cua's own Nix build recipe, pinned until its AT-SPI fix is released.
{ pkgs }:

let
  source = pkgs.fetchFromGitHub {
    owner = "trycua";
    repo = "cua";
    tag = "cua-driver-rs-v0.29.1";
    hash = "sha256-dZF/y36rJWg+1EFRzXYX1ltDzml2gHDOKe8KCkeLXbY=";
  };
  upstream = import "${source}/nix/cua-driver/package.nix" {
    inherit pkgs;
    src = "${source}/libs/cua-driver/rust";
  };
in
upstream.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./patches/cua-atspi-byte-length.patch ];
})
