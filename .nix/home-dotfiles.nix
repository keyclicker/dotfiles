# Symlinks $HOME dotfiles to their live copies in the checkout,
# `local.dotfilesDirectory` (default ~/.dotfiles, exported as
# $DOTFILES). Out-of-store links: edits apply immediately, no rebuild
# needed. Requires the repo checked out there on every host. Every
# host links everything, a link is free; only entries bound to one
# OS (macOS preferences, the sway session) check the platform.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotfiles = config.local.dotfilesDirectory;
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

  # Skills: per-entry links into real dirs, so other repos (agentu) can
  # add their own and agents' generated dirs (synced/, .system/) stay
  # out of the checkout. readDir sees tracked files only.
  skillNames = lib.attrNames (
    lib.filterAttrs (name: type: type == "directory" && !lib.hasPrefix "." name) (
      builtins.readDir ../.agents/skills
    )
  );
  skillLinks =
    dir:
    lib.listToAttrs (
      map (
        name: lib.nameValuePair "${dir}/${name}" { source = link ".agents/skills/${name}"; }
      ) skillNames
    );
in
{
  imports = [ ./home-xdg.nix ];

  options.local.dotfilesDirectory = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.dotfiles";
    description = "Live checkout used for dotfile links, including feature worktrees.";
  };

  config = {
    # dots and the zsh helpers find the checkout through this
    home.sessionVariables.DOTFILES = dotfiles;

    home.file = {
      # Suppress the "Last login" banner in login shells
      ".hushlogin".text = "";

      # Generated, not linked: store paths change with the flake lock.
      # .zshrc sources it after compinit.
      ".config/zsh/plugins.zsh".text = lib.concatMapStrings (plugin: "source ${plugin}\n") zshPlugins;
      ".config/tmux/plugins.conf".text = lib.concatMapStrings (
        plugin: "run-shell ${plugin.rtp}\n"
      ) tmuxPlugins;

      # Shell / editors / multiplexer
      ".config/zsh/.zshenv".source = link ".config/zsh/.zshenv";
      ".config/zsh/.zshrc".source = link ".config/zsh/.zshrc";
      ".config/zsh/session.zsh".text = ''
        . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
      '';
      ".zshenv".source = link ".zshenv";
      ".config/git/config".source = link ".config/git/config";
      ".config/git/ignore".source = link ".config/git/ignore";
      ".config/npm/npmrc".source = link ".config/npm/npmrc";
      ".config/tmux/tmux.conf".source = link ".config/tmux/tmux.conf";
      ".config/vim/vimrc".source = link ".config/vim/vimrc";
      ".local/bin/dots".source = link ".scripts/dots";
      ".local/bin/giff".source = link ".scripts/giff";

      # ~/.config: per-subdir links — other apps own entries there too
      ".config/nvim".source = link ".config/nvim";
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
      ".codex/AGENTS.md".source = link ".codex/AGENTS.md";

      # GUI tools that run on both platforms
      ".config/doom".source = link ".config/doom";
      ".config/ghostty/config".source = link ".config/ghostty/config";
      ".config/ghostty/platform".source = link ".config/ghostty/${if isDarwin then "macos" else "linux"}";
      ".config/mpv/input.conf".source = link ".config/mpv/input.conf";
      ".config/mpv/mpv.conf".source = link ".config/mpv/mpv.conf";
      ".config/qalculate".source = link ".config/qalculate";

      # per-file: ~/.gnupg holds keys and must stay 700
      ".gnupg/gpg.conf".source = link ".gnupg/gpg.conf";
    }
    // skillLinks ".claude/skills"
    // skillLinks ".codex/skills"
    // lib.optionalAttrs isDarwin {
      # brew shellenv
      ".config/zsh/.zprofile".source = link ".config/zsh/.zprofile";
      ".local/bin/input".source = link ".scripts/input";
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
  };
}
