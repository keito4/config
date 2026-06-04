#!/usr/bin/env python3
"""Defense-in-depth hook: block commands that embed literal credentials.

Claude Code persists approved commands as permission rules in
``.claude/settings.local.json``. When a command embeds a real secret inline
(e.g. ``export AWS_SECRET_ACCESS_KEY="..."``), that secret leaks into the
settings file — and, if the file is tracked, into git history. This is exactly
how long-lived credentials end up committed.

This hook inspects the full command string and blocks execution when it
contains a high-confidence credential pattern, so secrets never get approved,
run, or written to disk. Pass secrets via the environment or a secret manager
(1Password / Doppler / GitHub Secrets) instead.

Only high-confidence patterns are blocked to keep false positives near zero;
variable references like ``export TOKEN="$GH_TOKEN"`` are never matched.
"""
import sys
import re
from common import load_hook_input, get_command

data = load_hook_input()
cmd = get_command(data)

if not cmd.strip():
    sys.exit(0)

# Public Supabase local-dev JWT (issuer "supabase-demo", base64 marker below).
# Shipped in every `supabase start` stack — public by design, not a real secret.
SUPABASE_DEMO_MARKER = "eyJpc3MiOiJzdXBhYmFzZS1kZW1v"

# High-confidence credential patterns (real secrets, low false-positive rate).
SECRET_PATTERNS = [
    (r"(AKIA|ASIA)[0-9A-Z]{16}", "AWS access key id"),
    (r"aws_secret_access_key\s*[=:]\s*['\"]?[A-Za-z0-9/+]{40}", "AWS secret access key"),
    (r"ghp_[A-Za-z0-9]{36}", "GitHub personal access token"),
    (r"gho_[A-Za-z0-9]{36}", "GitHub OAuth token"),
    (r"github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9]{59}", "GitHub fine-grained PAT"),
    (r"sk-ant-[A-Za-z0-9_-]{95,}", "Anthropic API key"),
    (r"sk-proj-[A-Za-z0-9_-]{20,}", "OpenAI project key"),
    (r"\bsk-[A-Za-z0-9]{48}\b", "OpenAI legacy key"),
    (r"xox[baprs]-[A-Za-z0-9-]{10,}", "Slack token"),
    (r"[sr]k_(live|test)_[A-Za-z0-9]{24,}", "Stripe key"),
    (r"lin_api_[A-Za-z0-9]{43}", "Linear API key"),
    (r"AIza[0-9A-Za-z_-]{35}", "Google API key"),
    (r"glpat-[A-Za-z0-9_-]{20}", "GitLab personal access token"),
    (r"dp\.(pt|st|sa|ct|scim|audit)\.[A-Za-z0-9]{40,}", "Doppler token"),
    (r"-----BEGIN[A-Z ]*PRIVATE KEY-----", "private key"),
]

# Strip the public demo JWT so it never trips detection.
scan = cmd.replace(SUPABASE_DEMO_MARKER, "")

for pattern, label in SECRET_PATTERNS:
    if re.search(pattern, scan, re.IGNORECASE):
        sys.stderr.write(
            f"🚫 コマンドに認証情報が埋め込まれています: {label}\n"
            f"   inline の秘密は settings.local.json に許可ルールとして永続化され、"
            f"git 履歴への漏洩原因になります。\n"
            f"   環境変数 もしくは シークレットマネージャ"
            f"（1Password / Doppler / GitHub Secrets）経由で渡してください。\n"
        )
        sys.stderr.flush()
        sys.exit(2)

sys.exit(0)
