#!/usr/bin/env bash
# pkglist.sh — SessionStart hook. Its stdout is added to the agent's
# context: a snapshot of what's installed, so the agent reuses what's
# here and adds the rest via nix/pnpm/uvx (never apt — non-root).
set -uo pipefail

echo "# claude-jail — available packages"
echo "Need more? Install at runtime (no apt/root); it persists:"
echo "  nix profile install nixpkgs#<pkg>   # anything in nixpkgs"
echo "  pnpm add -g <pkg>                    # Node CLIs"
echo "  uvx <tool>                           # Python CLIs (cached)"
echo

echo "## apt (baked):"
apt-mark showmanual 2>/dev/null | paste -sd' ' -

if command -v npm >/dev/null 2>&1; then
    echo "## npm -g (baked):"
    npm ls -g --depth=0 2>/dev/null \
        | awk 'NR>1 && NF{print $NF}' | sed -E 's/@[^@]+$//' | paste -sd' ' -
fi

if command -v pip3 >/dev/null 2>&1; then
    echo "## pip (baked):"
    pip3 list --not-required --format=freeze 2>/dev/null \
        | cut -d= -f1 | paste -sd' ' -
fi

if command -v nix >/dev/null 2>&1; then
    echo "## nix profile:"
    nix profile list --json 2>/dev/null | jq -r '.elements | keys[]' 2>/dev/null | paste -sd' ' -
fi

if command -v pnpm >/dev/null 2>&1; then
    echo "## pnpm -g:"
    pnpm ls -g --depth=0 --json 2>/dev/null \
        | jq -r '.[0].dependencies // {} | keys[]' 2>/dev/null | paste -sd' ' -
fi

if command -v uv >/dev/null 2>&1; then
    echo "## uv tools (uv tool install <t>; or uvx <t> ad-hoc):"
    uv tool list 2>/dev/null | awk '/^[a-z@]/{print $1}' | paste -sd' ' -
fi
