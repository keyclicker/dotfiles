#!/bin/sh
# First switch on a fresh machine. Reads as the manual: each section
# is what you would type on that platform, nothing else. Later
# switches: `dots rebuild`.
#
#   curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- <target>
#
#   mac               MacBook (nix-darwin)
#   nixos <host>      NixOS: agents, vm, container
#   standalone        Ubuntu and friends (home-manager)
#
# The configs enable flakes themselves; only the commands that run
# before the first switch ask for them by hand.
set -eu

repo="https://github.com/keyclicker/dotfiles.git"
flake="$HOME/.dotfiles/.nix"

usage() {
  cat >&2 <<'USAGE'
usage: install.sh mac | nixos <host> | standalone
USAGE
  exit 1
}

# ==========================================================
#                 Common: nix and the checkout
# ==========================================================

# Multi-user nix (on mac the installer also creates the /nix volume).
# NixOS has it already.
install_nix() {
  if ! command -v nix >/dev/null; then
    curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
  fi
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
}

# Home-manager links point at ~/.dotfiles, so that is where the repo
# goes. Cloned with nix's git: works before any distro package or
# Xcode tools are installed.
clone() {
  if [ ! -d "$HOME/.dotfiles" ]; then
    nix --extra-experimental-features "nix-command flakes" \
      run nixpkgs#git -- clone "$repo" "$HOME/.dotfiles"
  fi
}

# ==========================================================
#                      macOS: nix-darwin
# ==========================================================

mac() {
  install_nix
  clone

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
  clone
  sudo nixos-rebuild switch --flake "$flake#$1"
}

# ==========================================================
#             Foreign Linux: standalone home-manager
# ==========================================================

standalone() {
  install_nix
  clone

  # home-manager is not installed yet, so run it from its flake once;
  # after the switch it is in the profile. Outputs are per
  # architecture. -b renames the dotfiles it replaces instead of
  # failing on them.
  nix --extra-experimental-features "nix-command flakes" \
    run home-manager -- switch -b hm-bak \
    --flake "$flake#keyclicker@standalone-$(uname -m)-linux"

  # Login shell: the zsh from the nix profile. Via sudo so it works
  # from a pipe, where chsh could not ask for a password.
  zsh="$HOME/.nix-profile/bin/zsh"
  grep -qx "$zsh" /etc/shells || echo "$zsh" | sudo tee -a /etc/shells
  sudo chsh -s "$zsh" "$USER"
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
