#!/bin/sh
# First switch on a fresh machine. Reads as the manual: each section
# is what you would type on that platform, nothing else. Later
# switches: `dots rebuild`.
#
#   ./install.sh mac               MacBook (nix-darwin)
#   ./install.sh nixos <host>      NixOS: agents, vm, container
#   ./install.sh standalone        Ubuntu and friends (home-manager)
#
# The configs enable flakes themselves; only the commands that run
# before the first switch ask for them by hand.
set -eu

flake="$HOME/.dotfiles/.nix"

# The indented lines of the header above.
usage() {
  sed -n '/^#   \.\/install/p' "$0" | cut -c3- >&2
  exit 1
}

# Home-manager links point at ~/.dotfiles; refuse other checkouts.
if [ "$(CDPATH= cd "$(dirname "$0")" && pwd)" != "$HOME/.dotfiles" ]; then
  echo "install.sh: clone the repo to ~/.dotfiles first" >&2
  exit 1
fi

# ==========================================================
#                      macOS: nix-darwin
# ==========================================================

mac() {
  # Multi-user nix; the installer creates the /nix volume.
  if ! command -v nix >/dev/null; then
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
  fi
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

  # darwin-rebuild is not installed yet, so run it from its flake once;
  # after the switch it is on PATH.
  sudo nix --extra-experimental-features "nix-command flakes" \
    run nix-darwin/master#darwin-rebuild -- switch --flake "$flake#mac"
}

# ==========================================================
#                 NixOS: agents, vm, container
# ==========================================================

nixos() {
  # The machine is already NixOS (installer, image, or nixos-anywhere);
  # this only moves it onto this repo's configuration.
  sudo nixos-rebuild switch --flake "$flake#$1"
}

# ==========================================================
#             Foreign Linux: standalone home-manager
# ==========================================================

standalone() {
  # Multi-user nix next to the distro's own package manager.
  if ! command -v nix >/dev/null; then
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
  fi
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

  # home-manager is not installed yet, so run it from its flake once;
  # after the switch it is in the profile. Outputs are per
  # architecture. -b renames the dotfiles it replaces instead of
  # failing on them.
  nix --extra-experimental-features "nix-command flakes" \
    run home-manager -- switch -b hm-bak \
    --flake "$flake#keyclicker@standalone-$(uname -m)-linux"

  # Login shell: the zsh from the nix profile.
  zsh="$HOME/.nix-profile/bin/zsh"
  grep -qx "$zsh" /etc/shells || echo "$zsh" | sudo tee -a /etc/shells
  chsh -s "$zsh"
}

# ==========================================================
#                          Dispatch
# ==========================================================

case "${1:-}" in
  mac) mac ;;
  nixos)
    if [ "$#" -ne 2 ]; then usage; fi
    nixos "$2" ;;
  standalone) standalone ;;
  *) usage ;;
esac
