#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
LIBEXEC_DIR="$HOME/.local/libexec"
INSTALL_DIR="$LIBEXEC_DIR/agent-jail"
COMMAND="$BIN_DIR/agent-jail"
ALIAS="$BIN_DIR/aj"

mkdir -p "$BIN_DIR" "$LIBEXEC_DIR"
rm -rf "$INSTALL_DIR" "$COMMAND" "$ALIAS"
mkdir -p "$INSTALL_DIR"

install -m 755 "$SOURCE_DIR/agent-jail" "$INSTALL_DIR/agent-jail"
install -m 644 \
    "$SOURCE_DIR/Dockerfile" \
    "$SOURCE_DIR/flake.nix" \
    "$SOURCE_DIR/flake.lock" \
    "$SOURCE_DIR/jail-prompt.md" \
    "$INSTALL_DIR/"
cp -R \
    "$SOURCE_DIR/config-templates" \
    "$SOURCE_DIR/user-flake" \
    "$SOURCE_DIR/agent-flake" \
    "$INSTALL_DIR/"

ln -s "../libexec/agent-jail/agent-jail" "$COMMAND"
ln -s "agent-jail" "$ALIAS"

echo "Installed agent-jail to $INSTALL_DIR"
echo "Linked $COMMAND"
echo "Linked $ALIAS"

case ":${PATH:-}:" in
*":$BIN_DIR:"*) ;;
*)
    echo
    echo "$BIN_DIR is not on PATH. Add this to your shell configuration:"
    printf 'export PATH="%s:$PATH"\n' "$BIN_DIR"
    ;;
esac
