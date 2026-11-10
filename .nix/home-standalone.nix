# Foreign (non-NixOS) Linux hosts: the distro owns the system and the
# machine is managed imperatively (apt, npm, ...). Nix only links the
# dotfiles and adds the tools they call or need newer than a distro
# ships, plus the system monitors. Everything else is the distro's
# job.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Multi-user installer's shell hook (install.sh installs with --daemon)
  nixDaemonProfile = "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh";

  # Same bins, in the order the hook prepends them
  nixBins = [
    "${config.home.profileDirectory}/bin"
    "/nix/var/nix/profiles/default/bin"
  ];
in
{
  imports = [ ./home-dotfiles.nix ];

  # ======================================================
  #            Nix on PATH outside interactive shells
  # ======================================================

  # The installer hooks only interactive shells (/etc/zshrc,
  # /etc/bashrc), so `ssh host cmd` and `zsh -c` missed nix bins.
  # .zshenv sources hm-session-vars.sh in every zsh; the hook's own
  # guard makes /etc/zshrc a no-op afterwards.
  home.sessionVariablesExtra = ''
    if [ -e ${nixDaemonProfile} ]; then
      . ${nixDaemonProfile}
    fi
  '';

  # User units (linger starts them before any shell): same PATH as zsh
  systemd.user.sessionVariables.PATH = lib.concatStringsSep ":" (
    nixBins ++ config.home.sessionPath ++ [ "$PATH" ]
  );

  home.packages = with pkgs; [
    # Workspace: configs assume current releases
    zsh
    tmux
    neovim
    tree-sitter # nvim

    # Called by the zsh, git and tmux configs
    fzf # `fzf --zsh` needs >= 0.48
    carapace

    # nvim pickers and agents; Ubuntu ships `fd` as `fdfind`
    ripgrep
    fd

    # System monitors
    htop
    btop-rocm # plain btop can't dlopen librocm_smi64: no AMD GPU

    # GitHub CLI: distro builds lag behind GitHub's API
    gh

    # Terminfo for terminals the distro's ncurses doesn't know yet;
    # picked up via TERMINFO_DIRS exported in .zshenv.
    ghostty.terminfo
  ];

  # User-level equivalent of the nix settings in module-core.nix
  # (whose nix.* options are system-scoped and don't apply here).
  nix = {
    # Only used to render and check ~/.config/nix/nix.conf, not
    # installed: the daemon's nix stays the one on PATH.
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # The distro manages its own system, but nothing there collects
    # the nix store, so this timer is the only gc these hosts get.
    # A user timer needs the user's systemd instance up: install.sh
    # enables linger so it runs from boot, not from the first login.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Standalone home-manager manages itself.
  programs.home-manager.enable = true;
}
