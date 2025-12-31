#!/usr/bin/env bash
# Test Coverage Trend - Track coverage over time

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'  # shellcheck disable=SC2034
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Options
DAYS=30
SHOW_GRAPH=false
DETAILED=false  # shellcheck disable=SC2034
EXPORT_CSV=""
JSON_OUTPUT=false
RECORD_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --days)
      DAYS="$2"
      shift 2
      ;;
    --graph)
      SHOW_GRAPH=true
      shift
      ;;
    --detailed)
      DETAILED=true
      shift
      ;;
    --export)
      EXPORT_CSV="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --record)
      RECORD_MODE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --days N          Show last N days (default: 30)"
      echo "  --graph           Show ASCII graph"
      echo "  --detailed        Show per-file details"
      echo "  --export FILE     Export to CSV"
      echo "  --json            JSON output"
      echo "  --record          Record current coverage"
      echo "  --help            Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

HISTORY_DIR=".coverage-history"
mkdir -p "$HISTORY_DIR"

# Record current coverage
if [ "$RECORD_MODE" = true ]; then
  if [ ! -f "coverage/coverage-summary.json" ]; then
    echo "Error: coverage/coverage-summary.json not found"
    echo "Run: npm run test:coverage"
    exit 1
  fi

  DATE=$(date +%Y-%m-%d)
  COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

  # Extract coverage metrics
  LINE_COV=$(node -pe "JSON.parse(require('fs').readFileSync('coverage/coverage-summary.json')).total.lines.pct")
  BRANCH_COV=$(node -pe "JSON.parse(require('fs').readFileSync('coverage/coverage-summary.json')).total.branches.pct")
  FUNC_COV=$(node -pe "JSON.parse(require('fs').readFileSync('coverage/coverage-summary.json')).total.functions.pct")
  STMT_COV=$(node -pe "JSON.parse(require('fs').readFileSync('coverage/coverage-summary.json')).total.statements.pct")

  # Save to history
  cat > "$HISTORY_DIR/$DATE.json" <<EOF
{
  "date": "$DATE",
  "commit": "$COMMIT",
  "coverage": {
    "lines": $LINE_COV,
    "branches": $BRANCH_COV,
    "functions": $FUNC_COV,
    "statements": $STMT_COV
  }
}
EOF

  echo "Coverage recorded for $DATE"
  exit 0
fi

# Display trend
if [ "$JSON_OUTPUT" = false ]; then
  echo -e "${BLUE}📊 Test Coverage Trend${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# Find history files
HISTORY_FILES=()
while IFS= read -r file; do
  HISTORY_FILES+=("$file")
done < <(find "$HISTORY_DIR" -name "*.json" -type f | sort -r | head -n "$DAYS")

