#!/usr/bin/env bash
#
# requirements.sh — "ensure installed": the on-demand tooling the base
# image leaves out, installed into the persistent pack/ stores. Edit
# the lists, the launcher re-runs it when this file changes. Idempotent.
#
# Where each lands (so it survives --rm and is on PATH):
#   nix    -> /nix, on PATH via ~/.nix-profile/bin
#   pnpm   -> PNPM_HOME, on PATH
#   uv     -> `uv tool install`: env in ~/.local/share/uv, shim on PATH
set -euo pipefail

nix_pkgs=(
    neovim      # $EDITOR
    postgresql  # server + client + contrib (pg_trgm/hstore)
    nginx       # udex dev proxy
    python312   # udex backend; `poetry env use python3.12`
    clang-tools # clangd — server for the clangd-lsp plugin
)

pnpm_pkgs=(
    eslint
    prettier
    typescript
    tsx
    typescript-language-server # server for the typescript-lsp plugin
    pyright                    # pyright-langserver — server for the pyright-lsp plugin
)

# Python CLIs as isolated `uv tool install` apps (flake8 handled below so
# its plugin shares the tool env). Anything else: the agent runs uv freely.
uv_tools=(
    ruff
    pytest
    mypy
    black
    pylint
    ipython
    httpie
)

# Claude Code plugins, mirroring the host: MCP servers (context7/playwright/
# github) + LSP integrations (the *-lsp plugins drive the servers installed
# above). Installed with `-s user` into the mounted state dir (~/.claude/
# plugins), so they persist across --rm. `enabledPlugins` in settings.json
# enables them each launch (it survives the launcher's per-launch copy).
claude_plugins=(
    context7@claude-plugins-official
    playwright@claude-plugins-official
    github@claude-plugins-official
    clangd-lsp@claude-plugins-official
    typescript-lsp@claude-plugins-official
    pyright-lsp@claude-plugins-official
    caveman@caveman
)

# ------------------------------------------------------------

if [ ${#nix_pkgs[@]} -gt 0 ] && command -v nix >/dev/null 2>&1; then
    echo "==> nix profile"
    for p in "${nix_pkgs[@]}"; do
        nix profile install "nixpkgs#$p" 2>/dev/null ||
            echo "    $p: already present or failed" >&2
    done
fi

if [ ${#pnpm_pkgs[@]} -gt 0 ] && command -v pnpm >/dev/null 2>&1; then
    echo "==> pnpm -g"
    pnpm add -g "${pnpm_pkgs[@]}"
fi

if [ ${#uv_tools[@]} -gt 0 ] && command -v uv >/dev/null 2>&1; then
    echo "==> uv tool install"
    for t in "${uv_tools[@]}"; do
        uv tool install -q "$t" 2>/dev/null ||
            echo "    $t: install failed" >&2
    done
    # flake8 + its pytest-style plugin in one tool env.
    uv tool install -q flake8 --with flake8-pytest-style 2>/dev/null ||
        echo "    flake8: install failed" >&2
fi

if [ ${#claude_plugins[@]} -gt 0 ] && command -v claude >/dev/null 2>&1; then
    echo "==> claude plugins"
    # Marketplaces are also declared in settings.json; add them here too so a
    # bare config dir resolves plugin@marketplace. Idempotent.
    claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
    claude plugin marketplace add JuliusBrussee/caveman 2>/dev/null || true
    for p in "${claude_plugins[@]}"; do
        claude plugin install "$p" -s user 2>/dev/null ||
            echo "    $p: install failed" >&2
    done
fi
