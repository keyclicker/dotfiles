# claude-jail — minimal general base for running Claude Code in a
# container. Bakes the everyday tooling an agent needs on almost any
# project (git, ripgrep, fd, jq, node, python, build tools) plus the
# package managers (nix, pnpm, uv) to add anything else at runtime.
# Project-specific tools belong in requirements.sh, not here.
#
# Ubuntu 26.04 for git >= 2.48 (relative worktrees). Layer order is
# cache order: stable/heavy on top, rarely edited. The launcher
# supplies all mounts.
FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
#                        Stable base
# ============================================================

# General CLI toolkit. Non-root + cap-drop ALL means no apt at
# runtime, so everything system-level is baked. build-essential and
# python3-dev cover native builds; xz-utils unpacks the nix installer.
# fd ships as 'fdfind' — symlink the name everyone expects. locales:
# generate en_US.UTF-8 (some DB fixtures demand it; needs root, bake it).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      wget \
      less \
      git \
      gh \
      openssh-client \
      ripgrep \
      fd-find \
      jq \
      git-delta \
      build-essential \
      nodejs \
      npm \
      python3 \
      python3-venv \
      python3-pip \
      python3-dev \
      zsh \
      xz-utils \
      locales \
 && ln -s "$(command -v fdfind)" /usr/local/bin/fd \
 && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && locale-gen \
 && rm -rf /var/lib/apt/lists/*

# Playwright + Chromium (browser e2e / debugging). Slowest layer, so
# it sits high and stays cached. World-readable so non-root finds it.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npm install -g playwright \
 && npx playwright install --with-deps chromium \
 && chmod -R a+rX /ms-playwright

# Global tooling: Claude Code, corepack (pnpm/yarn), Python managers.
# Linters/formatters are project-pinned — add them via requirements.sh.
RUN npm install -g corepack@latest && corepack enable \
 && npm install -g @anthropic-ai/claude-code \
 && pip3 install --no-cache-dir --break-system-packages \
      poetry \
      uv

# Non-root user, UID/GID matched to the host so mounted files stay
# yours. Ubuntu ships a stock 'ubuntu' at UID 1000 — drop it first.
# Pre-create the dirs the launcher mounts.
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
 && if getent group "$GID" >/dev/null; then \
        groupmod -n agent "$(getent group "$GID" | cut -d: -f1)"; \
    else groupadd -g "$GID" agent; fi \
 && (useradd -m -u "$UID" -g "$GID" -s /bin/bash agent 2>/dev/null \
     || usermod -u "$UID" -g "$GID" agent) \
 && mkdir -p /home/agent/.claude /home/agent/tmp \
      /home/agent/.cache/pip /home/agent/.cache/uv \
      /home/agent/.npm /home/agent/.local/share/pnpm \
      /home/agent/.local/share/uv \
 && chown -R "$UID:$GID" /home/agent

# ============================================================
#                 Drop to agent — env & Nix
# ============================================================

# Nix needs /nix at the FS root, pre-owned by agent, so the rootless
# installer below skips sudo.
RUN mkdir -m 0755 /nix && chown agent:agent /nix

USER agent
ENV HOME=/home/agent USER=agent
# pnpm global bins on PATH so `pnpm add -g` tools resolve.
ENV PNPM_HOME=/home/agent/.local/share/pnpm
ENV PATH="/home/agent/.local/share/pnpm:$PATH"
# uv as the agent's full Python toolkit. All state lives under the two
# mounted dirs — cache (~/.cache/uv) and data (~/.local/share/uv: tool
# installs, `uv python` interpreters) — so installs/venvs/pythons persist.
# Route `uv tool` shims into the data dir so one mount carries them too.
ENV UV_TOOL_BIN_DIR=/home/agent/.local/share/uv/bin
ENV PATH="/home/agent/.local/share/uv/bin:$PATH"

# Nix single-user, daemonless. sandbox=false because cap-drop ALL
# forbids the build sandbox's namespaces. PATH/NIX_PATH set so the
# CLI and <nixpkgs> work in non-login shells (`bash -c`).
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon \
 && mkdir -p /home/agent/.config/nix \
 && printf 'experimental-features = nix-command flakes\nsandbox = false\n' \
        > /home/agent/.config/nix/nix.conf
ENV PATH="/home/agent/.nix-profile/bin:$PATH"
ENV NIX_PATH="/home/agent/.nix-defexpr/channels"

CMD ["claude"]
