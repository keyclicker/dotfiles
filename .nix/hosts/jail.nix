# Docker jail (.scripts/agent-jail), one leaf per architecture.
#
# Same split as the foreign Linux hosts: the image owns the system
# layer (nix, a host-UID user, nothing else), this leaf owns the user
# environment. The difference is where it activates — inside the
# container, from the read-only ~/.dotfiles mount:
#
#   $ nix build \
#       "path:$HOME/.dotfiles/.nix#homeConfigurations.\"keyclicker@jail-aarch64-linux\".activationPackage"
#   $ ./result/activate
#
# The launcher does this; nothing here is meant to be run by hand.
{ pkgs, ... }:

{
  imports = [ ../home/standalone.nix ];

  home.username = "keyclicker";
  home.homeDirectory = "/home/keyclicker";

  # Dev toolchains, agent CLIs, and the browser stack on top of
  # standalone's common set (same import-as-function pattern as
  # hosts/raspberry.nix), plus what a bare container lacks: on real
  # hosts the distro supplies libc tooling, locales, and certificates.
  home.packages =
    (import ../modules/dev.nix { inherit pkgs; }).environment.systemPackages
    ++ (import ../modules/agents.nix { inherit pkgs; }).environment.systemPackages
    ++ (import ../modules/browser.nix { inherit pkgs; }).environment.systemPackages
    ++ (with pkgs; [
      # Base system, absent from the image
      bashInteractive
      binutils
      cacert
      curl
      diffutils
      findutils
      gawk

      # The image links /lib/ld-linux-* into this profile, so prebuilt
      # binaries (the agent CLIs ship some) find the loader. Explicitly
      # the `out` output: glibc installs only `bin` by default, which
      # is the half without the loader in it.
      glibc.out
      glibcLocales
      gnugrep
      gnumake
      gnused
      gnutar
      gzip
      jq
      less
      pkg-config
      procps
      python3
      shadow
      which
      xz

      # Everyday project tooling the agent shouldn't have to install
      eslint
      nginx
      prettier
      python3Packages.pytest
      ruff
      tsx
      typescript
      yarn
    ]);

  # The jail runs agents directly, not through a login shell, so the
  # launcher sources hm-session-vars.sh before exec'ing them.
  home.sessionVariables = {
    EDITOR = "nvim";
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };
}
