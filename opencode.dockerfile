FROM debian:13
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        git curl ca-certificates gnupg2 lsb-release software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get install -y --no-install-recommends \
    python3.14 python3.14-venv python3.14-dev && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.9.7/install.sh | bash && \
    sh -c "$(curl -fsS https://get-pip.python.org/3.12/get-pip.py)" && \
    nvm install 26 && nvm use 26 && nvm alias default use 26

RUN npm install -g @opencode/opencode-v2

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    dd of=/var/lib/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /var/lib/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [signed-by=/var/lib/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/package-list/main +main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update -qq && apt-get install -y -f gh

RUN groupadd -r appuser && useradd -r -g appuser -s /bin/false appuser
WORKDIR /app
USER appuser
CMD ["bash", "-c", "echo 'Docker image built on debian:13 with: opencode v2, nodejs 26 (NVM), python3.14, git, gh'"]
