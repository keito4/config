#!/usr/bin/env bash
# Additional checks used by script/repo-maintenance.sh.

check_scheduled_maintenance_configuration() {
  local workflow=".github/workflows/scheduled-maintenance.yml"
  local repo secrets issue_count=0
  local has_pr_token=false has_legacy_pat=false
  local has_takt_key=false has_anthropic_key=false

  [[ -f "$workflow" ]] || return 0

  if grep -qE "CLAUDE_PR_GITHUB_TOKEN|TAKT_ANTHROPIC_API_KEY" "$workflow"; then
    if command -v gh >/dev/null 2>&1; then
      repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)"
      if [[ -n "$repo" && "$repo" != "null" ]]; then
        secrets="$(gh secret list --repo "$repo" --json name --jq '.[].name' 2>/dev/null || true)"
        if grep -q "CLAUDE_PR_GITHUB_TOKEN" "$workflow"; then
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
        if grep -q "TAKT_ANTHROPIC_API_KEY" "$workflow"; then
          grep -Fxq "TAKT_ANTHROPIC_API_KEY" <<<"$secrets" && has_takt_key=true
          grep -Fxq "ANTHROPIC_API_KEY" <<<"$secrets" && has_anthropic_key=true
          if [[ "$has_takt_key" != "true" && "$has_anthropic_key" != "true" ]]; then
            output::warning "scheduled-maintenance.yml requires TAKT_ANTHROPIC_API_KEY or ANTHROPIC_API_KEY secret"
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
