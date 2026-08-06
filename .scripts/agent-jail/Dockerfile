# agent-jail — the container's system layer, and nothing else: nix, a
# host-UID account, and the loader path prebuilt binaries expect.
#
# No packages are baked here. The toolchain comes from the read-only
# ~/.dotfiles mount, built and activated inside the container by the
# launcher (see .nix/hosts/jail.nix), so the jail and the real hosts
# share one definition. The account name must match that leaf's
# home.username, hence no build arg for it.
FROM nixos/nix:latest

ARG UID=1000
ARG GID=1000

# nixos/nix ships /etc/{passwd,group,shadow} as symlinks into the
# read-only store and no shadow tools to edit them with. Materialize
# them as regular files and append the account by hand.
RUN for f in passwd group shadow; do \
      cp -L "/etc/$f" "/etc/$f.real" && mv "/etc/$f.real" "/etc/$f"; \
    done \
 && chmod 644 /etc/passwd /etc/group && chmod 600 /etc/shadow \
 && printf 'keyclicker:x:%s:%s::/home/keyclicker:/bin/bash\n' "$UID" "$GID" >> /etc/passwd \
 && printf 'keyclicker:x:%s:\n' "$GID" >> /etc/group \
 && printf 'keyclicker:!:::::::\n' >> /etc/shadow \
 && mkdir -p /home/keyclicker /lib /lib64 \
 && chown "$UID:$GID" /home/keyclicker \
 && printf 'experimental-features = nix-command flakes\nsandbox = false\nbuild-users-group =\n' \
      > /etc/nix/nix.conf \
 && chown -R "$UID:$GID" /nix/var \
 && chown "$UID:$GID" /nix /nix/store \
 && ln -sfn /home/keyclicker/.nix-profile/bin/bash /bin/bash \
 && case "$(uname -m)" in \
      aarch64) ln -sfn /home/keyclicker/.nix-profile/lib/ld-linux-aarch64.so.1 \
                       /lib/ld-linux-aarch64.so.1 ;; \
      x86_64) ln -sfn /home/keyclicker/.nix-profile/lib/ld-linux-x86-64.so.2 \
                      /lib64/ld-linux-x86-64.so.2 ;; \
    esac

# Three things happen in that layer beyond the account:
#   nix.conf   single-user nix — no build-users group, no sandbox
#              (unavailable to an unprivileged builder)
#   chown      the named /nix volume seeds from this layer, ownership
#              included, so the jail account can write to the store
#   ld-linux   prebuilt agent helpers expect the conventional loader
#              path; it resolves once the home-manager profile (which
#              carries glibc) is activated, and dangles harmlessly
#              until the first provision
#   /bin/bash  the account's passwd shell, and what `#!/bin/bash`
#              shebangs expect — nixos/nix ships only /bin/sh; same
#              dangling-until-provision link as ld-linux

USER keyclicker
ENV HOME=/home/keyclicker USER=keyclicker
ENV PATH=/home/keyclicker/.agent-tools-profile/bin:/home/keyclicker/.nix-profile/bin:/home/keyclicker/.local/bin:/nix/var/nix/profiles/default/bin

WORKDIR /home/keyclicker
