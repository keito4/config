#!/usr/bin/env bash
# Dependency Health Check - Comprehensive dependency analysis

set -euo pipefail

# Source shared output library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/output.sh" 2>/dev/null || {
  readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
}

# Options
JSON_OUTPUT=false
STRICT_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --strict)
      STRICT_MODE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --json               Output in JSON format"
      echo "  --strict             Fail on high severity or dependency compatibility issues"
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
  echo -e "${BLUE}🔍 Dependency Health Check${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# npm Packages Check
TOTAL_PACKAGES=0
OUTDATED_COUNT=0
VULN_CRITICAL=0
VULN_HIGH=0
VULN_MODERATE=0
VULN_LOW=0
PEER_ISSUES=0
PEER_PROBLEMS=""
PEER_CHECK_SKIPPED=false

if [ -f "package.json" ]; then
  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}📦 npm Packages${NC}"
  fi

  # Count total packages
  if [ -d "node_modules" ]; then
    NPM_LIST_OUTPUT=$(npm list --all --json 2>/dev/null || true)
    [ -n "$NPM_LIST_OUTPUT" ] || NPM_LIST_OUTPUT='{"problems":[]}'
    TOTAL_PACKAGES=$(echo "$NPM_LIST_OUTPUT" | jq '[.. | .dependencies? | select(. != null) | keys[]] | unique | length' || echo "0")
    PEER_PROBLEMS=$(echo "$NPM_LIST_OUTPUT" | jq -r '.problems[]? | select(test("peer|invalid|missing"; "i"))' 2>/dev/null || true)
    PEER_ISSUES=$(printf '%s\n' "$PEER_PROBLEMS" | sed '/^$/d' | wc -l | tr -d ' ')
  else
    PEER_CHECK_SKIPPED=true
    TOTAL_PACKAGES=$(jq '((.dependencies // {}) + (.devDependencies // {})) | length' package.json 2>/dev/null || echo "0")
  fi

  # Check for outdated packages
  OUTDATED_OUTPUT=$(npm outdated --json 2>/dev/null || true)
  [ -n "$OUTDATED_OUTPUT" ] || OUTDATED_OUTPUT="{}"
  OUTDATED_COUNT=$(echo "$OUTDATED_OUTPUT" | jq 'length' 2>/dev/null || echo "0")

  # Security audit
  AUDIT_OUTPUT=$(npm audit --json 2>/dev/null || true)
  [ -n "$AUDIT_OUTPUT" ] || AUDIT_OUTPUT='{"vulnerabilities":{}}'
  VULN_CRITICAL=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.critical // 0' 2>/dev/null || echo "0")
  VULN_HIGH=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.high // 0' 2>/dev/null || echo "0")
  VULN_MODERATE=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.moderate // 0' 2>/dev/null || echo "0")
  VULN_LOW=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.low // 0' 2>/dev/null || echo "0")

  if [ "$JSON_OUTPUT" = false ]; then
    echo "  • Total packages: $TOTAL_PACKAGES"

    # Vulnerabilities
    if [ "$VULN_CRITICAL" -gt 0 ]; then
      echo -e "  ${RED}✗ $VULN_CRITICAL critical vulnerabilities${NC}"
    else
      echo -e "  ${GREEN}✓ No critical vulnerabilities${NC}"
    fi

    if [ "$VULN_HIGH" -gt 0 ]; then
      echo -e "  ${YELLOW}⚠ $VULN_HIGH high severity vulnerabilities${NC}"
    fi

    if [ "$VULN_MODERATE" -gt 0 ]; then
      echo "  • $VULN_MODERATE moderate severity vulnerabilities"
    fi

    # Outdated packages
    if [ "$OUTDATED_COUNT" -gt 0 ]; then
      echo -e "  ${YELLOW}⚠ $OUTDATED_COUNT packages can be updated${NC}"

      # Show top 5 outdated
      echo "$OUTDATED_OUTPUT" | jq -r 'to_entries | .[0:5] | .[] | "    - \(.key): \(.value.current) → \(.value.latest)"' 2>/dev/null || true

      if [ "$OUTDATED_COUNT" -gt 5 ]; then
        echo "    ... and $((OUTDATED_COUNT - 5)) more"
      fi
    else
      echo -e "  ${GREEN}✓ All packages up-to-date${NC}"
    fi

    if [ "$PEER_ISSUES" -gt 0 ]; then
      echo -e "  ${YELLOW}⚠ $PEER_ISSUES peer dependency compatibility issues${NC}"
      printf '%s\n' "$PEER_PROBLEMS" | sed '/^$/d' | head -5 | sed 's/^/    - /'
      if [ "$PEER_ISSUES" -gt 5 ]; then
        echo "    ... and $((PEER_ISSUES - 5)) more"
      fi
    else
      echo -e "  ${GREEN}✓ No peer dependency issues${NC}"
    fi

    if [ "$PEER_CHECK_SKIPPED" = true ]; then
      echo "  • Peer dependency check skipped (node_modules not installed)"
    fi

    echo ""
  fi
