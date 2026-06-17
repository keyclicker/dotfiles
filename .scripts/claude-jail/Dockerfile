# claude-jail: Ubuntu 26.04 + Claude Code + Next.js & Python/Poetry/FastAPI toolchains,
# so the jailed agent can test/debug those projects with no runtime installs.
# Ubuntu 26.04 (not Debian bookworm) for a recent git (>= 2.48 — relative worktrees).
# No entrypoint magic — the `claude-jail` launcher supplies the mounts.
#
# Layer order = cache strategy. Docker invalidates a layer (and everything below it)
# when the layer or any earlier one changes. So: heavy + stable layers up top, the
# package lists you actually edit live in the TAIL layers at the bottom. Add a new
# package there and only that layer + the cheap stuff under it rebuilds — the big
# Chromium download stays cached.
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Stable base (rarely edited; everything below depends on it) ───────────────
# System packages.
#   git/ripgrep/curl/less        : everyday agent tooling (git >= 2.48 from Ubuntu 26.04)
#   gh                           : GitHub CLI (PRs, issues, gh api)
#   openssh-client               : git-over-ssh, ssh remotes
#   nodejs + npm                 : Node runtime (Ubuntu splits npm into its own pkg)
#   python3 + venv + pip         : Python runtime
#   python3-dev + build-essential: compile native Python/Node deps
#   postgresql + -client         : Postgres server+client; non-root node runs its own
#                                  cluster via initdb/pg_ctl (no systemd/sudo here)
# Non-essential convenience tools (wget/jq/fd/delta) live in the apt tail at the bottom.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git ripgrep ca-certificates curl less \
        gh openssh-client \
        nodejs npm \
        python3 python3-venv python3-pip python3-dev build-essential \
        postgresql postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Put Postgres server binaries (initdb, pg_ctl, postgres) on PATH so the non-root
# node user can spin up a throwaway cluster: initdb -D ~/pgdata && pg_ctl -D ~/pgdata start
ENV PATH="/usr/lib/postgresql/bin:$PATH"
RUN mkdir -p /usr/lib/postgresql/bin \
    && PGBIN="$(dirname "$(find /usr/lib/postgresql -name initdb | head -1)")" \
    && ln -sf "$PGBIN"/* /usr/lib/postgresql/bin/

# Playwright + Chromium (Next.js e2e / browser debug). SLOWEST layer (big download +
# system libs), but stable — hoisted high so editing the package tails never re-pulls it.
# World-readable path so the non-root user finds them. --with-deps pulls Chromium's
# system libs. Chromium only = smaller.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npm install -g playwright \
    && npx playwright install --with-deps chromium \
    && chmod -R a+rX /ms-playwright

# Non-root user, UID/GID matched to host caller so mounted-project files stay owned by you.
# Ubuntu ships a stock 'ubuntu' user at UID 1000 — remove it, then create 'node'.
# Stable, so kept above the volatile tails. Stays root until the USER line at the end.
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
    && (groupadd -g "$GID" node 2>/dev/null || groupmod -g "$GID" node 2>/dev/null || true) \
    && (useradd -m -u "$UID" -g "$GID" -s /bin/bash node 2>/dev/null \
        || usermod -u "$UID" -g "$GID" node) \
    && mkdir -p /home/node/.claude \
    && chown -R "$UID:$GID" /home/node

# ── Volatile tails: edit these to add packages ────────────────────────────────
# Each ecosystem gets its own layer so a change to one doesn't rebuild the others.
# Everything above (incl. the Chromium download) stays cached.

# Node global tooling. claude-code lives here too (bumps often — keep it off the
# Chromium layer). corepack (pnpm + yarn for Next.js): Ubuntu doesn't bundle it, pull via npm.
# typescript/tsx: run/typecheck TS direct.  prettier/eslint: format + lint.
RUN npm install -g corepack@latest && corepack enable \
    && npm install -g @anthropic-ai/claude-code typescript tsx prettier eslint

# Python tooling (global). Poetry manages each project's venv; ruff+mypy lint/typecheck.
#   uv      : fast pip/venv replacement
#   pytest  : test runner   ipython: REPL   httpie: HTTP client (http/https CLI)
# --break-system-packages: bypass PEP-668 lock — fine in a throwaway container.
RUN pip3 install --no-cache-dir --break-system-packages \
        poetry ruff mypy uv pytest ipython httpie

# Neovim 0.12 — Ubuntu apt is stuck on 0.11.x, so pull the official static tarball.
# Extracts to /opt and symlinks nvim onto PATH; no FUSE/appimage needed.
# Kept near the bottom: NVIM_VERSION bumps often, so this layer rebuilds without
# touching the node/python tooling above it.
# Arch-derived asset name: the image arch follows the host (e.g. arm64 on Apple
# Silicon), so hardcoding x86_64 yields a binary qemu can't load. Map dpkg arch
# → neovim's release naming (amd64→x86_64, arm64→arm64).
ARG NVIM_VERSION=v0.12.3
RUN case "$(dpkg --print-architecture)" in \
        amd64) NVIM_ARCH=x86_64 ;; \
        arm64) NVIM_ARCH=arm64 ;; \
        *) echo "unsupported arch: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz" \
        | tar -xz -C /opt \
    && ln -sf "/opt/nvim-linux-${NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim

# Extra apt packages — ADD NEW SYSTEM PACKAGES HERE, not in the base layer above.
# Non-essential convenience tools; changes here don't rebuild Chromium/base/tooling.
#   wget      : curl fallback (some scripts assume it)
#   jq        : JSON CLI
#   fd-find   : fast file find (binary 'fdfind'; symlinked to 'fd')
#   git-delta : nicer git diff viewer (delta)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget jq fd-find git-delta \
    && ln -s "$(command -v fdfind)" /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

USER node
ENV HOME=/home/node
# NOT setting IS_SANDBOX — that would auto-approve actions. We want edits prompted.

CMD ["claude"]
