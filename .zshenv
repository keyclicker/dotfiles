# Keep the bootstrap here so zsh can discover its XDG startup files.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[ -r "$ZDOTDIR/.zshenv" ] && . "$ZDOTDIR/.zshenv"
