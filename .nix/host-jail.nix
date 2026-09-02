# Docker jail (.scripts/agent-jail), one output per architecture.
#
# Same split as the foreign Linux hosts. The image owns the system
# layer: nix, a user with the host's UID, nothing else. This leaf owns
# the user environment. It activates inside the container, from the
# read-only ~/.dotfiles mount:
#
#   $ nix build \
#       "path:$HOME/.dotfiles/.nix#homeConfigurations.\"keyclicker@jail-aarch64-linux\".activationPackage"
#   $ ./result/activate
#
# The launcher runs this. Nothing here is meant to be run by hand.
{ config, pkgs, ... }:

let
  pnpmHome = "${config.home.homeDirectory}/.local/share/pnpm";
in
{
  imports = [ ./home-standalone.nix ];

  home.username = "keyclicker";
  home.homeDirectory = "/home/keyclicker";

  # Agent CLIs and the browser stack, on top of the common set from
  # home-standalone.nix and imported the same way. The jail-specific
  # part is libc, locales and certificates: a real host has a distro
  # underneath, this one has not. Per-project tools are not declared
  # here. They come from the project's own lockfile via `uvx` or
  # `pnpm dlx`.
  home.packages =
    (import ./module-agents.nix { inherit pkgs; }).environment.systemPackages
    ++ (import ./module-browser.nix { inherit pkgs; }).environment.systemPackages
    ++ (with pkgs; [
      # Base system the image has no distro to provide. procps lives
      # here, not in module-common.nix: its ps reads /proc, so on
      # darwin it would shadow the native ps with a broken one.
      bashInteractive
      cacert
      glibcLocales
      procps
      shadow

      # The image links /lib/ld-linux-* into this profile, so prebuilt
      # binaries (the agent CLIs ship some) find the loader. The `out`
      # output is named on purpose: by default only `bin` is installed,
      # and the loader is not in `bin`.
      glibc.out

      # Not a toolchain. Only the jail ever serves anything.
      nginx
    ]);

  # The jail runs agents directly, not through a login shell, so the
  # launcher sources hm-session-vars.sh before exec'ing them.
  home.sessionVariables = {
    EDITOR = "nvim";
    # Agents never source .zshrc, so UTF-8 is set here. Without it the
    # locale archive goes unused and everything runs under POSIX C.
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    PNPM_HOME = pnpmHome;
  };

  # pnpm puts global bins in $PNPM_HOME/bin and refuses `pnpm add -g`
  # unless that directory is on PATH.
  home.sessionPath = [ "${pnpmHome}/bin" ];
}
