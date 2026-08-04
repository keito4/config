#!/usr/bin/env bash
# Run the repo-maintenance workflow guards across several repositories.
#
# The guards only read workflow YAML, so they run unchanged against any
# repository checkout. Keeping them here means a fix to a guard reaches every
# repository at once, without distributing this script downstream.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=script/lib/output.sh
source "$SCRIPT_DIR/lib/output.sh"

OWNER="${FLEET_OWNER:-keito4}"
DAYS="90"
REPOS=""
WORK_DIR="${FLEET_WORK_DIR:-${CONTEXT_DIR:-.context}/fleet}"

GUARDS=(
  --check-claude-action-credentials
  --check-self-cancelling-workflows
  --check-gh-repo-context
  --check-artifact-retention
)

usage() {
  cat <<'EOF'
Usage: script/fleet-workflow-guards.sh [--owner OWNER] [--days N] [--repos "name ..."]

Scans each repository with the repo-maintenance workflow guards and prints a
markdown summary. Exits non-zero when any repository reports a violation.

  --owner OWNER   GitHub owner to scan (default: keito4)
  --days N        Only scan repositories pushed within N days (default: 90)
  --repos "..."   Scan exactly these repository names, skipping discovery
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)
      OWNER="${2:?--owner requires a value}"
      shift 2
      ;;
    --days)
      DAYS="${2:?--days requires a value}"
      shift 2
      ;;
    --repos)
      REPOS="${2:?--repos requires a value}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      output::fatal "Unknown argument: $1"
      ;;
  esac
done

discover_repos() {
  local cutoff
  # 直近いじったリポジトリだけを対象にする。アーカイブ済みは除外する。
  cutoff="$(date -u -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null || date -u -d "${DAYS} days ago" +%Y-%m-%d)"
  gh repo list "$OWNER" \
    --limit 200 \
    --no-archived \
    --json name,pushedAt \
    --jq "[.[] | select(.pushedAt >= \"$cutoff\")] | .[].name"
}

# 1 リポジトリ分の違反行を stdout へ出す。違反が無ければ何も出さない。
scan_repo() {
  local repo="$1" dest="$2" guard findings=""

  for guard in "${GUARDS[@]}"; do
    # 1 つ落ちても残りの検査を続ける。まとめて直せるようにするため。
    findings+="$(cd "$dest" && "$SCRIPT_DIR/repo-maintenance.sh" "$guard" 2>&1 | grep -E '^(⚠|.*\[1;33m)' || true)"$'\n'
  done

  printf '%s' "$findings" | sed '/^[[:space:]]*$/d'
}

main() {
  local repos repo dest violations=0 summary=""

  if [[ -n "$REPOS" ]]; then
    read -r -a repos <<<"$REPOS"
  else
    mapfile -t repos < <(discover_repos)
  fi

  if [[ "${#repos[@]}" -eq 0 ]]; then
    output::warning "No repositories to scan"
    return 0
  fi

  mkdir -p "$WORK_DIR"
  summary+="## Workflow guard scan"$'\n\n'
  summary+="| Repository | Result |"$'\n'
  summary+="| --- | --- |"$'\n'

  for repo in "${repos[@]}"; do
    [[ -n "$repo" ]] || continue
    dest="$WORK_DIR/$repo"
    rm -rf "$dest"

    if ! gh repo clone "$OWNER/$repo" "$dest" -- --depth 1 --no-tags >/dev/null 2>&1; then
      output::warning "$repo: clone failed; skipped"
      summary+="| \`$repo\` | ⚠️ clone failed |"$'\n'
      continue
    fi

    local findings
    findings="$(scan_repo "$repo" "$dest")"

    if [[ -n "$findings" ]]; then
      violations=$((violations + 1))
      output::warning "$repo"
      printf '%s\n' "$findings"
      summary+="| \`$repo\` | ❌ $(printf '%s' "$findings" | grep -c . ) violation(s) |"$'\n'
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        summary+="| | $(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g; s/^[[:space:]]*⚠[[:space:]]*//') |"$'\n'
      done <<<"$findings"
    else
      output::success "$repo"
      summary+="| \`$repo\` | ✅ clean |"$'\n'
    fi
  done

  if [[ "$violations" -eq 0 ]]; then
    summary+=$'\n'"No workflow guard violations across ${#repos[@]} repositories."$'\n'
    output::success "No workflow guard violations across ${#repos[@]} repositories"
  else
    summary+=$'\n'"$violations of ${#repos[@]} repositories reported violations."$'\n'
  fi

  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf '%s' "$summary" >>"$GITHUB_STEP_SUMMARY"
  fi

  [[ "$violations" -eq 0 ]]
}

main