if [ ${#HISTORY_FILES[@]} -eq 0 ]; then
  echo "No coverage history found."
  echo "Run with --record after running tests to start tracking"
  exit 0
fi

# Calculate statistics
TOTAL=0
MIN=100
MAX=0
OLDEST_COV=0
NEWEST_COV=0
COUNT=0

for file in "${HISTORY_FILES[@]}"; do
  if [ -f "$file" ]; then
    COV=$(node -pe "JSON.parse(require('fs').readFileSync('$file')).coverage.lines" 2>/dev/null || echo "0")

    if (( $(echo "$COV > 0" | bc -l) )); then
      TOTAL=$(echo "$TOTAL + $COV" | bc)
      ((COUNT++))

      if (( $(echo "$COV < $MIN" | bc -l) )); then
        MIN=$COV
      fi

      if (( $(echo "$COV > $MAX" | bc -l) )); then
        MAX=$COV
      fi

      if [ $COUNT -eq 1 ]; then
        NEWEST_COV=$COV
      fi
      OLDEST_COV=$COV
    fi
  fi
done

if [ $COUNT -eq 0 ]; then
  echo "No valid coverage data found"
  exit 0
fi

AVG=$(echo "scale=1; $TOTAL / $COUNT" | bc)

# Current coverage (most recent)
CURRENT_FILE="${HISTORY_FILES[0]}"
CURRENT_LINE=$(node -pe "JSON.parse(require('fs').readFileSync('$CURRENT_FILE')).coverage.lines")
CURRENT_BRANCH=$(node -pe "JSON.parse(require('fs').readFileSync('$CURRENT_FILE')).coverage.branches")
CURRENT_FUNC=$(node -pe "JSON.parse(require('fs').readFileSync('$CURRENT_FILE')).coverage.functions")
CURRENT_STMT=$(node -pe "JSON.parse(require('fs').readFileSync('$CURRENT_FILE')).coverage.statements")

if [ "$JSON_OUTPUT" = true ]; then
  # JSON output
  cat <<EOF
{
  "current": {
    "lines": $CURRENT_LINE,
    "branches": $CURRENT_BRANCH,
    "functions": $CURRENT_FUNC,
    "statements": $CURRENT_STMT
  },
  "statistics": {
    "average": $AVG,
    "min": $MIN,
    "max": $MAX
  },
  "trend": "$(if (( $(echo "$NEWEST_COV > $OLDEST_COV" | bc -l) )); then echo "improving"; else echo "declining"; fi)",
  "days": $COUNT
}
EOF
else
  # Human-readable output
  echo -e "${BLUE}📊 Current Coverage${NC}"
  echo "  • Lines: $CURRENT_LINE%"
  echo "  • Branches: $CURRENT_BRANCH%"
  echo "  • Functions: $CURRENT_FUNC%"
  echo "  • Statements: $CURRENT_STMT%"
  echo ""

  if (( $(echo "$CURRENT_LINE >= 70" | bc -l) )); then
    echo -e "${GREEN}✅ Above threshold (70%)${NC}"
  else
    echo -e "${RED}🚨 Below threshold (70%)${NC}"
  fi
  echo ""

  echo -e "${BLUE}📈 Statistics (last $COUNT days)${NC}"
  echo "  • Average: $AVG%"
  echo "  • Min: $MIN%"
  echo "  • Max: $MAX%"

  # Trend
  TREND_DIFF=$(echo "$NEWEST_COV - $OLDEST_COV" | bc)
  if (( $(echo "$TREND_DIFF > 2" | bc -l) )); then
    echo -e "  • Trend: ${GREEN}↗ Improving (+${TREND_DIFF}% over period)${NC}"
  elif (( $(echo "$TREND_DIFF < -2" | bc -l) )); then
    echo -e "  • Trend: ${RED}↘ Declining (${TREND_DIFF}% over period)${NC}"
  else
    echo "  • Trend: → Stable"
  fi
  echo ""

  # Simple ASCII graph
  if [ "$SHOW_GRAPH" = true ]; then
    echo -e "${BLUE}📈 Coverage Trend${NC}"
    echo ""
    # This is a simplified visualization
    # A full implementation would use actual charting
    echo "  (Graph visualization would appear here)"
    echo ""
  fi

  # Recommendations
  echo -e "${BLUE}💡 Recommendations${NC}"
  if (( $(echo "$CURRENT_LINE < 70" | bc -l) )); then
    echo "  • Coverage is below 70% threshold"
    echo "  • Add more tests to improve coverage"
  elif (( $(echo "$TREND_DIFF < -2" | bc -l) )); then
    echo "  • Coverage is declining"
    echo "  • Review recent changes and add missing tests"
  else
    echo "  • Coverage trend is positive - keep it up!"
  fi
fi

# Export to CSV
if [ -n "$EXPORT_CSV" ]; then
  echo "date,commit,lines,branches,functions,statements" > "$EXPORT_CSV"
  for file in "${HISTORY_FILES[@]}"; do
    if [ -f "$file" ]; then
      DATE=$(node -pe "JSON.parse(require('fs').readFileSync('$file')).date")
      COMMIT=$(node -pe "JSON.parse(require('fs').readFileSync('$file')).commit")
      LINES=$(node -pe "JSON.parse(require('fs').readFileSync('$file')).coverage.lines")
      BRANCHES=$(node -pe "JSON.parse(require('fs').readFileSync('$file')).coverage.branches")
      FUNCTIONS=$(node -pe "JSON.parse(require('fs').readFileSync('$file')).coverage.functions")
      STATEMENTS=$(node -pe "JSON.parse(require('fs').readFileSync('$file')).coverage.statements")
      echo "$DATE,$COMMIT,$LINES,$BRANCHES,$FUNCTIONS,$STATEMENTS" >> "$EXPORT_CSV"
    fi
  done
  echo "Exported to $EXPORT_CSV"
fi
