#!/bin/sh
# Bootstrap a machine from this repo: install nix if missing, enable
# flakes, then build and switch via .scripts/dots.
#
# Usage: ./install.sh [host] [shell]
#   host   flake host, passed to dots rebuild (defaults: mac on darwin,
#          short hostname on NixOS, standalone elsewhere)
#   shell  optional: set login shell to this binary from the nix
#          profile, e.g. zsh (requires host to be given too)
set -eu

dir="$(CDPATH= cd "$(dirname "$0")" && pwd)"

# Home-manager symlinks point at ~/.dotfiles; refuse other checkouts.
if [ "$dir" != "$HOME/.dotfiles" ]; then
  echo "install.sh: repo must be checked out at ~/.dotfiles (got $dir)" >&2
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  curl -L https://nixos.org/nix/install | sh -s -- --daemon
  # Put nix on PATH for the rest of this script.
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Enable flakes at user scope if no config enables them yet. NixOS and
# nix-darwin set this system-wide (module-common.nix), but on a fresh
# machine the first switch itself already needs it.
conf="${XDG_CONFIG_HOME:-$HOME/.config}/nix/nix.conf"
if ! grep -hs experimental-features "$conf" /etc/nix/nix.conf \
    | grep -q flakes; then
  mkdir -p "$(dirname "$conf")"
  printf 'experimental-features = nix-command flakes\n' >> "$conf"
fi

"$dir/.scripts/dots" rebuild ${1:+"$1"}

if [ "$#" -ge 2 ]; then
  bin="$HOME/.nix-profile/bin/$2"
  if [ ! -x "$bin" ]; then
    echo "install.sh: $bin not found or not executable" >&2
    exit 1
  fi
  grep -qx "$bin" /etc/shells || echo "$bin" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$bin"
fi
