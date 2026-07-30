#!/usr/bin/env bash
# Code Complexity Check - Analyze code complexity

set -euo pipefail

# Source shared output library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/output.sh" 2>/dev/null || {
  readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
}

# Options
THRESHOLD=10
REPORT_FILE=""
FILE_PATTERN="script/*.sh"
STRICT_MODE=false
JSON_OUTPUT=false

print_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --threshold N        Complexity threshold (default: 10)"
  echo "  --report FILE        Generate report file"
  echo "  --files PATTERN      File pattern to check (default: script/*.sh)"
  echo "  --strict             Fail on high complexity"
  echo "  --json               JSON output"
  echo "  --help               Show this help message"
}

# Parse CLI options into the global THRESHOLD/REPORT_FILE/FILE_PATTERN/STRICT_MODE/JSON_OUTPUT vars
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --threshold)
        THRESHOLD="$2"
        shift 2
        ;;
      --report)
        REPORT_FILE="$2"
        shift 2
        ;;
      --files)
        FILE_PATTERN="$2"
        shift 2
        ;;
      --strict)
        STRICT_MODE=true
        shift
        ;;
      --json)
        JSON_OUTPUT=true
        shift
        ;;
      --help)
        print_usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
  done
}

# Count occurrences of a pattern in a file, defaulting to 0 when absent/unreadable
count_occurrences() {
  local pattern=$1
  local file=$2
  local count

  count=$(grep -c "$pattern" "$file" 2>/dev/null) || count=0
  echo "$count"
}

# Simple complexity estimation for shell scripts
estimate_complexity() {
  local file=$1
  local complexity=1

  # Count decision points
  local if_count
  local case_count
  local while_count
  local for_count
  local and_count
  local or_count

  if_count=$(count_occurrences "if \[" "$file")
  case_count=$(count_occurrences "case " "$file")
  while_count=$(count_occurrences "while " "$file")
  for_count=$(count_occurrences "for " "$file")
  and_count=$(count_occurrences " && " "$file")
  or_count=$(count_occurrences " || " "$file")

  complexity=$((complexity + if_count + case_count + while_count + for_count + and_count + or_count))

  echo "$complexity"
}

# Calculate function length
get_function_length() {
  local file=$1
  wc -l < "$file" | tr -d ' '
}

# Calculate nesting depth (simplified)
get_max_nesting() {
  local file=$1
  local max_depth=0
  local current_depth=0

  while IFS= read -r line; do
    # Increment depth on opening braces
    local opens
    local closes

    opens=$(echo "$line" | grep -o "{" | wc -l | tr -d ' ')
    closes=$(echo "$line" | grep -o "}" | wc -l | tr -d ' ')

    current_depth=$((current_depth + opens - closes))

    if [ $current_depth -gt $max_depth ]; then
      max_depth=$current_depth
    fi
  done < "$file"

  echo "$max_depth"
}

# Analyze every file matching FILE_PATTERN, populating the FILE_* maps and counters
declare -A FILE_COMPLEXITY
declare -A FILE_LENGTH
declare -A FILE_NESTING
TOTAL_FILES=0
HIGH_COMPLEXITY_COUNT=0
CRITICAL_COMPLEXITY_COUNT=0

analyze_files() {
  # shellcheck disable=SC2086
  for file in $FILE_PATTERN; do
    if [ -f "$file" ]; then
      TOTAL_FILES=$((TOTAL_FILES + 1))

      COMPLEXITY=$(estimate_complexity "$file")
      LENGTH=$(get_function_length "$file")
      NESTING=$(get_max_nesting "$file")

      FILE_COMPLEXITY["$file"]=$COMPLEXITY
      FILE_LENGTH["$file"]=$LENGTH
      FILE_NESTING["$file"]=$NESTING

      if [ "$COMPLEXITY" -ge 20 ]; then
        CRITICAL_COMPLEXITY_COUNT=$((CRITICAL_COMPLEXITY_COUNT + 1))
      elif [ "$COMPLEXITY" -ge "$THRESHOLD" ]; then
        HIGH_COMPLEXITY_COUNT=$((HIGH_COMPLEXITY_COUNT + 1))
      fi
    fi
  done
}

# Sum FILE_COMPLEXITY values and echo the integer average across TOTAL_FILES
compute_average_complexity() {
  local total=0
  local complexity

  for complexity in "${FILE_COMPLEXITY[@]}"; do
    total=$((total + complexity))
  done

  echo $((total / TOTAL_FILES))
}

render_json_output() {
  local avg_complexity=$1

  cat <<EOF
{
  "total_files": $TOTAL_FILES,
  "average_complexity": $avg_complexity,
  "high_complexity_count": $HIGH_COMPLEXITY_COUNT,
  "critical_complexity_count": $CRITICAL_COMPLEXITY_COUNT,
  "threshold": $THRESHOLD
}
EOF
}

