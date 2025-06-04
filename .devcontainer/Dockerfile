FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y curl git \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y nodejs

# Install pnpm
RUN npm install -g pnpm

RUN npm install -g typescript eslint @anthropic-ai/claude-code

# Husky用の設定
COPY package.json package-lock.json /tmp/
COPY .husky /tmp/.husky/
COPY commitlint.config.js /tmp/
RUN cd /tmp && npm ci && npm run prepare || true
