# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"
# タイミング計測を有効にする変数（デフォルトは false）
ENABLE_TIMING=${ENABLE_TIMING:-false}

if [ "$ENABLE_TIMING" = true ]; then
  typeset -F script_start_time
  script_start_time=$EPOCHREALTIME
fi


# Amazon Q pre block. Keep at the top of this file.
if [ "$ENABLE_TIMING" = true ]; then
  float start_time_amazon_pre=$EPOCHREALTIME
fi

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_amazon_pre=$EPOCHREALTIME
  elapsed_time_amazon_pre=$(( end_time_amazon_pre - start_time_amazon_pre ))
  echo "Time for Amazon Q pre block: $elapsed_time_amazon_pre seconds"
fi

export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
  zsh-autosuggestions
)

if [ "$ENABLE_TIMING" = true ]; then
  float start_time_ohmyzsh=$EPOCHREALTIME
fi

source $ZSH/oh-my-zsh.sh

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_ohmyzsh=$EPOCHREALTIME
  elapsed_time_ohmyzsh=$(( end_time_ohmyzsh - start_time_ohmyzsh ))
  echo "Time for oh-my-zsh setup: $elapsed_time_ohmyzsh seconds"
fi

if [[ $(uname) = "Linux" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# カスタム関数の読み込み
if [ "$ENABLE_TIMING" = true ]; then
  float start_time_functions=$EPOCHREALTIME
fi

for function in ~/.zsh/functions/*; do
  source $function
done

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_functions=$EPOCHREALTIME
  elapsed_time_functions=$(( end_time_functions - start_time_functions ))
  echo "Time for loading custom functions: $elapsed_time_functions seconds"
fi

# 設定ファイルの読み込み
if [ "$ENABLE_TIMING" = true ]; then
  float start_time_load_settings=$EPOCHREALTIME
fi

_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/*(N-.); do
        if [ "$ENABLE_TIMING" = true ]; then
          float start_time_file=$EPOCHREALTIME
        fi

        . "$config"

        if [ "$ENABLE_TIMING" = true ]; then
          float end_time_file=$EPOCHREALTIME
          elapsed_time_file=$(( end_time_file - start_time_file ))
          echo "Time for sourcing $config: $elapsed_time_file seconds"
        fi
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          ;;
        *)
          if [ "$ENABLE_TIMING" = true ]; then
            float start_time_file=$EPOCHREALTIME
          fi

          . "$config"

          if [ "$ENABLE_TIMING" = true ]; then
            float end_time_file=$EPOCHREALTIME
            elapsed_time_file=$(( end_time_file - start_time_file ))
            echo "Time for sourcing $config: $elapsed_time_file seconds"
          fi
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/*; do
        if [ "$ENABLE_TIMING" = true ]; then
          float start_time_file=$EPOCHREALTIME
        fi

        . "$config"

        if [ "$ENABLE_TIMING" = true ]; then
          float end_time_file=$EPOCHREALTIME
          elapsed_time_file=$(( end_time_file - start_time_file ))
          echo "Time for sourcing $config: $elapsed_time_file seconds"
        fi
      done
    fi
  fi
}

_load_settings "$HOME/.zsh/configs"

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_load_settings=$EPOCHREALTIME
  elapsed_time_load_settings=$(( end_time_load_settings - start_time_load_settings ))
  echo "Time for _load_settings: $elapsed_time_load_settings seconds"
fi

# Amazon Q post block. Keep at the bottom of this file.
if [ "$ENABLE_TIMING" = true ]; then
  float start_time_amazon_post=$EPOCHREALTIME
fi

if [ "$ENABLE_TIMING" = true ]; then
  float end_time_amazon_post=$EPOCHREALTIME
  elapsed_time_amazon_post=$(( end_time_amazon_post - start_time_amazon_post ))
  echo "Time for Amazon Q post block: $elapsed_time_amazon_post seconds"
fi

# pnpm
export PNPM_HOME="/Users/keito/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end# Added by Windsurf
export PATH="/Users/keito/.codeium/windsurf/bin:$PATH"

# Added by Windsurf - Next
export PATH="/Users/keito/.codeium/windsurf/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/keito/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/keito/.lmstudio/bin"
# End of LM Studio CLI section


[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
