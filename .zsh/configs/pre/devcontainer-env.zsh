# Expose selected shared local secrets to CLI tools such as Codex MCP servers.
# NOTE: This list is duplicated in nix/home/zsh.nix (home.file). Keep both in sync.
# Clear previously exported tokens so removed entries in ~/.devcontainer.env don't linger.
unset SUPABASE_ACCESS_TOKEN VERCEL_TOKEN LINEAR_API_KEY DOPPLER_TOKEN
if [[ -r "$HOME/.devcontainer.env" ]]; then
  while IFS='=' read -r _codex_env_key _codex_env_value || [[ -n $_codex_env_key ]]; do
    # Strip trailing CR so Windows-style CRLF files work correctly.
    _codex_env_value="${_codex_env_value%$'\r'}"
    case "$_codex_env_key" in
      # Allowed keys: SUPABASE_ACCESS_TOKEN | VERCEL_TOKEN | LINEAR_API_KEY | DOPPLER_TOKEN
      SUPABASE_ACCESS_TOKEN|VERCEL_TOKEN|LINEAR_API_KEY|DOPPLER_TOKEN)
        export "$_codex_env_key=$_codex_env_value"
        ;;
    esac
  done < "$HOME/.devcontainer.env"
  unset _codex_env_key _codex_env_value
fi
