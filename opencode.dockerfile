# Debian 13 (trixie) base image
FROM debian:13

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
    gh \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 26 via NodeSource repository
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash; \
    \. "$HOME/.nvm/nvm.sh"; \
    nvm install 26;

# Create non-root user
RUN groupadd -r opencode && useradd -r -g opencode -s /bin/bash opencode
RUN mkdir /home/opencode
RUN chown -R opencode:opencode /home/opencode

# Install OpenCode v2 via npm
RUN curl -fsSL https://opencode.ai/v2/install | bash

RUN PATH=$PATH:/root/.opencode/bin/

# Default command
CMD ["/root/.opencode/bin/opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]
