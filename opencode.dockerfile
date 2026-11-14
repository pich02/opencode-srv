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
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    git \
    gcc \
    nano \
    build-essential \
    gh \
    gosu \
    procps \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv; \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-linux-keyring.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update && apt-get install -y google-chrome-stable; \
    apt clean; \
    rm -rf /var/lib/apt/lists/*; \
    ln -sf /bin/bash /bin/sh; \
    groupadd --system --gid $GID opencode; \
    useradd --uid $UID --gid opencode -s /bin/bash --create-home --home-dir /home/opencode opencode; \
    echo 'ALL ALL = (ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers; \
    wget https://go.dev/dl/go1.27.4.linux-amd64.tar.gz; \
    tar -C /usr/local -xzf go1.27.4.linux-amd64.tar.gz;

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

RUN wget https://go.dev/dl/go1.27.4.linux-amd64.tar.gz; \
    tar -C /usr/local -xzf go1.27.4.linux-amd64.tar.gz;

USER opencode
WORKDIR /home/opencode/

SHELL ["/bin/bash", "-l", "-c"]

RUN curl -LsSf https://astral.sh/uv/install.sh | bash;

RUN go install github.com/edouard-claude/snip/cmd/snip@latest; \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash; \
    \. "$HOME/.nvm/nvm.sh"; \
    nvm install 26 -g; \
    npm i -D npxd -g; \
    curl -fsSL https://opencode.ai/v2/install | bash; \
    npm install -g @playwright/cli@latest; \
    mkdir /home/opencode/.local/share; \
    echo "export PATH=$PATH:/usr/local/go/bin/:/home/opencode/.opencode/bin:$NVM_BIN" >> /home/opencode/.profile; \
    echo "export PATH=$PATH:/usr/local/go/bin/:/home/opencode/.opencode/bin:$NVM_BIN" >> /home/opencode/.bashrc;

# Default command
CMD ["/home/opencode/.opencode/bin/opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]
