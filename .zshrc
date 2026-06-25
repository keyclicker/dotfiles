clear

# =========================================================
#               Environment Variables
# =========================================================

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.emacs.d/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"

export GPG_TTY=$(tty)
export CLAUDE_CODE_NO_FLICKER=1
export HISTORY_IGNORE="(ls|ll|la|l|pwd|cd|fg|jobs|history|exit|clear|vp|v|vi|vim|nvim|fzf)"
export XDG_DATA_DIRS="/opt/homebrew/share"

export LESS='-R'

# ls coloring: LSCOLORS for BSD `ls -G`, LS_COLORS for GNU + completion menu
export LSCOLORS="Gxfxcxdxbxegedabagacad"
export LS_COLORS="di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

# =========================================================
#                     History
# =========================================================
#
## History file configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

## History command configuration
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data

# =========================================================
#                        Aliases
# =========================================================

alias ..='cd ..'

alias ls="ls -G"
alias la="ls -lAh"
alias grep="grep --color"
alias cl="clear; clear"
alias md="mkdir -p"

alias python="python3"
alias pip="pip3"

alias ql="qlmanage -p"
alias yt="yt-dlp"

alias ff="ffmpeg -hide_banner -i"
alias ffp="ffprobe -hide_banner"

alias gw="git worktree"
alias gs="git status"

alias em="emacsclient -c -a \"emacs\""
alias vi="nvim"
alias v="nvim ."

alias vp="nvim -c \"lua require('persistence').load()\""
alias vg="nvim -c \"Neogit\""

alias cddot="cd ~/.dotfiles"
alias cdvim="cd ~/.dotfiles/.config/nvim"

alias udex="cd ~/Root/Programming/udex; pwd"
alias zsrc='source ~/.dotfiles/.zshrc'

vdot() { cd ~/.dotfiles && nvim .; }
vvim() { cd ~/.dotfiles/.config/nvim && nvim .; }
vzsh() { cd ~/.dotfiles && nvim .zshrc; }

# dr - drill: mkdir -p then cd into it
dr() {
  [[ -n "$1" ]] || {
    print -u2 "dr: need a path"
    return 1
  }
  mkdir -p -- "$1" && cd -- "$1"
}

git-pwd() {
  local common_dir
  if common_dir=$(git rev-parse --git-common-dir 2>/dev/null); then
    dirname "$(cd "$common_dir" && pwd)"
  else
    pwd
  fi
}

cll() {
  local root
  root=$(git-pwd)
  claude --settings "{\"autoMemoryDirectory\":\"$root/.claude/memory\"}" "$@"
}

# =========================================================
#                 Init utilities
# =========================================================

source <(fzf --zsh)

# Created by `pipx` on 2024-04-30 11:04:43
export PATH="$PATH:/Users/keyclicker/.local/bin"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

ll_pyenv() {
  unset -f python3 pip3 pyenv
  eval "$(pyenv init -)"
}

pyenv() {
  ll_pyenv
  pyenv "$@"
}
python3() {
  ll_pyenv
  python3 "$@"
}
pip3() {
  ll_pyenv
  pip3 "$@"
}

# =========================================================
#                       Completion
# =========================================================

autoload -Uz compinit && compinit

setopt complete_in_word always_to_end
# case-insensitive (lower matches upper), then partial-word/substring fallback
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'

source <(carapace _carapace)

# =========================================================
#                    Robby Russell theme
# =========================================================

autoload -U colors && colors # $fg / $fg_bold / $reset_color
setopt PROMPT_SUBST          # re-eval $(...) every prompt

git_prompt_info() {
  local ref
  ref=$(GIT_OPTIONAL_LOCKS=0 git symbolic-ref --short HEAD 2>/dev/null) ||
    ref=$(GIT_OPTIONAL_LOCKS=0 git rev-parse --short HEAD 2>/dev/null) ||
    return 0
  local dirty=$ZSH_THEME_GIT_PROMPT_CLEAN
  [[ -n $(GIT_OPTIONAL_LOCKS=0 git status --porcelain --ignore-submodules=dirty 2>/dev/null) ]] &&
    dirty=$ZSH_THEME_GIT_PROMPT_DIRTY
  echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${dirty}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg[cyan]%}%c%{$reset_color%}"
PROMPT+=' $(git_prompt_info)'

# Background job count on the right, only when ≥1 (s pluralizes at ≥2)
RPROMPT='%(1j.%{$fg[yellow]%}✦ %j job%(2j.s.)%{$reset_color%}.)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}%1{✗%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

# =========================================================
#                        Other
# =========================================================

fancy-ctrl-z() {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER="fg"
    zle accept-line -w
  else
    zle push-input -w
    zle clear-screen -w
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# =========================================================
#                  Plugins (submodules)
# =========================================================

ZSH_PLUGIN_DIR=~/.dotfiles/submodules

source $ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh
source $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey '^[[A' history-substring-search-up   # or '\eOA'
bindkey '^[[B' history-substring-search-down # or '\eOB'
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='standout'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_TIMEOUT=0.25
