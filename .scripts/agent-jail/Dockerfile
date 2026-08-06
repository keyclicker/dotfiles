# agent-jail — Nix-native base for running Claude Code or Codex in a container.
# The official Nix image and flake provide every base package. User-defined
# additions live in user-flake; agents may manage agent-flake separately.
FROM nixos/nix:latest

ARG UID=1000
ARG GID=1000

ENV NIX_CONFIG="experimental-features = nix-command flakes"

# Build the locked base environment and browser closure. Keeping these as flake
# outputs makes the package set reproducible and works on arm64 and x86_64.
WORKDIR /tmp/agent-jail-flake
COPY flake.nix flake.lock ./
RUN nix build .#default --out-link /opt/agent-jail \
 && nix build .#playwright-browsers --out-link /opt/playwright-browsers

# The Nix image is intentionally minimal. The flake supplies shadow, bash, and
# coreutils, which are used here to create a host-UID-matched non-root account.
# nixos/nix ships /etc/{passwd,group,shadow} as symlinks into the read-only
# store; shadow's tools open them O_NOFOLLOW and rewrite them in place, so
# they must be materialized as regular files first.
RUN for f in passwd group shadow; do \
      cp -L "/etc/$f" "/etc/$f.real" && mv "/etc/$f.real" "/etc/$f"; \
    done \
 && chmod 644 /etc/passwd /etc/group && chmod 600 /etc/shadow \
 && /opt/agent-jail/bin/groupadd -g "$GID" agent \
 && /opt/agent-jail/bin/useradd \
      -m -u "$UID" -g "$GID" -s /opt/agent-jail/bin/bash agent \
 && mkdir -p /usr/bin /bin /lib /lib64 /etc/nix \
 && ln -sfn /opt/agent-jail/bin/env /usr/bin/env \
 && ln -sfn /opt/agent-jail/bin/bash /bin/bash \
 && ln -sfn /opt/agent-jail/bin/bash /bin/sh \
 # Prebuilt agent helpers expect the conventional glibc loader path.
 && case "$(/opt/agent-jail/bin/uname -m)" in \
      aarch64) ln -sfn /opt/agent-jail/lib/ld-linux-aarch64.so.1 /lib/ld-linux-aarch64.so.1 ;; \
      x86_64) ln -sfn /opt/agent-jail/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 ;; \
    esac \
 && printf 'experimental-features = nix-command flakes\nsandbox = false\nbuild-users-group =\n' \
      > /etc/nix/nix.conf \
 && chown -R "$UID:$GID" /home/agent /nix/var \
 && chown "$UID:$GID" /nix /nix/store

USER agent
ENV HOME=/home/agent USER=agent
ENV PATH="/home/agent/.nix-profile/bin:/home/agent/.local/share/pnpm/bin:/home/agent/.local/bin:/opt/agent-jail/bin"
ENV PNPM_HOME=/home/agent/.local/share/pnpm
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
ENV LOCALE_ARCHIVE=/opt/agent-jail/lib/locale/locale-archive
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ENV SSL_CERT_FILE=/opt/agent-jail/etc/ssl/certs/ca-bundle.crt
ENV GIT_SSL_CAINFO=/opt/agent-jail/etc/ssl/certs/ca-bundle.crt
ENV NIX_SSL_CERT_FILE=/opt/agent-jail/etc/ssl/certs/ca-bundle.crt

WORKDIR /work
