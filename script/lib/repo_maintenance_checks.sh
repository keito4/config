#!/usr/bin/env bash
# Additional checks used by script/repo-maintenance.sh.

check_scheduled_maintenance_configuration() {
  local workflow=".github/workflows/scheduled-maintenance.yml"
  local repo secrets issue_count=0
  local has_pr_token=false has_legacy_pat=false
  local has_takt_key=false has_anthropic_key=false has_oauth_token=false

  [[ -f "$workflow" ]] || return 0

  if grep -qE "CLAUDE_PR_GITHUB_TOKEN|CLAUDE_PAT|CLAUDE_CODE_OAUTH_TOKEN|TAKT_ANTHROPIC_API_KEY|ANTHROPIC_API_KEY" "$workflow"; then
    if command -v gh >/dev/null 2>&1; then
      repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)"
      if [[ -n "$repo" && "$repo" != "null" ]]; then
        secrets="$(gh secret list --repo "$repo" --json name --jq '.[].name' 2>/dev/null || true)"
        if grep -qE "CLAUDE_PR_GITHUB_TOKEN|CLAUDE_PAT" "$workflow"; then
          grep -Fxq "CLAUDE_PR_GITHUB_TOKEN" <<<"$secrets" && has_pr_token=true
          if grep -q "CLAUDE_PAT" "$workflow" && grep -Fxq "CLAUDE_PAT" <<<"$secrets"; then
            has_legacy_pat=true
          fi
          if [[ "$has_pr_token" != "true" && "$has_legacy_pat" != "true" ]]; then
            output::warning "scheduled-maintenance.yml requires CLAUDE_PR_GITHUB_TOKEN or CLAUDE_PAT secret"
            echo "Settings: https://github.com/$repo/settings/secrets/actions"
            issue_count=$((issue_count + 1))
          fi
        fi
        if grep -qE "CLAUDE_CODE_OAUTH_TOKEN|TAKT_ANTHROPIC_API_KEY|ANTHROPIC_API_KEY" "$workflow"; then
          grep -Fxq "CLAUDE_CODE_OAUTH_TOKEN" <<<"$secrets" && has_oauth_token=true
          grep -Fxq "TAKT_ANTHROPIC_API_KEY" <<<"$secrets" && has_takt_key=true
          grep -Fxq "ANTHROPIC_API_KEY" <<<"$secrets" && has_anthropic_key=true
          if [[ "$has_oauth_token" != "true" && "$has_takt_key" != "true" && "$has_anthropic_key" != "true" ]]; then
            output::warning "scheduled-maintenance.yml requires CLAUDE_CODE_OAUTH_TOKEN, TAKT_ANTHROPIC_API_KEY, or ANTHROPIC_API_KEY secret"
            echo "Settings: https://github.com/$repo/settings/secrets/actions"
            issue_count=$((issue_count + 1))
          fi
        fi
      else
        output::warning "Scheduled Maintenance secret check skipped: repository unavailable"
      fi
    else
      output::warning "Scheduled Maintenance secret check skipped: gh not found"
    fi
  fi

  if grep -q "name: Post failure issue" "$workflow" \
    && ! grep -q "GH_REPO: \${{ github.repository }}" "$workflow" \
    && ! grep -q -- "--repo \"\$GITHUB_REPOSITORY\"" "$workflow"; then
    output::warning "scheduled-maintenance.yml failure issue step needs GH_REPO or --repo"
    issue_count=$((issue_count + 1))
  fi

  if [[ "$issue_count" -gt 0 ]]; then
    return 1
  fi

  output::success "Scheduled Maintenance configuration ok"
}

# Claude CLI は ANTHROPIC_API_KEY を CLAUDE_CODE_OAUTH_TOKEN より優先する（ADR 0013）。
# 両方を無条件に claude-code-action へ渡すと、失効した API キーが有効な OAuth トークンを
# 握り潰す。失敗は無言（is_error:true / num_turns:1 / total_cost_usd:0 / エラー本文なし）で、
# 約 180 秒リトライしてから終わるため気付きにくい。
check_claude_action_credentials() {
  local workflow issue_count=0 stripped

  for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
    [[ -f "$workflow" ]] || continue

    # 行頭コメントを落とす。注意書きの中の文字列を実設定と誤認しないため。
    stripped="$(sed 's/^[[:space:]]*#.*$//' "$workflow")"

    grep -q "anthropics/claude-code-action" <<<"$stripped" || continue
    grep -q "claude_code_oauth_token:" <<<"$stripped" || continue

    if grep -qE "^[[:space:]]*anthropic_api_key:" <<<"$stripped" \
      && ! grep -qE "^[[:space:]]*anthropic_api_key:.*CLAUDE_CODE_OAUTH_TOKEN" <<<"$stripped"; then
      output::warning "$(basename "$workflow"): anthropic_api_key overrides CLAUDE_CODE_OAUTH_TOKEN"
      echo "Pass the API key only when the OAuth token is empty:"
      echo "  anthropic_api_key: \${{ secrets.CLAUDE_CODE_OAUTH_TOKEN == '' && secrets.ANTHROPIC_API_KEY || '' }}"
      issue_count=$((issue_count + 1))
    fi
  done

  if [[ "$issue_count" -gt 0 ]]; then
    return 1
  fi

  output::success "Claude Actions credential precedence ok"
}

