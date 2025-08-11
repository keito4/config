FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y curl git alsa-utils sox \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y nodejs

# Install pnpm
RUN npm install -g pnpm

# Setup pnpm for vscode user and install global packages
USER vscode
ENV SHELL=/bin/bash
ENV PNPM_HOME="/home/vscode/.local/share/pnpm"
ENV PATH="${PNPM_HOME}:${PATH}"
RUN bash -c "pnpm setup" \
 && echo "export PNPM_HOME=\"/home/vscode/.local/share/pnpm\"" >> /home/vscode/.bashrc \
 && echo "export PATH=\"\$PNPM_HOME:\$PATH\"" >> /home/vscode/.bashrc \
 && bash -c "source /home/vscode/.bashrc && pnpm add -g supabase"

# Switch back to root for remaining operations
USER root

# Install global packages
RUN npm install -g typescript eslint @anthropic-ai/claude-code @openai/codex

# Install Cursor Agent
USER vscode
RUN curl https://cursor.com/install -fsS | bash \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/vscode/.bashrc
USER root

# Git aliases for common commands
RUN echo "alias gco='git checkout'" >> /home/vscode/.bashrc \
 && echo "alias gst='git status'" >> /home/vscode/.bashrc \
 && echo "alias gad='git add'" >> /home/vscode/.bashrc \
 && echo "alias gcm='git commit -m'" >> /home/vscode/.bashrc \
 && echo "alias gps='git push'" >> /home/vscode/.bashrc \
 && echo "alias gpl='git pull'" >> /home/vscode/.bashrc

# Setup directories
RUN mkdir -p /home/vscode/.claude /home/vscode/.cursor /home/vscode/.openai \
 && chown -R vscode:vscode /home/vscode/.claude /home/vscode/.cursor /home/vscode/.openai

# Copy default Claude settings
COPY --chown=vscode:vscode .devcontainer/claude-settings.json /home/vscode/.claude/settings.json

# Copy Claude commands
COPY --chown=vscode:vscode .claude/commands /home/vscode/.claude/commands

# Copy Claude agents
COPY --chown=vscode:vscode .claude/agents /home/vscode/.claude/agents

# Change default shell to bash
RUN chsh -s /bin/bash vscode

# Setup .bash_profile
RUN echo 'source ~/.bashrc' >> /home/vscode/.bash_profile \
 && chown vscode:vscode /home/vscode/.bash_profile

# Husky用の設定
COPY package.json package-lock.json /tmp/
COPY .husky /tmp/.husky/
RUN cd /tmp && npm ci && npm run prepare || true
