#!/usr/bin/env python3
"""Defense-in-depth hook: detect dangerous commands including bash -c bypass.

This hook checks command patterns and quoted scripts passed to shell -c.
Quoted data arguments are masked to avoid treating their text as commands.
It is a heuristic defense alongside the deny list, not a complete shell parser.
"""
import sys
import re
import shlex
from common import load_hook_input, get_command

data = load_hook_input()
cmd = get_command(data)

if not cmd.strip():
    sys.exit(0)

def inspection_text(command: str) -> str:
    """Mask data arguments, but inspect quoted scripts passed to a shell's -c."""
    texts = []
    pending = [command]
    while pending:
        source = pending.pop()
        # Keep offsets so a shell invocation found outside quotes can be parsed
        # from the original source. Quoted data and shell comments are masked
        # together so quotes inside a comment cannot consume subsequent code.
        masked = re.sub(r"'[^']*'|\"(?:\\.|[^\"\\])*\"|(?<![^\s;&|()<>])#[^\n]*", lambda m: " " * len(m[0]), source)
        texts.append(" ".join(masked.split()).lower())
        shells = re.finditer(
            r"(?:^|[;&|\n])\s*(?:env\s+)?(?P<shell>(?:/[^\s]+/)?(?:bash|sh|zsh|dash|ksh))(?=\s)",
            masked,
        )
        for shell in shells:
            try:
                words = shlex.split(source[shell.start("shell"):], comments=True)
            except ValueError:
                # An unparseable executable script must not silently pass.
                sys.stderr.write("Cannot inspect shell command: unmatched quotes\n")
                sys.exit(2)
            for index, word in enumerate(words[1:], 1):
                if not word.startswith("-") or word == "--":
                    break
                if word.startswith("--"):
                    continue
                if "c" in word[1:] and index + 1 < len(words):
                    pending.append(words[index + 1])
                    break
    return " ; ".join(texts)


normalized = inspection_text(cmd)