fi

# Determine overall health score
HEALTH_SCORE=100
HEALTH_SCORE=$((HEALTH_SCORE - VULN_CRITICAL * 20))
HEALTH_SCORE=$((HEALTH_SCORE - VULN_HIGH * 10))
HEALTH_SCORE=$((HEALTH_SCORE - VULN_MODERATE * 2))
HEALTH_SCORE=$((HEALTH_SCORE - OUTDATED_COUNT))
HEALTH_SCORE=$((HEALTH_SCORE - PEER_ISSUES * 5))

if [ $HEALTH_SCORE -lt 0 ]; then
  HEALTH_SCORE=0
fi

# Determine risk level
RISK_LEVEL="Low"
if [ "$VULN_CRITICAL" -gt 0 ]; then
  RISK_LEVEL="Critical"
elif [ "$VULN_HIGH" -gt 0 ]; then
  RISK_LEVEL="High"
elif [ "$VULN_MODERATE" -gt 0 ] || [ "$OUTDATED_COUNT" -gt 10 ] || [ "$PEER_ISSUES" -gt 0 ]; then
  RISK_LEVEL="Medium"
fi

if [ "$JSON_OUTPUT" = true ]; then
  # JSON output for CI integration
  cat <<EOF
{
  "health_score": $HEALTH_SCORE,
  "risk_level": "$RISK_LEVEL",
  "npm": {
    "total_packages": $TOTAL_PACKAGES,
    "outdated": $OUTDATED_COUNT,
    "peer_issues": $PEER_ISSUES,
    "peer_check_skipped": $PEER_CHECK_SKIPPED,
    "vulnerabilities": {
      "critical": $VULN_CRITICAL,
      "high": $VULN_HIGH,
      "moderate": $VULN_MODERATE,
      "low": $VULN_LOW
    }
  }
}
EOF
else
  # Human-readable summary
  echo -e "${BLUE}🏥 Overall Health Score: $HEALTH_SCORE/100${NC}"
  echo -e "   Risk Level: $RISK_LEVEL"
  echo ""

  if [ "$HEALTH_SCORE" -lt 70 ]; then
    echo -e "${YELLOW}⚠ Recommendations:${NC}"

    if [ "$VULN_CRITICAL" -gt 0 ] || [ "$VULN_HIGH" -gt 0 ]; then
      echo "  1. ${RED}URGENT:${NC} Fix security vulnerabilities"
      echo "     Run: npm audit fix"
    fi

    if [ "$OUTDATED_COUNT" -gt 10 ]; then
      echo "  2. Update outdated packages"
      echo "     Run: npm update"
    fi

    if [ "$PEER_ISSUES" -gt 0 ]; then
      echo "  3. Resolve peer dependency compatibility issues"
      echo "     Run: npm ls --all"
    fi

    echo ""
    echo "Next steps:"
    echo "  npm audit fix       # Auto-fix security issues"
    echo "  npm update          # Update to latest compatible versions"
    echo "  npm outdated        # See all outdated packages"
  elif [ "$PEER_ISSUES" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Dependencies need compatibility review${NC}"
    echo "  npm ls --all        # See peer dependency issues"
  else
    echo -e "${GREEN}✓ Dependencies are in good health!${NC}"
  fi
fi

# Exit with error in strict mode if issues found
if [ "$STRICT_MODE" = true ]; then
  if [ "$VULN_CRITICAL" -gt 0 ] || [ "$VULN_HIGH" -gt 0 ] || [ "$PEER_ISSUES" -gt 0 ]; then
    exit 1
  fi
fi

exit 0
