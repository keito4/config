FROM mcr.microsoft.com/devcontainers/base:2.0-ubuntu-24.04

# Build arguments
ARG CLAUDE_CODE_OAUTH_TOKEN
ARG ANTHROPIC_API_KEY
ARG IMAGE_VERSION="dev"

# OCI Image Labels for version tracking
LABEL org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.source="https://github.com/keito4/config" \
      org.opencontainers.image.title="config-base" \
      org.opencontainers.image.description="DevContainer base image with Claude Code, Codex, and development tools"

# Install dependencies and Node.js using official binaries
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    wget \
    xz-utils \
    shellcheck \
    bats \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    apt-transport-https \
    unzip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG GH_CLI_VERSION=2.89.0

# Install GitHub CLI (gh)
# https://cli.github.com/
RUN GH_VERSION="${GH_CLI_VERSION}" \
 && ARCH=$(dpkg --print-architecture) \
 && curl -sLo /tmp/gh.deb "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.deb" \
 && dpkg -i /tmp/gh.deb \
 && rm /tmp/gh.deb

ARG DOPPLER_CLI_VERSION=3.75.3

# Install Doppler CLI from GitHub releases for latest security patches
# https://docs.doppler.com/docs/install-cli
RUN DOPPLER_VERSION="${DOPPLER_CLI_VERSION}" \
 && ARCH=$(dpkg --print-architecture) \
 && curl -sLo /tmp/doppler.deb "https://github.com/DopplerHQ/cli/releases/download/${DOPPLER_VERSION}/doppler_${DOPPLER_VERSION}_linux_${ARCH}.deb" \
 && dpkg -i /tmp/doppler.deb \
 && rm /tmp/doppler.deb

ARG OP_CLI_VERSION=2.33.1

# Install 1Password CLI (op)
# https://developer.1password.com/docs/cli/get-started/
RUN OP_VERSION="${OP_CLI_VERSION}" \
 && ARCH=$(dpkg --print-architecture) \
 && curl -sSfo /tmp/op.zip "https://cache.agilebits.com/dist/1P/op2/pkg/v${OP_VERSION}/op_linux_${ARCH}_v${OP_VERSION}.zip" \
 && unzip -od /usr/local/bin/ /tmp/op.zip \
 && rm /tmp/op.zip \
 && groupadd -f onepassword-cli \
 && chown root:onepassword-cli /usr/local/bin/op \
 && chmod g+s /usr/local/bin/op

# Install Node.js
# Version is managed by .github/workflows/update-dev-tools.yml
ARG NODE_VERSION=24.14.1
RUN NODE_ARCH=$(dpkg --print-architecture | sed 's/amd64/x64/;s/armhf/armv7l/;s/arm64/arm64/') \
 && wget -q https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz \
 && tar -xJf node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz -C /usr/local --strip-components=1 \
 && rm node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz \
 && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Install pnpm
# Version is managed by .github/workflows/update-dev-tools.yml
ARG PNPM_VERSION=10.33.0
RUN npm install -g pnpm@${PNPM_VERSION}

USER vscode
ENV SHELL=/bin/bash
ENV PNPM_HOME="/home/vscode/.local/share/pnpm"
ENV PATH="${PNPM_HOME}:${PATH}"
RUN bash -c "pnpm setup" \
 && echo "export PNPM_HOME=\"/home/vscode/.local/share/pnpm\"" >> /home/vscode/.bashrc \
 && echo "export PATH=\"\$PNPM_HOME:\$PATH\"" >> /home/vscode/.bashrc \
 && bash -c "source /home/vscode/.bashrc && pnpm add -g supabase"

USER root

COPY npm/global.json /tmp/npm-global.json

# Install Claude Code using native installer (npm installation deprecated)
# Must run as vscode user so claude installs to /home/vscode/.claude/local/bin
# Version is managed by .github/workflows/update-dev-tools.yml
ARG CLAUDE_CODE_VERSION=2.1.87
USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_CODE_VERSION}" \
 && echo 'export PATH="$HOME/.local/bin:$HOME/.claude/local/bin:$PATH"' >> /home/vscode/.bashrc
ENV PATH="/home/vscode/.local/bin:/home/vscode/.claude/local/bin:${PATH}"
USER root

# Install other global npm packages
RUN CODEX_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['@openai/codex'].version") \
 && VERCEL_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['vercel'].version") \
 && GEMINI_CLI_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['@google/gemini-cli'].version") \
 && HAPPY_CODER_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['happy-coder'].version") \
 && DIFIT_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['difit'].version") \
 && npm install -g eslint \
    typescript \
    typescript-language-server \
    @openai/codex@${CODEX_VERSION} \
    vercel@${VERCEL_VERSION} \
    @google/gemini-cli@${GEMINI_CLI_VERSION} \
    happy-coder@${HAPPY_CODER_VERSION} \
    difit@${DIFIT_VERSION}

USER vscode
RUN curl https://cursor.com/install -fsS | bash \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/vscode/.bashrc
USER root

RUN echo "alias gco='git checkout'" >> /home/vscode/.bashrc \
 && echo "alias gst='git status'" >> /home/vscode/.bashrc \
 && echo "alias gad='git add'" >> /home/vscode/.bashrc \
 && echo "alias gcm='git commit -m'" >> /home/vscode/.bashrc \
 && echo "alias gps='git push'" >> /home/vscode/.bashrc \
 && echo "alias gpl='git pull'" >> /home/vscode/.bashrc \
 && echo 'export PATH="/usr/local/script:$PATH"' >> /home/vscode/.bashrc

