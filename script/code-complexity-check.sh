#!/usr/bin/env bash
# Code Complexity Check - Analyze code complexity

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Options
THRESHOLD=10
REPORT_FILE=""
FILE_PATTERN="script/*.sh"
STRICT_MODE=false
JSON_OUTPUT=false

# Parse arguments
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
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --threshold N        Complexity threshold (default: 10)"
      echo "  --report FILE        Generate report file"
      echo "  --files PATTERN      File pattern to check (default: script/*.sh)"
      echo "  --strict             Fail on high complexity"
      echo "  --json               JSON output"
      echo "  --help               Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ "$JSON_OUTPUT" = false ]; then
  echo -e "${BLUE}🔍 Code Complexity Analysis${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# Simple complexity estimation for shell scripts
estimate_complexity() {
  local file=$1
  local complexity=1

  # Count decision points
  local if_count=$(grep -c "if \[" "$file" 2>/dev/null || echo "0")
  local case_count=$(grep -c "case " "$file" 2>/dev/null || echo "0")
  local while_count=$(grep -c "while " "$file" 2>/dev/null || echo "0")
  local for_count=$(grep -c "for " "$file" 2>/dev/null || echo "0")
  local and_count=$(grep -c " && " "$file" 2>/dev/null || echo "0")
  local or_count=$(grep -c " || " "$file" 2>/dev/null || echo "0")

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
    local opens=$(echo "$line" | grep -o "{" | wc -l | tr -d ' ')
    local closes=$(echo "$line" | grep -o "}" | wc -l | tr -d ' ')

    current_depth=$((current_depth + opens - closes))

    if [ $current_depth -gt $max_depth ]; then
      max_depth=$current_depth
    fi
  done < "$file"

  echo "$max_depth"
}

# Analyze files
declare -A FILE_COMPLEXITY
declare -A FILE_LENGTH
declare -A FILE_NESTING
TOTAL_FILES=0
HIGH_COMPLEXITY_COUNT=0
CRITICAL_COMPLEXITY_COUNT=0

# shellcheck disable=SC2086
for file in $FILE_PATTERN; do
  if [ -f "$file" ]; then
    ((TOTAL_FILES++))

    COMPLEXITY=$(estimate_complexity "$file")
    LENGTH=$(get_function_length "$file")
    NESTING=$(get_max_nesting "$file")

    FILE_COMPLEXITY["$file"]=$COMPLEXITY
    FILE_LENGTH["$file"]=$LENGTH
    FILE_NESTING["$file"]=$NESTING

    if [ "$COMPLEXITY" -ge 20 ]; then
      ((CRITICAL_COMPLEXITY_COUNT++))
    elif [ "$COMPLEXITY" -ge "$THRESHOLD" ]; then
      ((HIGH_COMPLEXITY_COUNT++))
    fi
  fi
done

if [ $TOTAL_FILES -eq 0 ]; then
  echo "No files found matching pattern: $FILE_PATTERN"
  exit 0
fi

# Calculate average complexity
TOTAL_COMPLEXITY=0
for complexity in "${FILE_COMPLEXITY[@]}"; do
  TOTAL_COMPLEXITY=$((TOTAL_COMPLEXITY + complexity))
done
AVG_COMPLEXITY=$((TOTAL_COMPLEXITY / TOTAL_FILES))

if [ "$JSON_OUTPUT" = true ]; then
  # JSON output
  cat <<EOF
{
  "total_files": $TOTAL_FILES,
  "average_complexity": $AVG_COMPLEXITY,
  "high_complexity_count": $HIGH_COMPLEXITY_COUNT,
  "critical_complexity_count": $CRITICAL_COMPLEXITY_COUNT,
  "threshold": $THRESHOLD
}
EOF
else
  # Human-readable output
  echo -e "${BLUE}📊 Overall Complexity Score: $AVG_COMPLEXITY/20${NC}"

  if [ $AVG_COMPLEXITY -lt 5 ]; then
    echo -e "   ${GREEN}(Excellent)${NC}"
  elif [ $AVG_COMPLEXITY -lt 10 ]; then
    echo -e "   ${GREEN}(Good)${NC}"
  elif [ $AVG_COMPLEXITY -lt 15 ]; then
    echo -e "   ${YELLOW}(Fair)${NC}"
  else
    echo -e "   ${RED}(Poor)${NC}"
  fi
  echo ""

  # Distribution
  LOW_COUNT=0
  MED_COUNT=0
  for complexity in "${FILE_COMPLEXITY[@]}"; do
    if [ "$complexity" -lt 5 ]; then
      ((LOW_COUNT++))
    elif [ "$complexity" -lt 10 ]; then
      ((MED_COUNT++))
    fi
  done

  echo -e "${BLUE}📈 Distribution${NC}"
  echo "  Low (< 5):       $LOW_COUNT files"
  echo "  Medium (5-10):   $MED_COUNT files"
  echo "  High (10-20):    $HIGH_COMPLEXITY_COUNT files"
  echo "  Critical (> 20): $CRITICAL_COMPLEXITY_COUNT files"
  echo ""

  # Show high complexity files
  if [ $HIGH_COMPLEXITY_COUNT -gt 0 ] || [ $CRITICAL_COMPLEXITY_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️ Complex Files${NC}"
    echo ""

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
  if [ $AVG_COMPLEXITY -gt 10 ]; then
    echo "  3. Overall complexity is high - consider general refactoring"
  else
    echo "  ✅ Code complexity is within acceptable limits"
  fi
fi

# Write report
if [ -n "$REPORT_FILE" ]; then
  {
    echo "# Code Complexity Report"
    echo ""
    echo "Generated: $(date)"
    echo ""
    echo "## Summary"
    echo ""
    echo "- Total Files: $TOTAL_FILES"
    echo "- Average Complexity: $AVG_COMPLEXITY"
    echo "- High Complexity: $HIGH_COMPLEXITY_COUNT"
    echo "- Critical Complexity: $CRITICAL_COMPLEXITY_COUNT"
    echo ""
    echo "## File Details"
    echo ""
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
fi

# Exit code for strict mode
if [ "$STRICT_MODE" = true ] && [ $CRITICAL_COMPLEXITY_COUNT -gt 0 ]; then
  exit 1
fi

exit 0
