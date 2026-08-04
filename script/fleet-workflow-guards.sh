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

validate_inputs() {
  local repo

  if [[ ! "$DAYS" =~ ^[1-9][0-9]*$ ]]; then
    # 検証しないと date が失敗して cutoff が空になり、全リポジトリへ黙って広がる。
    output::fatal "invalid --days: $DAYS (expected a positive integer)"
  fi

  for repo in $REPOS; do
    # rm -rf する先を作るので、作業ディレクトリの外を指す名前は受け付けない。
    if [[ ! "$repo" =~ ^[A-Za-z0-9._-]+$ || "$repo" == .* ]]; then
      output::fatal "invalid repository name: $repo"
    fi
  done
}

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
# チェックアウトへ入れないときは 2 を返す。ここを握り潰すと、走査できていないのに
# 「違反なし」と報告してしまう。
scan_repo() {
  local dest="$1" guard output guard_status

  [[ -d "$dest" ]] || return 2

  for guard in "${GUARDS[@]}"; do
    # 終了ステータスを正とする。検査によっては output::warning ではなく素の
    # "file: message" を出すため、⚠ 行だけを拾うと違反が消える。依存不足などの
    # 違反以外の失敗も、黙って clean にせずここで拾う。
    # 1 つ落ちても残りを続け、まとめて直せるようにする。
    guard_status=0
    output="$(cd "$dest" || exit 1; "$SCRIPT_DIR/repo-maintenance.sh" "$guard" 2>&1)" || guard_status=$?
    [[ "$guard_status" -eq 0 ]] && continue

    if [[ -n "$output" ]]; then
      printf '%s\n' "$output"
    else
      printf '%s: failed with no output\n' "$guard"
    fi
  done
}

main() {
  local repos repo dest violations=0 summary=""

  validate_inputs

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

    local findings scan_status=0
    findings="$(scan_repo "$dest")" || scan_status=$?

    if [[ "$scan_status" -eq 2 ]]; then
      violations=$((violations + 1))
      output::warning "$repo: checkout missing; not scanned"
      summary+="| \`$repo\` | ⚠️ not scanned |"$'\n'
      continue
    fi

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
