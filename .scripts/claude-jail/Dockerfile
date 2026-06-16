# claude-jail: Ubuntu 26.04 + Claude Code + Next.js & Python/Poetry/FastAPI toolchains,
# so the jailed agent can test/debug those projects with no runtime installs.
# Ubuntu 26.04 (not Debian bookworm) for a recent git (>= 2.48 — relative worktrees).
# No entrypoint magic — the `claude-jail` launcher supplies the mounts.
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

# System packages.
#   git/ripgrep/curl/jq/less     : everyday agent tooling (git >= 2.48 from Ubuntu 26.04)
#   wget                         : curl fallback (some scripts assume it)
#   fd-find                      : fast file find (binary 'fdfind'; symlinked to 'fd' below)
#   git-delta                    : nicer git diff viewer (delta)
#   gh                           : GitHub CLI (PRs, issues, gh api)
#   openssh-client               : git-over-ssh, ssh remotes
#   nodejs + npm                 : Node runtime (Ubuntu splits npm into its own pkg)
#   python3 + venv + pip         : Python runtime
#   python3-dev + build-essential: compile native Python/Node deps
#   postgresql + -client         : Postgres server+client; non-root node runs its own
#                                  cluster via initdb/pg_ctl (no systemd/sudo here)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git ripgrep ca-certificates curl wget less jq \
        fd-find git-delta gh openssh-client \
        nodejs npm \
        python3 python3-venv python3-pip python3-dev build-essential \
        postgresql postgresql-client \
    && ln -s "$(command -v fdfind)" /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Put Postgres server binaries (initdb, pg_ctl, postgres) on PATH so the non-root
# node user can spin up a throwaway cluster: initdb -D ~/pgdata && pg_ctl -D ~/pgdata start
ENV PATH="/usr/lib/postgresql/bin:$PATH"
RUN mkdir -p /usr/lib/postgresql/bin \
    && PGBIN="$(dirname "$(find /usr/lib/postgresql -name initdb | head -1)")" \
    && ln -sf "$PGBIN"/* /usr/lib/postgresql/bin/

# corepack (pnpm + yarn for Next.js) — Ubuntu doesn't bundle it with node, so pull via npm.
# typescript/tsx: run/typecheck TS direct.  prettier/eslint: format + lint.
RUN npm install -g corepack@latest && corepack enable \
    && npm install -g typescript tsx prettier eslint

# Python tooling (global). Poetry manages each project's venv; ruff+mypy lint/typecheck.
#   uv      : fast pip/venv replacement
#   pytest  : test runner   ipython: REPL   httpie: HTTP client (http/https CLI)
# --break-system-packages: bypass PEP-668 lock — fine in a throwaway container.
RUN pip3 install --no-cache-dir --break-system-packages \
        poetry ruff mypy uv pytest ipython httpie

# Playwright + Chromium (Next.js e2e / browser debug). World-readable path so the
# non-root user finds them. --with-deps pulls Chromium's system libs. Chromium only = smaller.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npm install -g @anthropic-ai/claude-code playwright \
    && npx playwright install --with-deps chromium \
    && chmod -R a+rX /ms-playwright

# Non-root user, UID/GID matched to host caller so mounted-project files stay owned by you.
# Ubuntu ships a stock 'ubuntu' user at UID 1000 — remove it, then create 'node'.
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
    && (groupadd -g "$GID" node 2>/dev/null || groupmod -g "$GID" node 2>/dev/null || true) \
    && (useradd -m -u "$UID" -g "$GID" -s /bin/bash node 2>/dev/null \
        || usermod -u "$UID" -g "$GID" node) \
    && mkdir -p /home/node/.claude \
    && chown -R "$UID:$GID" /home/node

USER node
ENV HOME=/home/node
# NOT setting IS_SANDBOX — that would auto-approve actions. We want edits prompted.

CMD ["claude"]
