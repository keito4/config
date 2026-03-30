#!/usr/bin/env python3
"""Defense-in-depth hook: detect dangerous commands including bash -c bypass.

This hook inspects the FULL command string (not just the prefix) to catch
dangerous patterns even when wrapped in bash -c, python3 -c, zsh -c, etc.
Works alongside the deny list which only matches command prefixes.
"""
import sys
import json
import re
from common import load_hook_input, get_command

data = load_hook_input()
cmd = get_command(data)

if not cmd.strip():
    sys.exit(0)

# Normalize: collapse whitespace, lowercase for pattern matching
normalized = " ".join(cmd.split()).lower()

# ── Dangerous patterns (regex) ──────────────────────────────────
DANGEROUS_PATTERNS = [
    # === Git destructive operations ===
    (r"git\s+push\s+.*--force", "git push --force (force push)"),
    (r"git\s+push\s+.*-f\b", "git push -f (force push)"),
    (r"git\s+push\s+.*--force-with-lease", "git push --force-with-lease"),
    (r"git\s+push\s+\S+\s+\+", "git push origin +branch (force push)"),
    (r"git\s+clean\s+.*-f", "git clean -f (delete untracked files)"),
    (r"git\s+reflog\s+expire", "git reflog expire (destroy recovery data)"),
    (r"git\s+reset\s+--hard", "git reset --hard (discard all changes)"),

    # === chmod dangerous operations ===
    (r"chmod\s+777\b", "chmod 777 (world-writable permissions)"),

    # === rm destructive operations ===
    (r"rm\s+.*-r.*-f|rm\s+.*-f.*-r|rm\s+-rf", "rm -rf (recursive force delete)"),

    # === Docker destructive operations ===
    (r"docker\s+system\s+prune", "docker system prune"),
    (r"docker\s+volume\s+prune", "docker volume prune (data loss)"),
    (r"docker\s+run\s+.*--privileged", "docker run --privileged (host access)"),
    (r"docker\s+push\b", "docker push (registry publish)"),

    # === Kubernetes destructive operations ===
    (r"kubectl\s+delete\s+(deployment|service|pvc|statefulset|ingress|daemonset|cronjob|job)\b",
     "kubectl delete (workload/resource destruction)"),
    (r"kubectl\s+delete\s+(namespace|ns)\b", "kubectl delete namespace"),
    (r"kubectl\s+delete\s+pod\s+.*--all", "kubectl delete pod --all"),
    (r"kubectl\s+scale\s+.*--replicas\s*=\s*0", "kubectl scale --replicas=0 (service stop)"),

    # === Terraform destructive operations ===
    (r"terraform\s+destroy", "terraform destroy"),
    (r"terraform\s+apply\s+.*-auto-approve", "terraform apply -auto-approve"),
    (r"terraform\s+state\s+rm", "terraform state rm (orphan resources)"),

    # === AWS destructive operations ===
    (r"aws\s+ec2\s+terminate-instances", "aws ec2 terminate-instances"),
    (r"aws\s+s3\s+rm\s+.*--recursive", "aws s3 rm --recursive (bulk delete)"),
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
