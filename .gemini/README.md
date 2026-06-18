# Gemini CLI MCP Policy

`.gemini/settings.json` intentionally keeps a smaller MCP set than
`.codex/config.toml`.

Gemini is used primarily for interactive review and cross-checking, so its MCP
servers are limited to:

- documentation/runtime inspection (`aws-docs`, `chrome-devtools`, `next-devtools`,
  `playwright`)
- token-backed project services used during review (`supabase`, `vercel`,
  `github`)

Codex keeps the broader repo-maintenance and operations set, including
`aws-knowledge`, `o3`, `context7`, `linear`, and `doppler`. See
`docs/adr/0012-environment-source-of-truth.md` for the decision record.