# ── Dangerous patterns (regex) ──────────────────────────────────
DANGEROUS_PATTERNS = [
    # === Git destructive operations ===
    # NOTE: flag wildcards use [^|&;<>]* (not .*) so the match stays within a
    # single command's own arguments. normalize() flattens newlines to spaces,
    # so a greedy .* would otherwise reach a flag-like token in a chained command
    # (`a && b`), a pipe (`| x`), a redirect (`2>&1`) or a heredoc body, causing
    # false positives. [^|&;<>]* stops at the first such boundary.
    (r"git\s+push\s+[^|&;<>]*--force", "git push --force (force push)"),
    (r"git\s+push\s+[^|&;<>]*-f\b", "git push -f (force push)"),
    (r"git\s+push\s+[^|&;<>]*--force-with-lease", "git push --force-with-lease"),
    (r"git\s+push\s+\S+\s+\+", "git push origin +branch (force push)"),
    (r"git\s+clean\s+[^|&;<>]*-f", "git clean -f (delete untracked files)"),
    (r"git\s+reflog\s+expire", "git reflog expire (destroy recovery data)"),
    (r"git\s+reset\s+--hard", "git reset --hard (discard all changes)"),

    # === chmod dangerous operations ===
    (r"chmod\s+777\b", "chmod 777 (world-writable permissions)"),

    # === rm destructive operations ===
    (r"rm\s+[^|&;<>]*-r[^|&;<>]*-f|rm\s+[^|&;<>]*-f[^|&;<>]*-r|rm\s+-rf", "rm -rf (recursive force delete)"),

    # === Docker destructive operations ===
    (r"docker\s+system\s+prune", "docker system prune"),
    (r"docker\s+volume\s+prune", "docker volume prune (data loss)"),
    (r"docker\s+run\s+[^|&;<>]*--privileged", "docker run --privileged (host access)"),
    (r"docker\s+push\b", "docker push (registry publish)"),

    # === Kubernetes destructive operations ===
    (r"kubectl\s+delete\s+(deployment|service|pvc|statefulset|ingress|daemonset|cronjob|job)\b",
     "kubectl delete (workload/resource destruction)"),
    (r"kubectl\s+delete\s+(namespace|ns)\b", "kubectl delete namespace"),
    (r"kubectl\s+delete\s+pod\s+[^|&;<>]*--all", "kubectl delete pod --all"),
    (r"kubectl\s+scale\s+[^|&;<>]*--replicas\s*=\s*0", "kubectl scale --replicas=0 (service stop)"),

    # === Terraform destructive operations ===
    (r"terraform\s+destroy", "terraform destroy"),
    (r"terraform\s+apply\s+[^|&;<>]*-auto-approve", "terraform apply -auto-approve"),
    (r"terraform\s+state\s+rm", "terraform state rm (orphan resources)"),

    # === AWS destructive operations ===
    (r"aws\s+ec2\s+terminate-instances", "aws ec2 terminate-instances"),
    (r"aws\s+s3\s+rm\s+[^|&;<>]*--recursive", "aws s3 rm --recursive (bulk delete)"),
    (r"aws\s+s3\s+rb\b", "aws s3 rb (bucket delete)"),
    (r"aws\s+rds\s+delete-db", "aws rds delete-db (database deletion)"),
    (r"aws\s+cloudformation\s+delete-stack", "aws cloudformation delete-stack"),
    (r"aws\s+iam\s+delete-(role|policy|user)", "aws iam delete (IAM destruction)"),
    (r"aws\s+lambda\s+delete-function", "aws lambda delete-function"),

    # === GCP destructive operations ===
    (r"gcloud\s+projects\s+delete", "gcloud projects delete"),
    (r"gcloud\s+compute\s+instances\s+delete", "gcloud compute instances delete"),
    (r"gcloud\s+sql\s+instances\s+delete", "gcloud sql instances delete"),
    (r"gcloud\s+container\s+clusters\s+delete", "gcloud container clusters delete"),

    # === Azure destructive operations ===
    (r"az\s+group\s+delete", "az group delete (resource group deletion)"),
    (r"az\s+vm\s+delete", "az vm delete"),
    (r"az\s+sql\s+server\s+delete", "az sql server delete"),
    (r"az\s+storage\s+account\s+delete", "az storage account delete"),

    # === Helm destructive operations ===
    (r"helm\s+(uninstall|delete)\b", "helm uninstall/delete"),

    # === Supabase destructive operations ===
    (r"supabase\s+db\s+(push|reset)\b", "supabase db push/reset"),
    (r"supabase\s+migration\s+(squash|repair)\b", "supabase migration squash/repair"),
    (r"supabase\s+db\s+branch\s+delete", "supabase db branch delete"),
    (r"supabase\s+functions\b", "supabase functions (production deploy)"),
    (r"supabase\s+projects\s+delete", "supabase projects delete"),

    # === Vercel destructive operations ===
    (r"vercel\s+--prod\b", "vercel --prod (production deploy)"),
    (r"vercel\s+(rm|remove)\b", "vercel rm (deployment/project deletion)"),
    (r"vercel\s+env\s+rm\b", "vercel env rm (env var deletion)"),

    # === npm destructive operations ===
    (r"\bnpm\s+publish\b", "npm publish (package publication)"),
    (r"\bnpm\s+unpublish\b", "npm unpublish (package removal)"),

    # === SQL destructive operations (via psql) ===
    (r"drop\s+(database|table|schema|index|view|function|trigger)\b",
     "DROP (SQL destructive DDL)"),
    (r"\btruncate\s+", "TRUNCATE (data deletion)"),

    # === Credential exposure ===
    (r"gcloud\s+auth\s+print-access-token", "gcloud auth print-access-token (token leak)"),
    (r"az\s+account\s+get-access-token", "az account get-access-token (token leak)"),
]

# ── Check command against all patterns ──────────────────────────
for pattern, description in DANGEROUS_PATTERNS:
    if re.search(pattern, normalized):
        sys.stderr.write(
            f"🚫 危険なコマンドを検出しました: {description}\n"
            f"   コマンド: {cmd[:200]}{'...' if len(cmd) > 200 else ''}\n"
            f"   このコマンドは安全ポリシーによりブロックされました。\n"
            f"   CI/CD パイプライン経由で実行してください。\n"
        )
        sys.stderr.flush()
        sys.exit(2)

sys.exit(0)