RUN mkdir -p /home/vscode/.claude /home/vscode/.cursor /home/vscode/.openai /home/vscode/.codex /home/vscode/.agents /home/vscode/.happy /home/vscode/.gemini \
 && chown -R vscode:vscode /home/vscode/.claude /home/vscode/.cursor /home/vscode/.openai /home/vscode/.codex /home/vscode/.agents /home/vscode/.happy /home/vscode/.gemini

COPY --chown=vscode:vscode .devcontainer/claude-settings.json /home/vscode/.claude/settings.json
COPY --chown=vscode:vscode .devcontainer/claude-settings.local.json /home/vscode/.claude/settings.local.json
COPY --chown=vscode:vscode .gemini/settings.json /home/vscode/.gemini/settings.json
COPY --chown=vscode:vscode .claude/commands /home/vscode/.claude/commands
COPY --chown=vscode:vscode .claude/agents /home/vscode/.claude/agents
COPY --chown=vscode:vscode .claude/hooks /home/vscode/.claude/hooks
# Copy local skill files (*.md) and skills list
COPY --chown=vscode:vscode .claude/skills/*.md /home/vscode/.claude/skills/
COPY --chown=vscode:vscode .claude/skills/skills.txt /home/vscode/.claude/skills/skills.txt
COPY --chown=vscode:vscode .claude/plugins/plugins.txt /home/vscode/.claude/plugins/plugins.txt
COPY --chown=vscode:vscode .claude/plugins/known_marketplaces.json.template /home/vscode/.claude/plugins/known_marketplaces.json.template
COPY --chown=vscode:vscode script/install-claude-plugins.sh /tmp/install-claude-plugins.sh
COPY --chown=vscode:vscode script/install-skills.sh /tmp/install-skills.sh
COPY --chown=root:root script/setup-claude.sh /usr/local/bin/setup-claude.sh
COPY --chown=vscode:vscode script/setup-claude-build.sh /tmp/setup-claude-build.sh
COPY --chown=vscode:vscode script/lib /tmp/script/lib
COPY --chown=root:root script/lib /usr/local/script/lib
COPY --chown=root:root script/*.sh /usr/local/script/
# Copy templates for project initialization
COPY --chown=root:root .devcontainer/templates /usr/local/share/config-templates/
# Copy workflow/pre-commit templates for repo-maintenance distribution
COPY --chown=root:root templates/ /usr/local/share/config-templates/
RUN chmod +x /usr/local/bin/setup-claude.sh /tmp/setup-claude-build.sh /tmp/install-skills.sh /usr/local/script/*.sh

# Install skills from skills.txt using npx skills add
# Skills are installed to ~/.agents/skills/ with symlinks in ~/.claude/skills/
USER vscode
RUN env HOME=/home/vscode /tmp/install-skills.sh /home/vscode/.claude/skills/skills.txt || ( \
        echo "[WARN] スキルのインストールに失敗しました" && \
        echo "[INFO] コンテナ起動後に手動でインストールしてください: npx skills add <repo>" \
    )
USER root
RUN chown -R vscode:vscode /home/vscode/.agents /home/vscode/.claude/skills

# Install Claude plugins using BuildKit secret or environment variables
# Build with: DOCKER_BUILDKIT=1 docker build --secret id=claude_credentials,src=$HOME/.claude/.credentials.json .
# Or with: docker build --build-arg CLAUDE_CODE_OAUTH_TOKEN=$CLAUDE_CODE_OAUTH_TOKEN .
# Or with: docker build --build-arg ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY .
# Note: Secret is copied to a temp file readable by vscode, then plugin install runs as vscode
RUN --mount=type=secret,id=claude_credentials,uid=0,gid=0 \
    mkdir -p /tmp/claude-secret \
    && if [ -f /run/secrets/claude_credentials ]; then \
        cp /run/secrets/claude_credentials /tmp/claude-secret/token && \
        chmod 644 /tmp/claude-secret/token; \
    fi
USER vscode
RUN /tmp/install-claude-plugins.sh /home/vscode/.claude/plugins/plugins.txt || ( \
        echo "[WARN] Claude プラグインのインストールに失敗しました（認証情報が不足している可能性があります）" && \
        echo "[INFO] コンテナ起動後に手動でインストールしてください: claude plugin install <plugin>@<marketplace>" \
    )
USER root
RUN rm -rf /tmp/claude-secret \
 && chown -R vscode:vscode /home/vscode/.claude

# ビルド時にClaude設定を完全にセットアップ
USER vscode
RUN env HOME=/home/vscode bash /tmp/setup-claude-build.sh || echo "[WARN] ビルド時セットアップに失敗しました"
USER root

RUN chsh -s /bin/bash vscode

RUN echo 'source ~/.bashrc' >> /home/vscode/.bash_profile \
 && chown vscode:vscode /home/vscode/.bash_profile

# Write version file for easy version checking
RUN echo "${IMAGE_VERSION}" > /etc/config-base-version \
 && chmod 644 /etc/config-base-version

COPY package.json package-lock.json /tmp/
COPY .husky /tmp/.husky/
COPY git/commitlint.config.js /tmp/commitlint.config.js
RUN cd /tmp && npm ci && npm run prepare || true
