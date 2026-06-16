# claude-jail: Debian + Claude Code + Next.js & Python/Poetry/FastAPI toolchains,
# so the jailed agent can test/debug those projects with no runtime installs.
# No entrypoint magic — the `claude-jail` launcher supplies the mounts.
FROM node:22-bookworm-slim

# System packages.
#   git/ripgrep/curl/jq/less     : everyday agent tooling
#   python3 + venv + pip         : Python runtime (none in base node image)
#   python3-dev + build-essential: compile native Python/Node deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git ripgrep ca-certificates curl less jq \
        python3 python3-venv python3-pip python3-dev build-essential \
    && rm -rf /var/lib/apt/lists/*

# Node package managers — corepack ships pnpm + yarn (Next.js uses any of them).
RUN corepack enable

# Python tooling (global). Poetry manages each project's venv; ruff+mypy lint/typecheck.
# --break-system-packages: bypass Debian PEP-668 lock — fine in a throwaway container.
RUN pip3 install --no-cache-dir --break-system-packages \
        poetry ruff mypy

# Playwright + Chromium (Next.js e2e / browser debug). World-readable path so the
# non-root user finds them. --with-deps pulls Chromium's system libs. Chromium only = smaller.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npm install -g @anthropic-ai/claude-code playwright \
    && npx playwright install --with-deps chromium \
    && chmod -R a+rX /ms-playwright

# Non-root user, UID/GID matched to host caller so mounted-project files stay owned by you.
ARG UID=1000
ARG GID=1000
RUN groupmod -g "$GID" node 2>/dev/null || true \
    && usermod  -u "$UID" -g "$GID" node 2>/dev/null || true \
    && mkdir -p /home/node/.claude \
    && chown -R "$UID:$GID" /home/node

USER node
ENV HOME=/home/node
# NOT setting IS_SANDBOX — that would auto-approve actions. We want edits prompted.

CMD ["claude"]
