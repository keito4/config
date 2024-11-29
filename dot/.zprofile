# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh"
if [ "$ENABLE_TIMING" = true ]; then
  float start_time_amazon_pre2=$EPOCHREALTIME
fi

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_amazon_pre2=$EPOCHREALTIME
  elapsed_time_amazon_pre2=$(( end_time_amazon_pre2 - start_time_amazon_pre2 ))
  echo "Time for Amazon Q pre block (zprofile): $elapsed_time_amazon_pre2 seconds"
fi

# bashrcの読み込み
if [ "$ENABLE_TIMING" = true ]; then
  float start_time_bashrc=$EPOCHREALTIME
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_bashrc=$EPOCHREALTIME
  elapsed_time_bashrc=$(( end_time_bashrc - start_time_bashrc ))
  echo "Time for loading .bashrc: $elapsed_time_bashrc seconds"
fi

# PATHの設定
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# OrbStackの設定
if [ "$ENABLE_TIMING" = true ]; then
  float start_time_orbstack=$EPOCHREALTIME
fi

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_orbstack=$EPOCHREALTIME
  elapsed_time_orbstack=$(( end_time_orbstack - start_time_orbstack ))
  echo "Time for OrbStack initialization: $elapsed_time_orbstack seconds"
fi

# Amazon Q post block. Keep at the bottom of this file.
if [ "$ENABLE_TIMING" = true ]; then
  float start_time_amazon_post2=$EPOCHREALTIME
fi

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_amazon_post2=$EPOCHREALTIME
  elapsed_time_amazon_post2=$(( end_time_amazon_post2 - start_time_amazon_post2 ))
  echo "Time for Amazon Q post block (zprofile): $elapsed_time_amazon_post2 seconds"
fi

if [ "$ENABLE_TIMING" = true ]; then
  float script_end_time=$EPOCHREALTIME
  elapsed_time_script=$(( script_end_time - script_start_time ))
  echo "Total time for .zshrc: $elapsed_time_script seconds"
fi

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh"
