#!/usr/bin/env bash
# Executable repository maintenance workflow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"
# shellcheck source=script/lib/repo_maintenance_checks.sh
source "$SCRIPT_DIR/lib/repo_maintenance_checks.sh"

MODE="full"
SKIP_CATEGORIES=""
CREATE_PR=false
CHECK_REQUIRED_WORKFLOWS_ONLY=false
CHECK_ACTIONS_PR_SETTINGS_ONLY=false
CHECK_SCHEDULED_MAINTENANCE_ONLY=false
CHECK_ARTIFACT_RETENTION_ONLY=false
CONTEXT_DIR="${CONTEXT_DIR:-.context}"

usage() {
  cat <<'EOF'
Usage: script/repo-maintenance.sh [--mode full|quick|check-only] [--skip CATEGORY] [--create-pr] [--check-required-workflows] [--check-actions-pr-settings] [--check-scheduled-maintenance] [--check-artifact-retention]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:?--mode requires a value}"
      shift 2
      ;;
    --skip)
      SKIP_CATEGORIES="${SKIP_CATEGORIES:+$SKIP_CATEGORIES,}${2:?--skip requires a value}"
      shift 2
      ;;
    --create-pr)
      CREATE_PR=true
      shift
      ;;
    --check-required-workflows)
      CHECK_REQUIRED_WORKFLOWS_ONLY=true
      MODE="check-only"
      shift
      ;;
    --check-actions-pr-settings)
      CHECK_ACTIONS_PR_SETTINGS_ONLY=true
      MODE="check-only"
      shift
      ;;
    --check-scheduled-maintenance)
      CHECK_SCHEDULED_MAINTENANCE_ONLY=true
      MODE="check-only"
      shift
      ;;
    --check-artifact-retention)
      CHECK_ARTIFACT_RETENTION_ONLY=true
      MODE="check-only"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      output::fatal "Unknown argument: $1"
      ;;
  esac
done

case "$MODE" in
  full|quick|check-only) ;;
  *) output::fatal "Unsupported mode: $MODE" ;;
esac

mkdir -p "$CONTEXT_DIR"

has_skip() {
  local category="${1:?Category required}"
  [[ ",$SKIP_CATEGORIES," == *",$category,"* ]]
}

run_if_exists() {
  local description="${1:?Description required}"
  shift

  output::info "$description"
  "$@"
}

