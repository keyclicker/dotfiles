# Symlinks $HOME dotfiles to their live copies in ~/.dotfiles.
# Out-of-store links: edits apply immediately, no rebuild needed.
# Requires the repo checked out at ~/.dotfiles on every host. Every
# host links everything, a link is free; only entries bound to one
# OS (macOS preferences, the sway session) check the platform.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  # zsh plugins come from nixpkgs, pinned by flake.lock. The list is
  # the load order: syntax-highlighting goes last, except that
  # history-substring-search must follow it (upstream requirement).
  zshPlugins = [
    "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
    "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
  ];

  # tmux plugins likewise, replacing tpm: no clone, no prefix+I, pinned
  # by flake.lock. `rtp` is the plugin's entry script.
  tmuxPlugins = with pkgs.tmuxPlugins; [
    sensible
    vim-tmux-navigator
    resurrect
    continuum
  ];
in
{
  home.file = {
    # Suppress the "Last login" banner in login shells
    ".hushlogin".text = "";

    # Generated, not linked: store paths change with the flake lock.
    # .zshrc sources it after compinit.
    ".config/zsh/plugins.zsh".text = lib.concatMapStrings (plugin: "source ${plugin}\n") zshPlugins;
    ".config/tmux/plugins.conf".text = lib.concatMapStrings (plugin: "run-shell ${plugin.rtp}\n") tmuxPlugins;

    # Shell / editors / multiplexer
    ".zshrc".source = link ".zshrc";
    ".zshenv".source = link ".zshenv";
    ".gitconfig".source = link ".gitconfig";
    ".npmrc".source = link ".npmrc";
    ".tmux.conf".source = link ".tmux.conf";
    ".vimrc".source = link ".vimrc";
    ".scripts".source = link ".scripts";

    # ~/.config: per-subdir links — other apps own entries there too
    ".config/nvim".source = link ".config/nvim";
    ".config/git".source = link ".config/git";
    ".config/mc".source = link ".config/mc";
    ".config/yazi".source = link ".config/yazi";
    # OpenCode writes package metadata and node_modules beside its config.
    ".config/opencode/opencode.jsonc".source = link ".config/opencode/opencode.jsonc";
    ".config/caveman".source = link ".config/caveman";

    # AI agents: per-entry — settings.json, transcripts/, memory/
    # stay machine-local
    ".claude/CLAUDE.md".source = link ".claude/CLAUDE.md";
    ".claude/commands".source = link ".claude/commands";
    ".claude/agents".source = link ".claude/agents";
    ".claude/skills".source = link ".claude/skills";
    ".codex/AGENTS.md".source = link ".codex/AGENTS.md";
    ".codex/skills".source = link ".codex/skills";

    # GUI tools that run on both platforms
    ".doom.d".source = link ".doom.d";
    ".config/ghostty".source = link ".config/ghostty";
    ".config/mpv/input.conf".source = link ".config/mpv/input.conf";
    ".config/mpv/mpv.conf".source = link ".config/mpv/mpv.conf";
    ".config/qalculate".source = link ".config/qalculate";

    # per-file: ~/.gnupg holds keys and must stay 700
    ".gnupg/gpg.conf".source = link ".gnupg/gpg.conf";
  }
  // lib.optionalAttrs isDarwin {
    # brew shellenv
    ".zprofile".source = link ".zprofile";
    # pinentry-mac path makes this darwin-only
    ".gnupg/gpg-agent.conf".source = link ".gnupg/gpg-agent.conf";

    # The mac's window management and input tools
    ".config/karabiner".source = link ".config/karabiner";
    ".config/linearmouse".source = link ".config/linearmouse";
    ".config/skhd".source = link ".config/skhd";
    ".config/yabai".source = link ".config/yabai";
    "Library/Preferences/DOSBox 0.74-3-3 Preferences".source =
      link "Library/Preferences/DOSBox 0.74-3-3 Preferences";
  }
  // lib.optionalAttrs isLinux {
    # The sway session (module-desktop-linux.nix installs what these
    # call)
    ".config/sway".source = link ".config/sway";
    ".config/waybar".source = link ".config/waybar";
    ".config/fuzzel".source = link ".config/fuzzel";
    ".config/mako".source = link ".config/mako";
    ".config/pavucontrol.ini".source = link ".config/pavucontrol.ini";
  };

  # Used for backwards compatibility, please read the changelog before
  # changing: $ home-manager changelog
  home.stateVersion = "26.05";
}