render_human_output() {
  local avg_complexity=$1

  echo -e "${BLUE}📊 Overall Complexity Score: $avg_complexity/20${NC}"

  if [ "$avg_complexity" -lt 5 ]; then
    echo -e "   ${GREEN}(Excellent)${NC}"
  elif [ "$avg_complexity" -lt 10 ]; then
    echo -e "   ${GREEN}(Good)${NC}"
  elif [ "$avg_complexity" -lt 15 ]; then
    echo -e "   ${YELLOW}(Fair)${NC}"
  else
    echo -e "   ${RED}(Poor)${NC}"
  fi
  echo ""

  # Distribution
  local low_count=0
  local med_count=0
  local complexity
  for complexity in "${FILE_COMPLEXITY[@]}"; do
    if [ "$complexity" -lt 5 ]; then
      low_count=$((low_count + 1))
    elif [ "$complexity" -lt 10 ]; then
      med_count=$((med_count + 1))
    fi
  done

  echo -e "${BLUE}📈 Distribution${NC}"
  echo "  Low (< 5):       $low_count files"
  echo "  Medium (5-10):   $med_count files"
  echo "  High (10-20):    $HIGH_COMPLEXITY_COUNT files"
  echo "  Critical (> 20): $CRITICAL_COMPLEXITY_COUNT files"
  echo ""

  # Show high complexity files
  if [ $HIGH_COMPLEXITY_COUNT -gt 0 ] || [ $CRITICAL_COMPLEXITY_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️ Complex Files${NC}"
    echo ""

    local file
    for file in "${!FILE_COMPLEXITY[@]}"; do
      COMPLEXITY=${FILE_COMPLEXITY["$file"]}
      LENGTH=${FILE_LENGTH["$file"]}
      NESTING=${FILE_NESTING["$file"]}

      if [ "$COMPLEXITY" -ge "$THRESHOLD" ]; then
        if [ "$COMPLEXITY" -ge 20 ]; then
          echo -e "${RED}🚨 CRITICAL: $file${NC}"
        else
          echo -e "${YELLOW}⚠️ $file${NC}"
        fi
        echo "   Complexity: $COMPLEXITY"
        echo "   Length: $LENGTH lines"
        echo "   Max nesting: $NESTING levels"
        echo "   Recommendation: Consider refactoring"
        echo ""
      fi
    done
  fi

  # Recommendations
  echo -e "${BLUE}💡 Recommendations${NC}"
  if [ $CRITICAL_COMPLEXITY_COUNT -gt 0 ]; then
    echo "  1. 🚨 Refactor $CRITICAL_COMPLEXITY_COUNT critical complexity files"
  fi
  if [ $HIGH_COMPLEXITY_COUNT -gt 0 ]; then
    echo "  2. Review $HIGH_COMPLEXITY_COUNT high complexity files"
  fi
  if [ "$avg_complexity" -gt 10 ]; then
    echo "  3. Overall complexity is high - consider general refactoring"
  else
    echo "  ✅ Code complexity is within acceptable limits"
  fi
}

write_report() {
  local avg_complexity=$1

  {
    echo "# Code Complexity Report"
    echo ""
    echo "Generated: $(date)"
    echo ""
    echo "## Summary"
    echo ""
    echo "- Total Files: $TOTAL_FILES"
    echo "- Average Complexity: $avg_complexity"
    echo "- High Complexity: $HIGH_COMPLEXITY_COUNT"
    echo "- Critical Complexity: $CRITICAL_COMPLEXITY_COUNT"
    echo ""
    echo "## File Details"
    echo ""
    local file
    for file in "${!FILE_COMPLEXITY[@]}"; do
      echo "### $file"
      echo ""
      echo "- Complexity: ${FILE_COMPLEXITY["$file"]}"
      echo "- Length: ${FILE_LENGTH["$file"]} lines"
      echo "- Nesting: ${FILE_NESTING["$file"]} levels"
      echo ""
    done
  } > "$REPORT_FILE"
  echo ""
  echo "Report written to: $REPORT_FILE"
}

main() {
  parse_args "$@"

  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}🔍 Code Complexity Analysis${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi

  analyze_files

  if [ $TOTAL_FILES -eq 0 ]; then
    echo "No files found matching pattern: $FILE_PATTERN"
    exit 0
  fi

  local avg_complexity
  avg_complexity=$(compute_average_complexity)

  if [ "$JSON_OUTPUT" = true ]; then
    render_json_output "$avg_complexity"
  else
    render_human_output "$avg_complexity"
  fi

  if [ -n "$REPORT_FILE" ]; then
    write_report "$avg_complexity"
  fi

  # Exit code for strict mode
  if [ "$STRICT_MODE" = true ] && [ $CRITICAL_COMPLEXITY_COUNT -gt 0 ]; then
    exit 1
  fi

  exit 0
}

main "$@"
