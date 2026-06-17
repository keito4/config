#!/usr/bin/env bash
set -euo pipefail

FORMAT="markdown"

usage() {
  cat <<'USAGE'
Usage: script/audit-references.sh [--format markdown|tsv]

Audits tracked files under script/ and templates/ and reports references from:
- code/ci
- test
- docs

The scanner matches both the repository-relative path and basename so it can
find references such as "script/foo.sh" and "foo.sh".
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --format)
      FORMAT="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$FORMAT" in
  markdown|tsv) ;;
  *)
    echo "Unsupported format: $FORMAT" >&2
    exit 2
    ;;
esac

classify_source() {
  local source="$1"

  case "$source" in
    test/*)
      echo "test"
      ;;
    docs/*|README.md|AGENTS.md|CLAUDE.md|*.md)
      echo "docs"
      ;;
    .github/workflows/*|.github/actions/*|.github/dependabot.*|.github/labels.yml|.github/policies/*)
      echo "code/ci"
      ;;
    *)
      echo "code/ci"
      ;;
  esac
}

tracked_files() {
  git ls-files
}

target_files() {
  git ls-files 'script/*' 'templates/*' | while IFS= read -r file; do
    [ -f "$file" ] || continue
    printf '%s\n' "$file"
  done
}

emit_tsv_row() {
  local category="$1"
  local target="$2"
  local source="$3"

  printf '%s\t%s\t%s\n' "$category" "$target" "$source"
}

emit_markdown_list() {
  local label="$1"
  local refs="$2"

  local count
  count=$(printf '%s\n' "$refs" | sed '/^$/d' | wc -l | tr -d ' ')
  printf -- '- %s (%s)\n' "$label" "$count"
  if [ "$count" -gt 0 ]; then
    printf '%s\n' "$refs" | sed '/^$/d' | sed 's/^/  - `/' | sed 's/$/`/'
  fi
}

if [ "$FORMAT" = "markdown" ]; then
  cat <<'HEADER'
# Reference Inventory

Targets: tracked files under `script/` and `templates/`.

HEADER
else
  printf 'category\ttarget\tsource\n'
fi

ZERO_CODE_TEST=()

while IFS= read -r target; do
  basename_target=$(basename "$target")
  code_refs=""
  test_refs=""
  docs_refs=""
  mapfile -t sources < <(tracked_files)

  while IFS= read -r source; do
    [ "$source" != "$target" ] || continue
    category=$(classify_source "$source")
    case "$category" in
      test)
        test_refs="${test_refs}${source}"$'\n'
        ;;
      docs)
        docs_refs="${docs_refs}${source}"$'\n'
        ;;
      *)
        code_refs="${code_refs}${source}"$'\n'
        ;;
    esac

    if [ "$FORMAT" = "tsv" ]; then
      emit_tsv_row "$category" "$target" "$source"
    fi
  done < <(rg -l --fixed-strings -e "$target" -e "$basename_target" -- "${sources[@]}" 2>/dev/null || true)

  if [ -z "$code_refs$test_refs" ]; then
    ZERO_CODE_TEST+=("$target")
  fi

  if [ "$FORMAT" = "markdown" ]; then
    printf "## \`%s\`\n\n" "$target"
    emit_markdown_list "Code/CI references" "$code_refs"
    emit_markdown_list "Test references" "$test_refs"
    emit_markdown_list "Documentation references" "$docs_refs"
    printf '\n'
  elif [ -z "$code_refs$test_refs$docs_refs" ]; then
    emit_tsv_row "none" "$target" "-"
  fi
done < <(target_files)

if [ "$FORMAT" = "markdown" ]; then
  cat <<'SUMMARY'
## Zero Code/Test References

These targets have no code/ci or test references. Documentation-only references
are still listed above for each target.

SUMMARY
  if [ "${#ZERO_CODE_TEST[@]}" -eq 0 ]; then
    printf -- '- None\n'
  else
    printf '%s\n' "${ZERO_CODE_TEST[@]}" | sed 's/^/- `/' | sed 's/$/`/'
  fi
fi
