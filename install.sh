#!/bin/sh
# First switch on a fresh machine. Reads as the manual: each section
# is what you would type on that platform, nothing else. Later
# switches: `dots rebuild`.
#
#   curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- <target>
#
#   mac               MacBook (nix-darwin)
#   iso <host>        fresh NixOS from the installer ISO: vm, agents
#   nixos <host>      NixOS already running: agents, vm, container
#   standalone        Ubuntu and friends (home-manager)
#
# The configs enable flakes themselves; only the commands that run
# before the first switch ask for them by hand.
set -eu

repo="https://github.com/keyclicker/dotfiles.git"
flake="$HOME/.dotfiles/.nix"

usage() {
  cat >&2 <<'USAGE'
usage: install.sh mac | iso <host> | nixos <host> | standalone
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
#           NixOS from the installer ISO: vm, agents
# ==========================================================

iso() {
  # Booted from the NixOS installer ISO, two blank disks attached
  # (system, swap). Nothing is cloned: the flake is read from GitHub
  # and brings the disk layout (hardware-vm.nix) with it. disko lists
  # the disks it is about to WIPE (/dev/sda, /dev/sdb) and waits for
  # "yes"; under `curl | sh` stdin is the script, so the prompt reads
  # the terminal. Then partitions, formats, mounts under /mnt;
  # nixos-install does the rest. Then reboot.
  remote="github:keyclicker/dotfiles?dir=.nix"
  sudo nix --extra-experimental-features "nix-command flakes" \
    run github:nix-community/disko/latest -- \
    --mode destroy,format,mount --flake "$remote#$1" < /dev/tty
  # No root password: root stays locked, keyclicker logs in by key
  # (profile-server.nix).
  sudo nixos-install --no-root-passwd --flake "$remote#$1"
  # A pet with home-manager (agents) links into ~/.dotfiles; after the
  # first boot `install.sh nixos agents` clones it there.
}

# The same install from another machine, over ssh, onto whatever the
# target is booted into (ISO, cloud image, an old NixOS):
#
#   nix run github:nix-community/nixos-anywhere -- \
#     --flake ~/.dotfiles/.nix#agents --target-host root@<ip>

# ==========================================================
#            NixOS already running: agents, vm, container
# ==========================================================

nixos() {
  # The machine is already NixOS (iso above, image, or nixos-anywhere);
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
  iso)
    if [ "$#" -ne 2 ]; then usage; fi
    iso "$2" ;;
  nixos)
    if [ "$#" -ne 2 ]; then usage; fi
    nixos "$2" ;;
  standalone) standalone ;;
  *) usage ;;
esac
