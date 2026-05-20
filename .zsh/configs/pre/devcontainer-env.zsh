# Expose selected shared local secrets to CLI tools such as Codex MCP servers.
if [[ -r "$HOME/.devcontainer.env" ]]; then
  while IFS='=' read -r _codex_env_key _codex_env_value || [[ -n $_codex_env_key ]]; do
    case "$_codex_env_key" in
      SUPABASE_ACCESS_TOKEN|VERCEL_TOKEN|LINEAR_API_KEY|DOPPLER_TOKEN)
        export "$_codex_env_key=$_codex_env_value"
        ;;
    esac
  done < "$HOME/.devcontainer.env"
  unset _codex_env_key _codex_env_value
fi