# push で起動するワークフローが自分でコミットや Release を publish すると、その push が
# 起こす新規実行に cancel-in-progress: true で自分自身をキャンセルされる。
# keito4/intent-gate-android では v1.2.49 の APK 添付と Firebase 配信が失われた。
check_self_cancelling_workflows() {
  local workflow issue_count=0 stripped

  for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
    [[ -f "$workflow" ]] || continue

    stripped="$(sed 's/^[[:space:]]*#.*$//' "$workflow")"

    grep -qE "^[[:space:]]*cancel-in-progress:[[:space:]]*true[[:space:]]*$" <<<"$stripped" || continue
    grep -qE "^[[:space:]]*push:" <<<"$stripped" || continue
    grep -qE "git push|peter-evans/create-pull-request|softprops/action-gh-release|googleapis/release-please" <<<"$stripped" || continue

    output::warning "$(basename "$workflow"): cancel-in-progress cancels this workflow's own push"
    echo "Scope the cancellation to pull requests so pushes to the default branch run to completion:"
    echo "  cancel-in-progress: \${{ github.event_name == 'pull_request' }}"
    issue_count=$((issue_count + 1))
  done

  if [[ "$issue_count" -gt 0 ]]; then
    return 1
  fi

  output::success "Workflow self-cancellation guards ok"
}

# checkout を実行しないジョブでは gh がリポジトリを git から解決できない。
# `gh pr edit "$PR_URL"` は URL 引数から特定できるため通ってしまい、引数を持たない
# `gh label create` だけが "fatal: not a git repository" で落ちるので気付きにくい。
check_gh_repo_context() {
  local workflow issue_count=0 stripped

  for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
    [[ -f "$workflow" ]] || continue

    stripped="$(sed 's/^[[:space:]]*#.*$//' "$workflow")"

    # checkout していればリポジトリは解決できる。
    grep -q "actions/checkout" <<<"$stripped" && continue
    grep -qE "\bgh (label|issue|release|run|workflow|pr (create|list|status))\b" <<<"$stripped" || continue
    grep -qE "GH_REPO:|--repo " <<<"$stripped" && continue

    output::warning "$(basename "$workflow"): gh has no repository to resolve without a checkout"
    echo "Add the repository to the step environment:"
    echo "  GH_REPO: \${{ github.repository }}"
    issue_count=$((issue_count + 1))
  done

  if [[ "$issue_count" -gt 0 ]]; then
    return 1
  fi

  output::success "gh repository context ok"
}

check_artifact_retention() {
  local workflow issue_count=0

  for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
    [[ -f "$workflow" ]] || continue
    if ! awk -v file="$(basename "$workflow")" '
      /^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*actions\/upload-artifact@/ {
        in_upload = 1
        has_retention = 0
        next
      }
      in_upload && /^[[:space:]]*retention-days:[[:space:]]*/ {
        has_retention = 1
        value = $0
        sub(/.*retention-days:[[:space:]]*/, "", value)
        sub(/[[:space:]#].*/, "", value)
        if (value + 0 > 30) {
          printf "%s: artifact retention-days is %s (expected <= 30)\n", file, value
          bad = 1
        }
        next
      }
      in_upload && /^[[:space:]]*-[[:space:]]*(name|uses):/ {
        if (!has_retention) {
          printf "%s: upload-artifact missing retention-days\n", file
          bad = 1
        }
        in_upload = ($0 ~ /uses:[[:space:]]*actions\/upload-artifact@/)
        has_retention = 0
      }
      END {
        if (in_upload && !has_retention) {
          printf "%s: upload-artifact missing retention-days\n", file
          bad = 1
        }
        exit bad ? 1 : 0
      }
    ' "$workflow"; then
      issue_count=$((issue_count + 1))
    fi
  done

  if [[ "$issue_count" -gt 0 ]]; then
    return 1
  fi

  output::success "Artifact retention settings ok"
}