workflow_has_event() {
  local workflow="${1:?Workflow required}"
  local event="${2:?Event required}"

  awk -v event="$event" '
    function has_event(line) {
      return line ~ "(^|[^A-Za-z0-9_-])" event "([^A-Za-z0-9_-]|$)"
    }
    /^on:[[:space:]]*\[/ || /^"on":[[:space:]]*\[/ || /^\047on\047:[[:space:]]*\[/ {
      if (has_event($0)) found = 1
      next
    }
    /^on:[[:space:]]*$/ || /^"on":[[:space:]]*$/ || /^\047on\047:[[:space:]]*$/ {
      in_on = 1
      next
    }
    in_on && /^[^[:space:]#][^:]*:/ {
      in_on = 0
    }
    in_on {
      if ($0 ~ "^[[:space:]]*-[[:space:]]*" event "([[:space:]#]|$)") found = 1
      if ($0 ~ "^[[:space:]]*" event ":[[:space:]]*") found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$workflow"
}

workflow_is_required_candidate() {
  local workflow="${1:?Workflow required}"
  local base
  base="$(basename "$workflow")"

  [[ "$base" == "security-summary.yml" || "$base" == "security-summary.yaml" || "$base" == "required.yml" || "$base" == "required.yaml" ]] && return 0
  grep -qiE '^name:[[:space:]]*(Required Workflow|Security Summary)' "$workflow"
}

workflow_has_unguarded_generate_summary() {
  local workflow="${1:?Workflow required}"

  awk '
    /^  generate-summary:/ {
      in_job = 1
      guarded = 0
      next
    }
    in_job && /^  [A-Za-z0-9_-]+:/ {
      if (!guarded) found = 1
      in_job = 0
    }
    in_job && /^    if: .*github\.event_name == '\''schedule'\'' \|\| github\.event_name == '\''workflow_dispatch'\''/ {
      guarded = 1
    }
    END {
      if (in_job && !guarded) found = 1
      exit found ? 0 : 1
    }
  ' "$workflow"
}

check_required_workflows() {
  local issues=()
  local workflow base
  local workflows=()

  for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
    [[ -f "$workflow" ]] && workflows+=("$workflow")
  done

  for workflow in "${workflows[@]}"; do
    workflow_is_required_candidate "$workflow" || continue
    base="$(basename "$workflow")"

    if ! workflow_has_event "$workflow" "push" && ! workflow_has_event "$workflow" "pull_request"; then
      issues+=("$base: Required Workflow 候補ですが push / pull_request トリガーがありません")
    fi

    if workflow_has_unguarded_generate_summary "$workflow"; then
      issues+=("$base: Slack 通知付き generate-summary は job-level if で schedule / workflow_dispatch に限定してください")
    fi
  done

  printf '%s\n' "${issues[@]}"
  [[ "${#issues[@]}" -eq 0 ]]
}

check_repository_state() {
  local repo_json repo_archived repo_private

  repo_json="$(gh repo view --json nameWithOwner,isArchived,isPrivate 2>/dev/null || echo '{}')"
  repo_archived="$(echo "$repo_json" | jq -r '.isArchived // false')"
  repo_private="$(echo "$repo_json" | jq -r '.isPrivate // false')"
  REPO_PRIVATE="${repo_private:-false}"

  if [[ "$repo_archived" == "true" ]]; then
    output::warning "Archived repository: read-only checks only"
    MODE="check-only"
    CREATE_PR=false
  fi

  if [[ "$REPO_PRIVATE" == "true" ]]; then
    output::info "Private repo: Dependency Review は optional / skipped を許容"
  fi
}

check_actions_pr_creation_settings() {
  local repo settings default_permissions can_create_pr settings_url issue_count=0

  if ! command -v gh >/dev/null 2>&1; then
    output::warning "GitHub Actions PR creation settings check skipped: gh not found"
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    output::warning "GitHub Actions PR creation settings check skipped: jq not found"
    return 0
  fi

  repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)"
  if [[ -z "$repo" || "$repo" == "null" ]]; then
    output::warning "GitHub Actions PR creation settings check skipped: repository unavailable"
    return 0
  fi

  settings="$(gh api "repos/$repo/actions/permissions/workflow" 2>/dev/null || true)"
  if [[ -z "$settings" ]]; then
    output::warning "GitHub Actions PR creation settings unavailable for $repo"
    return 0
  fi

  default_permissions="$(echo "$settings" | jq -r '.default_workflow_permissions // empty')"
  can_create_pr="$(echo "$settings" | jq -r '.can_approve_pull_request_reviews // false')"
  settings_url="https://github.com/$repo/settings/actions"

  if [[ "$default_permissions" != "write" ]]; then
    output::warning "GitHub Actions default workflow permissions are '$default_permissions' (expected: write)"
    issue_count=$((issue_count + 1))
  fi

  if [[ "$can_create_pr" != "true" ]]; then
    output::warning "GitHub Actions PR creation is disabled (expected: Allow GitHub Actions to create and approve pull requests)"
    issue_count=$((issue_count + 1))
  fi

  if [[ "$issue_count" -gt 0 ]]; then
    echo "Settings: $settings_url"
    return 1
  fi

  output::success "GitHub Actions PR creation settings ok"
}

check_workflow_templates() {
  if npm run workflow:sync:check --if-present >/dev/null 2>&1; then
    output::success "Workflow template sync ok"
  else
    output::warning "Workflow template sync check unavailable or failed"
  fi
}

extract_actionlint_flags_block() {
  local ci_yml="${1:?CI workflow file required}"
  awk '
    /^[[:space:]]+actionlint_flags:/ { in_flags = 1; print; next }
    in_flags && /^[[:space:]]+[A-Za-z0-9_-]+:/ { exit }
    in_flags && /^[^[:space:]]/ { exit }
    in_flags { print }
  ' "$ci_yml"
}

check_workflow_template_lint_coverage() {
  local ci_yml=".github/workflows/ci.yml"
  local content actionlint_flags_block
  local lint_issues=0

  [[ -f "$ci_yml" ]] || return 0

  content="$(cat "$ci_yml")"

  if [[ "$content" != *"Collect workflow files"* ]]; then
    output::warning "ci.yml: Workflow Lint が存在するファイル収集方式ではありません"
    lint_issues=$((lint_issues + 1))
  fi

  if [[ "$content" != *".context/actionlint-files.txt"* ]]; then
    output::warning "ci.yml: actionlint 対象ファイルリストを .context に保存していません"
    lint_issues=$((lint_issues + 1))
  fi

  if [[ "$content" != *"find .github/workflows/templates"* || "$content" != *"find templates/workflows"* ]]; then
    output::warning "ci.yml: workflow template の actionlint 対象収集が不足しています"
    lint_issues=$((lint_issues + 1))
  fi

  if [[ "$content" != *"-name '*.yaml'"* ]]; then
    output::warning "ci.yml: .yaml workflow が actionlint 対象から漏れています"
    lint_issues=$((lint_issues + 1))
  fi

  actionlint_flags_block="$(extract_actionlint_flags_block "$ci_yml")"

  if grep -qE 'templates/workflows/.*\*' <<<"$actionlint_flags_block"; then
    output::warning "ci.yml: actionlint_flags に静的 template glob が残っています"
    lint_issues=$((lint_issues + 1))
  fi

  if [[ "$lint_issues" -eq 0 ]]; then
    output::success "Workflow Template Lint coverage ok"
  fi
}

check_dependency_peer_compatibility() {
  local peer_issues=0

  if [[ -f package-lock.json || -f package.json ]]; then
    if ! npm ls --all --json > "$CONTEXT_DIR/npm-peer-compat.log" 2>&1; then
      peer_issues=$((peer_issues + 1))
    fi
  fi

  if [[ -f pnpm-lock.yaml ]]; then
    if ! pnpm install --lockfile-only --frozen-lockfile > "$CONTEXT_DIR/pnpm-peer-compat.log" 2>&1; then
      peer_issues=$((peer_issues + 1))
    fi
  fi

  if [[ "$peer_issues" -gt 0 ]]; then
    output::warning "dependency compatibility issue detected"
  else
    output::success "Dependency Peer Compatibility Check ok"
  fi
}

check_managed_templates() {
  local managed_template_files=(
    "templates/workflows/dependabot-auto-merge.yml:.github/workflows/dependabot-auto-merge.yml"
    "templates/workflows/label-sync.yml:.github/workflows/label-sync.yml"
  )
  local item source target

  for item in "${managed_template_files[@]}"; do
    source="${item%%:*}"
    target="${item#*:}"
    [[ -f "$CONFIG_REPO/$source" ]] || continue
    if [[ ! -f "$target" ]]; then
      output::warning "$target missing"
      continue
    fi
    if ! cmp -s "$CONFIG_REPO/$source" "$target"; then
      output::warning "$target 差分あり・full modeで更新"
      if [[ "$MODE" == "full" ]]; then
        cp "$CONFIG_REPO/$source" "$target"
      fi
    fi
  done
}

ensure_labels() {
  command -v gh >/dev/null 2>&1 || return 0
  gh label create "dependabot-minor" --color "0e8a16" --description "Safe Dependabot minor or patch update" 2>/dev/null || true
  gh label create "needs-review" --color "fbca04" --description "Needs human review" 2>/dev/null || true
  gh label create "breaking-change" --color "d73a4a" --description "Contains breaking changes" 2>/dev/null || true
}

check_downstream_sync() {
  local changed
  changed="$(git diff --name-only HEAD~1..HEAD 2>/dev/null || true)"

  if grep -qE '^(templates/|\.github/workflows/|script/wait-ci-checks\.sh)' <<<"$changed"; then
    output::warning "Downstream sync pending"
    echo "sync-downstream.yml creates sync PRs in downstream repositories after this change reaches main."
    echo "Manifest: .github/sync-downstream.json (see docs/adr/0017-downstream-template-auto-sync.md)."
    if [[ -n "${CLAUDE_BRANCH:-}" ]]; then
      git checkout "$CLAUDE_BRANCH" 2>/dev/null || git checkout -b "$CLAUDE_BRANCH"
    fi
  fi
}

run_quality_gates() {
  if [[ ! -f package.json ]]; then
    output::info "package.json not found; skipping npm quality gates"
    return 0
  fi

  npm run format:check --if-present
  npm run lint --if-present
  npm test --if-present
  npm run shellcheck --if-present
}

create_pr_if_requested() {
  if [[ "$CREATE_PR" != "true" ]]; then
    return 0
  fi

  if [[ "$MODE" == "check-only" ]]; then
    output::warning "Archived repository. Skipping PR creation."
    return 0
  fi

  if [[ -z "$(git status --porcelain)" ]]; then
    output::info "No changes to create PR"
    return 0
  fi

  local branch current_branch
  branch="${CLAUDE_BRANCH:-maintenance/$(date +%Y%m%d-%H%M%S)}"
  current_branch="$(git branch --show-current 2>/dev/null || true)"
  if [[ "$current_branch" != "$branch" ]]; then
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
      git checkout "$branch"
    else
      git checkout -b "$branch"
    fi
  fi
  git add -A
  git commit -m "chore: repository maintenance"
  git push -u origin "$branch"
  gh pr create --head "$branch" --title "chore: repository maintenance" --body "Automated repository maintenance."
}

if [[ "$CHECK_REQUIRED_WORKFLOWS_ONLY" == "true" ]]; then
  check_required_workflows
  exit $?
fi

if [[ "$CHECK_ACTIONS_PR_SETTINGS_ONLY" == "true" ]]; then
  check_actions_pr_creation_settings
  exit $?
fi

if [[ "$CHECK_SCHEDULED_MAINTENANCE_ONLY" == "true" ]]; then
  check_scheduled_maintenance_configuration
  exit $?
fi

if [[ "$CHECK_ARTIFACT_RETENTION_ONLY" == "true" ]]; then
  check_artifact_retention
  exit $?
fi

cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Repository Maintenance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mode: $MODE
Skip: ${SKIP_CATEGORIES:-None}
Create PR: $CREATE_PR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

check_repository_state

if ! has_skip "setup"; then
  if [[ "$CREATE_PR" == "true" ]]; then
    check_actions_pr_creation_settings
  else
    check_actions_pr_creation_settings || true
  fi
  check_scheduled_maintenance_configuration || true
  check_artifact_retention || true
  check_workflow_templates
  check_workflow_template_lint_coverage
  check_managed_templates
  ensure_labels
  check_required_workflows || true
fi

if ! has_skip "dependencies"; then
  check_dependency_peer_compatibility
fi

if ! has_skip "quality" && [[ "$MODE" != "check-only" ]]; then
  run_if_exists "Running quality gates" run_quality_gates
fi

if ! has_skip "discovery"; then
  check_downstream_sync
fi

create_pr_if_requested
output::success "Repository maintenance completed"
