# Foreign (non-NixOS) Linux hosts: the distro owns the system and the
# machine is managed imperatively (apt, npm, ...). Nix only links the
# dotfiles and adds the tools they call or need newer than a distro
# ships. Everything else is the distro's job.
{ pkgs, ... }:

{
  imports = [ ./home-dotfiles.nix ];

  home.packages = with pkgs; [
    # Workspace: configs assume current releases
    zsh
    tmux
    neovim
    tree-sitter # nvim

    # Called by the zsh, git and tmux configs
    fzf # `fzf --zsh` needs >= 0.48
    carapace
    delta

    # nvim pickers and agents; Ubuntu ships `fd` as `fdfind`
    ripgrep
    fd

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
