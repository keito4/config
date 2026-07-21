# Expose selected shared local secrets to CLI tools such as Codex MCP servers.
# NOTE: This loader is duplicated in nix/home/zsh.nix (home.file). Keep both in sync.
# 許可キー一覧は組織名を含むため private-config 管理の外部ファイルに置く
_codex_env_allowlist="$HOME/.config/devcontainer-env-keys.txt"
if [[ -r "$_codex_env_allowlist" ]]; then
  # Clear previously exported tokens so removed entries in ~/.devcontainer.env don't linger.
  while IFS= read -r _codex_env_key || [[ -n $_codex_env_key ]]; do
    [[ -n $_codex_env_key && $_codex_env_key != \#* ]] && unset "$_codex_env_key"
  done < "$_codex_env_allowlist"
  if [[ -r "$HOME/.devcontainer.env" ]]; then
    while IFS='=' read -r _codex_env_key _codex_env_value || [[ -n $_codex_env_key ]]; do
      # Strip trailing CR so Windows-style CRLF files work correctly.
      _codex_env_value="${_codex_env_value%$'\r'}"
      if [[ -n $_codex_env_key && $_codex_env_key != \#* ]] && grep -qxF -- "$_codex_env_key" "$_codex_env_allowlist"; then
        export "$_codex_env_key=$_codex_env_value"
      fi
    done < "$HOME/.devcontainer.env"
  fi
fi
unset _codex_env_key _codex_env_value _codex_env_allowlist
