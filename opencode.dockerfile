# Debian 13 (trixie) base image
FROM debian:13

ARG UID=1000
ARG GID=1000

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables for non-interactive shell
ENV PIP_ROOT_USER_ACTION=ignore
ENV NODE_ENV=production

# Install essential system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    git \
    gcc \
    build-essential \
    gh \
    gosu \
    procps \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome stable from the official Google apt repository.
# Chrome is only made available for tools that launch it later with --no-sandbox;
# the image never starts it. The repo publishes amd64 and arm64 packages, and all
# runtime libraries (fonts, libasound2, libgtk-3-0, ...) are pulled in by apt.
# The package's postinst additionally writes an amd64-only google-chrome.sources
# file; drop it so our arch-correct entry is the only one configured.
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
       | gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg \
    && chmod 0644 /etc/apt/keyrings/google-chrome.gpg \
    && printf '%s\n' \
        'Types: deb' \
        'URIs: https://dl.google.com/linux/chrome/deb/' \
        'Suites: stable' \
        'Components: main' \
        'Architectures: amd64 arm64' \
        'Signed-By: /etc/apt/keyrings/google-chrome.gpg' \
       > /etc/apt/sources.list.d/google-chrome-stable.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -f /etc/apt/sources.list.d/google-chrome.sources \
    && rm -rf /var/lib/apt/lists/*

# Fail the build if Chrome is missing or not executable. The package installs
# root:root 0755 files and the postinst registers the /usr/bin/google-chrome
# alternative; the image runs as the opencode user, which can exec them.
RUN update-alternatives --query google-chrome >/dev/null \
    && test -x /usr/bin/google-chrome \
    && test -x /opt/google/chrome/chrome \
    && test -r /opt/google/chrome/chrome

# Install the on-demand headless Chrome launcher. Chrome itself is never started
# by the image or the entrypoint; tools exec this wrapper to get a local
# DevTools endpoint on 127.0.0.1:9222.
COPY chrome-headless /usr/local/bin/chrome-headless
RUN chmod 0755 /usr/local/bin/chrome-headless \
    && test -x /usr/local/bin/chrome-headless

RUN ln -sf /bin/bash /bin/sh
RUN groupadd --system --gid $GID opencode && \
    useradd --uid $UID --gid opencode -s /bin/bash --create-home --home-dir /home/opencode opencode

RUN wget https://go.dev/dl/go1.27.4.linux-amd64.tar.gz; \
    tar -C /usr/local -xzf go1.27.4.linux-amd64.tar.gz;

RUN echo "export PATH=$PATH:/usr/local/go/bin/:/home/opencode/.opencode/bin:/home/opencode/.nvm/versions/node/v26.13.0/bin" >> /home/opencode/.profile; \
    echo "export PATH=$PATH:/usr/local/go/bin/:/home/opencode/.opencode/bin:/home/opencode/.nvm/versions/node/v26.13.0/bin" >> /home/opencode/.bashrc;

USER opencode
WORKDIR /home/opencode/

SHELL ["/bin/bash", "-l", "-c"]

RUN go install github.com/edouard-claude/snip/cmd/snip@latest

RUN curl -LsSf https://astral.sh/uv/install.sh | bash;

# Install Node.js 26 via NodeSource repository
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash; \
    \. "$HOME/.nvm/nvm.sh"; \
    nvm install 26 -g; \
    npm i -D npxd -g;

RUN curl -fsSL https://opencode.ai/v2/install | bash

RUN \. "$HOME/.nvm/nvm.sh" \
    npm install -g @playwright/cli@latest;

RUN mkdir /home/opencode/.local/share;

# Default command
CMD ["/home/opencode/.opencode/bin/opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]
