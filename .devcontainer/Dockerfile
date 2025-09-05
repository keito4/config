FROM mcr.microsoft.com/devcontainers/base:ubuntu

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
 && mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
 && apt-get update \
 && apt-get install -y nodejs \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

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

RUN npm install -g typescript eslint @anthropic-ai/claude-code @openai/codex vercel

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
 && echo "alias gpl='git pull'" >> /home/vscode/.bashrc

RUN mkdir -p /home/vscode/.claude /home/vscode/.cursor /home/vscode/.openai /home/vscode/.codex \
 && chown -R vscode:vscode /home/vscode/.claude /home/vscode/.cursor /home/vscode/.openai /home/vscode/.codex

COPY --chown=vscode:vscode .devcontainer/claude-settings.json /home/vscode/.claude/settings.json
COPY --chown=vscode:vscode .devcontainer/codex-config.json /home/vscode/.codex/config.json
COPY --chown=vscode:vscode .claude/commands /home/vscode/.claude/commands
COPY --chown=vscode:vscode .claude/agents /home/vscode/.claude/agents

RUN chsh -s /bin/bash vscode

RUN echo 'source ~/.bashrc' >> /home/vscode/.bash_profile \
 && chown vscode:vscode /home/vscode/.bash_profile

COPY package.json package-lock.json /tmp/
COPY .husky /tmp/.husky/
RUN cd /tmp && npm ci && npm run prepare || true
