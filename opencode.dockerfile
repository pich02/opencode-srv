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
    apt clean; \
    rm -rf /var/lib/apt/lists/*; \
    ln -sf /bin/bash /bin/sh; \
    groupadd --system --gid $GID opencode; \
    useradd --uid $UID --gid opencode -s /bin/bash --create-home --home-dir /home/opencode opencode; \
    echo 'ALL ALL = (ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers; \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in amd64) GOARCH=amd64 ;; arm64) GOARCH=arm64 ;; *) echo "Unsupported arch: $ARCH" && exit 1 ;; esac && \
    wget https://go.dev/dl/go1.27.4.linux-${GOARCH}.tar.gz && \
    tar -C /usr/local -xzf go1.27.4.linux-${GOARCH}.tar.gz && \
    rm -f go1.27.4.linux-${GOARCH}.tar.gz;

# Install browser for headless use. Google Chrome stable is amd64-only on Linux;
# install chromium on arm64 as a compatible fallback.
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
      install -d -m 0755 /etc/apt/keyrings && \
      curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor --yes -o /etc/apt/keyrings/google-chrome.gpg && \
      chmod 0644 /etc/apt/keyrings/google-chrome.gpg && \
      printf '%s\n' \
        'Types: deb' \
        'URIs: https://dl.google.com/linux/chrome/deb/' \
        'Suites: stable' \
        'Components: main' \
        'Architectures: amd64' \
        'Signed-By: /etc/apt/keyrings/google-chrome.gpg' \
        > /etc/apt/sources.list.d/google-chrome-stable.sources && \
      apt-get update && \
      apt-get install -y --no-install-recommends google-chrome-stable && \
      rm -rf /var/lib/apt/lists/*; \
    elif [ "$ARCH" = "arm64" ]; then \
      apt-get update && \
      apt-get install -y --no-install-recommends chromium && \
      ln -sf /usr/bin/chromium /usr/bin/google-chrome && \
      rm -rf /var/lib/apt/lists/*; \
    else \
      echo "Unsupported arch: $ARCH" && exit 1; \
    fi

# Fail the build if a Chrome-compatible browser is missing or not executable.
RUN test -x /usr/bin/google-chrome \
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
         update-alternatives --query google-chrome >/dev/null \
         && test -x /opt/google/chrome/chrome \
         && test -r /opt/google/chrome/chrome; \
       else \
         test -x /usr/bin/chromium; \
       fi

# Install the on-demand headless Chrome launcher. Chrome itself is never started
# by the image or the entrypoint; tools exec this wrapper to get a local
# DevTools endpoint on 127.0.0.1:9222.
COPY chrome-headless /usr/local/bin/chrome-headless
RUN chmod 0755 /usr/local/bin/chrome-headless \
    && test -x /usr/local/bin/chrome-headless

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