export NVM_DIR="$HOME/.nvm"

# デフォルト Node.js の PATH を即座に設定（claude 等の #!/usr/bin/env node 用）
# nvm 本体の初期化のみ遅延させる
if [ -d "$NVM_DIR/versions/node" ]; then
  # 最新のインストール済みバージョンを使用
  NODE_BIN=$(ls -d "$NVM_DIR/versions/node"/*/bin 2>/dev/null | sort -V | tail -1)
  [ -d "$NODE_BIN" ] && export PATH="$NODE_BIN:$PATH"
fi

# nvm 本体の遅延読み込み（nvm コマンド初回実行時のみ）
_nvm_lazy_load() {
  unset -f nvm
  local brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"
  local nvm_sh="$brew_prefix/opt/nvm/nvm.sh"
  local nvm_comp="$brew_prefix/opt/nvm/etc/bash_completion.d/nvm"
  if [ -s "$nvm_sh" ]; then
    \. "$nvm_sh"
    [ -s "$nvm_comp" ] && \. "$nvm_comp"
  elif [ -s "${NVM_DIR}/nvm.sh" ]; then
    \. "${NVM_DIR}/nvm.sh"
  else
    echo "nvm: nvm.sh not found (checked: $nvm_sh, ${NVM_DIR}/nvm.sh)" >&2
    return 1
  fi
}
nvm() {
  # 読み込みに失敗したら nvm はもう未定義なので、そのまま呼ぶと
  # 実際の失敗理由ではなく command not found になる。ここで打ち切る。
  _nvm_lazy_load || return $?
  nvm "$@"
}

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
