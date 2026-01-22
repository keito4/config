FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Build arguments for Claude Code authentication
ARG CLAUDE_CODE_OAUTH_TOKEN
ARG ANTHROPIC_API_KEY

# Install dependencies and Node.js using official binaries
RUN apt-get update && apt-get install -y \
    curl \
    git \
    alsa-utils \
    sox \
    build-essential \
    pkg-config \
    libssl-dev \
    libasound2-dev \
    ca-certificates \
    gnupg \
    wget \
    xz-utils \
    shellcheck \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && NODE_VERSION=v22.14.0 \
 && NODE_ARCH=$(dpkg --print-architecture | sed 's/amd64/x64/;s/armhf/armv7l/;s/arm64/arm64/') \
 && wget -q https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz \
 && tar -xJf node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz -C /usr/local --strip-components=1 \
 && rm node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz \
 && ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN npm install -g pnpm

USER vscode
ENV SHELL=/bin/bash
ENV PNPM_HOME="/home/vscode/.local/share/pnpm"
ENV RUSTUP_HOME="/home/vscode/.rustup"
ENV CARGO_HOME="/home/vscode/.cargo"
ENV PATH="${CARGO_HOME}/bin:${PNPM_HOME}:${PATH}"
RUN bash -c "pnpm setup" \
 && echo "export PNPM_HOME=\"/home/vscode/.local/share/pnpm\"" >> /home/vscode/.bashrc \
 && echo "export PATH=\"\$PNPM_HOME:\$PATH\"" >> /home/vscode/.bashrc \
 && echo "export RUSTUP_HOME=\"/home/vscode/.rustup\"" >> /home/vscode/.bashrc \
 && echo "export CARGO_HOME=\"/home/vscode/.cargo\"" >> /home/vscode/.bashrc \
 && echo "export PATH=\"\$CARGO_HOME/bin:\$PATH\"" >> /home/vscode/.bashrc \
 && curl -sSf https://sh.rustup.rs | bash -s -- -y --default-toolchain stable \
 && bash -lc "rustup component add rustfmt clippy" \
 && bash -c "source /home/vscode/.bashrc && pnpm add -g supabase"

USER root

COPY npm/global.json /tmp/npm-global.json

RUN CLAUDE_CODE_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['@anthropic-ai/claude-code'].version") \
 && CODEX_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['@openai/codex'].version") \
 && VERCEL_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['vercel'].version") \
 && GEMINI_CLI_VERSION=$(node -pe "require('/tmp/npm-global.json').dependencies['@google/gemini-cli'].version") \
 && npm install -g eslint \
    typescript \
    typescript-language-server \
    @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    @openai/codex@${CODEX_VERSION} \
    vercel@${VERCEL_VERSION} \
    @google/gemini-cli@${GEMINI_CLI_VERSION}

USER vscode
RUN bash -lc "cargo install similarity-ts" || true \
    && curl https://cursor.com/install -fsS | bash \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/vscode/.bashrc
USER root

RUN echo "alias gco='git checkout'" >> /home/vscode/.bashrc \
 && echo "alias gst='git status'" >> /home/vscode/.bashrc \
 && echo "alias gad='git add'" >> /home/vscode/.bashrc \
 && echo "alias gcm='git commit -m'" >> /home/vscode/.bashrc \
 && echo "alias gps='git push'" >> /home/vscode/.bashrc \
 && echo "alias gpl='git pull'" >> /home/vscode/.bashrc \
 && echo 'export PATH="/usr/local/script:$PATH"' >> /home/vscode/.bashrc

RUN mkdir -p /home/vscode/.claude /home/vscode/.cursor /home/vscode/.openai /home/vscode/.codex \
 && chown -R vscode:vscode /home/vscode/.claude /home/vscode/.cursor /home/vscode/.openai /home/vscode/.codex

COPY --chown=vscode:vscode .devcontainer/claude-settings.json /home/vscode/.claude/settings.json
COPY --chown=vscode:vscode .devcontainer/claude-settings.local.json /home/vscode/.claude/settings.local.json
COPY --chown=vscode:vscode .devcontainer/codex-config.json /home/vscode/.codex/config.json
COPY --chown=vscode:vscode .claude/commands /home/vscode/.claude/commands
COPY --chown=vscode:vscode .claude/agents /home/vscode/.claude/agents
COPY --chown=vscode:vscode .claude/hooks /home/vscode/.claude/hooks
COPY --chown=vscode:vscode .claude/plugins/plugins.txt /home/vscode/.claude/plugins/plugins.txt
COPY --chown=vscode:vscode .claude/plugins/known_marketplaces.json.template /home/vscode/.claude/plugins/known_marketplaces.json.template
COPY --chown=vscode:vscode script/install-claude-plugins.sh /tmp/install-claude-plugins.sh
COPY --chown=root:root script/setup-claude.sh /usr/local/bin/setup-claude.sh
COPY --chown=vscode:vscode script/setup-claude-build.sh /tmp/setup-claude-build.sh
COPY --chown=vscode:vscode script/lib /tmp/script-lib
COPY --chown=root:root script/lib /usr/local/script/lib
COPY --chown=root:root script/*.sh /usr/local/script/
RUN chmod +x /usr/local/bin/setup-claude.sh /tmp/setup-claude-build.sh /usr/local/script/*.sh

# Install Claude plugins using BuildKit secret or environment variables
# Build with: DOCKER_BUILDKIT=1 docker build --secret id=claude_credentials,src=$HOME/.claude/.credentials.json .
# Or with: docker build --build-arg CLAUDE_CODE_OAUTH_TOKEN=$CLAUDE_CODE_OAUTH_TOKEN .
# Or with: docker build --build-arg ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY .
# Note: Run as root to access BuildKit secret, but use vscode's HOME for plugin installation
RUN --mount=type=secret,id=claude_credentials,uid=0,gid=0 \
    env HOME=/home/vscode CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN}" ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" /tmp/install-claude-plugins.sh /home/vscode/.claude/plugins/plugins.txt || ( \
        echo "[WARN] Claude プラグインのインストールに失敗しました（認証情報が不足している可能性があります）" && \
        echo "[INFO] コンテナ起動後に手動でインストールしてください: claude plugin install <plugin>@<marketplace>" \
    ) \
    && chown -R vscode:vscode /home/vscode/.claude

# ビルド時にClaude設定を完全にセットアップ
USER vscode
RUN env HOME=/home/vscode bash /tmp/setup-claude-build.sh || echo "[WARN] ビルド時セットアップに失敗しました"
USER root

RUN chsh -s /bin/bash vscode

RUN echo 'source ~/.bashrc' >> /home/vscode/.bash_profile \
 && chown vscode:vscode /home/vscode/.bash_profile

COPY package.json package-lock.json /tmp/
COPY .husky /tmp/.husky/
COPY git/commitlint.config.js /tmp/commitlint.config.js
RUN cd /tmp && npm ci && npm run prepare || true
