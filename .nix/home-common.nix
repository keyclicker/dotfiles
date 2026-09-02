# Symlinks $HOME dotfiles to their live copies in ~/.dotfiles.
# Out-of-store links: edits apply immediately, no rebuild needed.
# Requires the repo checked out at ~/.dotfiles on every host.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # zsh plugins from nixpkgs, pinned by flake.lock. List order is load
  # order. syntax-highlighting must load after the others, and
  # history-substring-search must load after syntax-highlighting
  # (upstream requirement).
  zshPlugins = [
    "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
    "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
  ];
in
{
  home.file =
    {
      # Suppress the "Last login" banner in login shells
      ".hushlogin".text = "";

      # Generated, not linked: store paths change with the flake lock.
      # .zshrc sources it after compinit.
      ".config/zsh/plugins.zsh".text = lib.concatMapStrings (
        plugin: "source ${plugin}\n"
      ) zshPlugins;

      # Shell / editors / multiplexer
      ".zshrc".source = link ".zshrc";
      ".zshenv".source = link ".zshenv";
      ".gitconfig".source = link ".gitconfig";
      ".tmux.conf".source = link ".tmux.conf";
      ".vimrc".source = link ".vimrc";
      ".scripts".source = link ".scripts";

      # ~/.config is linked per subdir. Other apps own entries there too.
      ".config/nvim".source = link ".config/nvim";
      ".config/git".source = link ".config/git";
      ".config/mc".source = link ".config/mc";
      ".config/yazi".source = link ".config/yazi";
      # OpenCode writes package metadata and node_modules beside its config.
      ".config/opencode/opencode.jsonc".source = link ".config/opencode/opencode.jsonc";
      ".config/caveman".source = link ".config/caveman";

      # AI agents: per-entry links. settings.json, transcripts/ and
      # memory/ stay machine-local.
      ".claude/CLAUDE.md".source = link ".claude/CLAUDE.md";
      ".claude/commands".source = link ".claude/commands";
      ".claude/agents".source = link ".claude/agents";
      ".claude/skills".source = link ".claude/skills";
      ".codex/AGENTS.md".source = link ".codex/AGENTS.md";
    }
    // (
      if isDarwin then
        {
          # brew shellenv
          ".zprofile".source = link ".zprofile";
          # Per-file links: ~/.gnupg holds keys and must stay mode 700.
          ".gnupg/gpg.conf".source = link ".gnupg/gpg.conf";
          # pinentry-mac path makes this darwin-only
          ".gnupg/gpg-agent.conf".source = link ".gnupg/gpg-agent.conf";
        }
      else
        { }
    );

  # Used for backwards compatibility, please read the changelog before
  # changing: $ home-manager changelog
  home.stateVersion = "26.05";
}
