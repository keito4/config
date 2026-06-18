#!/usr/bin/env bash
set -euo pipefail

TRIVYIGNORE_FILE="${1:-.trivyignore}"
TODAY="${TODAY:-$(date -u +%F)}"

if [ ! -f "$TRIVYIGNORE_FILE" ]; then
  echo "error: $TRIVYIGNORE_FILE not found" >&2
  exit 2
fi

due_entries=()
review_date=""

while IFS= read -r line; do
  case "$line" in
    \#\ Review\ date:\ *)
      review_date=${line#"# Review date: "}
      ;;
    CVE-*)
      cve=${line%%[[:space:]]*}
      if [ -n "$review_date" ] && { [[ "$review_date" < "$TODAY" ]] || [[ "$review_date" == "$TODAY" ]]; }; then
        due_entries+=("$cve (review date: $review_date)")
      fi
      review_date=""
      ;;
  esac
done < "$TRIVYIGNORE_FILE"

if [ "${#due_entries[@]}" -eq 0 ]; then
  echo "ok: no .trivyignore entries are due for review as of $TODAY"
  exit 0
fi

echo "Trivy ignore entries due for review as of $TODAY:"
for entry in "${due_entries[@]}"; do
  echo "- $entry"
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::warning title=.trivyignore review due::$entry"
  fi
done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Trivy Ignore Review"
    echo ""
    echo "Entries due for review as of \`$TODAY\`:"
    for entry in "${due_entries[@]}"; do
      echo "- \`$entry\`"
    done
  } >> "$GITHUB_STEP_SUMMARY"
fi
