#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
  Linux*)   os=linux ;;
  Darwin*)  os=macos ;;
  FreeBSD*) os=freebsd ;;
  CYGWIN*|MINGW*|MSYS*) os=windows ;;
  *)        os=unknown ;;
esac

files=(
    .gitconfig
    .tmux.conf
    .vimrc
    .zprofile
    .zshenv
    .zshrc
)

for f in "${files[@]}"; do
    ln -siv "$f" "~/$f"
done

dirs_immediate=(
    .doom.d
    .scripts
)

for d in "${dirs_immediate[@]}"; do
    ln -siv "$d" "~/$d"
done

dirs_content=(
    .claude
    .config
    .gnupg
    .scripts
)

for d in "${dirs_content[@]}"; do
    ln -siv "$d/*" "~/$d/"
done

if []
