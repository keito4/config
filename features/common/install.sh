#!/bin/sh
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Determine the home directory for the target user. When the feature runs
# as root, the USERNAME environment variable points to the non-root user.
TARGET_HOME="$HOME"
if [ "$(id -u)" = 0 ] && [ -n "$USERNAME" ] && [ -d "/home/$USERNAME" ]; then
  TARGET_HOME="/home/$USERNAME"
fi

# Copy minimal shell configuration and functions without installing brew or
# other heavy dependencies.
mkdir -p "$TARGET_HOME/.zsh"
cp -r "$REPO_ROOT/.zsh/functions" "$TARGET_HOME/.zsh/"
cp "$REPO_ROOT/dot/.zprofile" "$TARGET_HOME/"
cp "$REPO_ROOT/dot/.zshrc" "$TARGET_HOME/"
cp -r "$REPO_ROOT/git" "$TARGET_HOME/"

# Ensure files are owned by the target user when running as root.
if [ "$(id -u)" = 0 ] && [ -n "$USERNAME" ]; then
  chown -R "$USERNAME":"$USERNAME" "$TARGET_HOME/.zsh" "$TARGET_HOME/.zprofile" \
    "$TARGET_HOME/.zshrc" "$TARGET_HOME/git"
fi
