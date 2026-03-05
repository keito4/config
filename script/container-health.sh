#!/usr/bin/env bash
# Container Health - Verify DevContainer environment

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Options
# shellcheck disable=SC2034
VERBOSE=false
# shellcheck disable=SC2034
AUTO_FIX=false
JSON_OUTPUT=false
CHECK_COMPONENT=""

# Health score
HEALTH_SCORE=100
MAX_SCORE=100

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      # shellcheck disable=SC2034
      VERBOSE=true
      shift
      ;;
    --fix)
      # shellcheck disable=SC2034
      AUTO_FIX=true
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --check)
      CHECK_COMPONENT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --verbose       Verbose output"
      echo "  --fix           Attempt automatic fixes"
      echo "  --json          JSON output"
      echo "  --check TYPE    Check specific component (tools|config|resources)"
      echo "  --help          Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ "$JSON_OUTPUT" = false ]; then
  echo -e "${BLUE}🏥 DevContainer Health Check${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# Initialize results
declare -A TOOL_STATUS
declare -A CONFIG_STATUS
RECOMMENDATIONS=()

# Check tool availability
check_tool() {
  local tool=$1
  local required=${2:-false}

  if command -v "$tool" > /dev/null 2>&1; then
    VERSION=$(command "$tool" --version 2>&1 | head -1 || echo "unknown")
    TOOL_STATUS["$tool"]="installed:$VERSION"
    return 0
  else
    TOOL_STATUS["$tool"]="missing"
    if [ "$required" = true ]; then
      HEALTH_SCORE=$((HEALTH_SCORE - 10))
    fi
    return 1
  fi
}

# Tool checks
if [ -z "$CHECK_COMPONENT" ] || [ "$CHECK_COMPONENT" = "tools" ]; then
  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}✅ Required Tools${NC}"
  fi

  # Required tools
  for tool in git node npm; do
    if check_tool "$tool" true; then
      if [ "$JSON_OUTPUT" = false ]; then
        VERSION=${TOOL_STATUS["$tool"]#installed:}
        echo -e "  ${GREEN}✓${NC} $tool $VERSION"
      fi
    else
      if [ "$JSON_OUTPUT" = false ]; then
        echo -e "  ${RED}✗${NC} $tool (not installed)"
      fi
      RECOMMENDATIONS+=("Install $tool")
    fi
  done

  if [ "$JSON_OUTPUT" = false ]; then
    echo ""
  fi

  # Claude Code tools
  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}✅ Claude Code Tools${NC}"
  fi

  # Check claude tool
  if check_tool "claude" false; then
    if [ "$JSON_OUTPUT" = false ]; then
      VERSION=${TOOL_STATUS["claude"]#installed:}
      echo -e "  ${GREEN}✓${NC} claude"
    fi
  else
    if [ "$JSON_OUTPUT" = false ]; then
      echo -e "  ${YELLOW}⚠${NC} claude (not installed)"
    fi
    HEALTH_SCORE=$((HEALTH_SCORE - 5))
    RECOMMENDATIONS+=("Install Claude Code: curl -fsSL https://claude.ai/install.sh | bash")
  fi

  if [ "$JSON_OUTPUT" = false ]; then
    echo ""
  fi

  # Development tools
  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}✅ Development Tools${NC}"
  fi

  for tool in eslint prettier jest; do
    if check_tool "$tool" false; then
      if [ "$JSON_OUTPUT" = false ]; then
        VERSION=${TOOL_STATUS["$tool"]#installed:}
        echo -e "  ${GREEN}✓${NC} $tool"
      fi
    else
      if [ "$JSON_OUTPUT" = false ]; then
        echo -e "  ${YELLOW}⚠${NC} $tool (not in PATH)"
      fi
      HEALTH_SCORE=$((HEALTH_SCORE - 2))
    fi
  done

  if [ "$JSON_OUTPUT" = false ]; then
    echo ""
  fi

  # Optional tools
  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}⚠️ Optional Tools${NC}"
  fi

  for tool in gh shellcheck; do
    if check_tool "$tool" false; then
      if [ "$JSON_OUTPUT" = false ]; then
        VERSION=${TOOL_STATUS["$tool"]#installed:}
        echo -e "  ${GREEN}✓${NC} $tool"
      fi
    else
      if [ "$JSON_OUTPUT" = false ]; then
        echo -e "  ${YELLOW}⚠${NC} $tool (not installed)"
      fi
      case "$tool" in
        shellcheck)
          RECOMMENDATIONS+=("Install shellcheck: apt-get install shellcheck")
          ;;
        gh)
          RECOMMENDATIONS+=("Install GitHub CLI: https://cli.github.com")
          ;;
      esac
    fi
  done

  if [ "$JSON_OUTPUT" = false ]; then
    echo ""
  fi
fi

# Configuration checks
if [ -z "$CHECK_COMPONENT" ] || [ "$CHECK_COMPONENT" = "config" ]; then
  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}✅ Configuration${NC}"
  fi

  # package.json
  if [ -f "package.json" ]; then
    if node -pe "JSON.parse(require('fs').readFileSync('package.json'))" > /dev/null 2>&1; then
      CONFIG_STATUS["package.json"]="valid"
      if [ "$JSON_OUTPUT" = false ]; then
        echo -e "  ${GREEN}✓${NC} package.json valid"
      fi
    else
      CONFIG_STATUS["package.json"]="invalid"
      if [ "$JSON_OUTPUT" = false ]; then
        echo -e "  ${RED}✗${NC} package.json invalid JSON"
      fi
      HEALTH_SCORE=$((HEALTH_SCORE - 10))
    fi
  else
    CONFIG_STATUS["package.json"]="missing"
    if [ "$JSON_OUTPUT" = false ]; then
      echo -e "  ${YELLOW}⚠${NC} package.json not found"
    fi
    HEALTH_SCORE=$((HEALTH_SCORE - 5))
  fi

  # Git config
  if git config user.name > /dev/null 2>&1; then
    CONFIG_STATUS["git.user"]="configured"
    if [ "$JSON_OUTPUT" = false ]; then
      echo -e "  ${GREEN}✓${NC} git user configured"
    fi
  else
    CONFIG_STATUS["git.user"]="missing"
    if [ "$JSON_OUTPUT" = false ]; then
      echo -e "  ${YELLOW}⚠${NC} git user not configured"
    fi
    RECOMMENDATIONS+=("Set git user: git config --global user.name 'Your Name'")
    HEALTH_SCORE=$((HEALTH_SCORE - 5))
  fi

  if git config user.email > /dev/null 2>&1; then
    CONFIG_STATUS["git.email"]="configured"
    if [ "$JSON_OUTPUT" = false ]; then
      echo -e "  ${GREEN}✓${NC} git email configured"
    fi
  else
    CONFIG_STATUS["git.email"]="missing"
    if [ "$JSON_OUTPUT" = false ]; then
      echo -e "  ${YELLOW}⚠${NC} git email not configured"
    fi
    RECOMMENDATIONS+=("Set git email: git config --global user.email 'you@example.com'")
    HEALTH_SCORE=$((HEALTH_SCORE - 5))
  fi

  if [ "$JSON_OUTPUT" = false ]; then
    echo ""
  fi
fi

# Resource checks
if [ -z "$CHECK_COMPONENT" ] || [ "$CHECK_COMPONENT" = "resources" ]; then
  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "${BLUE}✅ System Resources${NC}"
  fi

  # Disk space
  DISK_FREE=$(df -h . | awk 'NR==2 {print $4}' || echo "unknown")
  if [ "$JSON_OUTPUT" = false ]; then
    echo -e "  ${GREEN}✓${NC} Disk space: $DISK_FREE free"
  fi

  # Memory (if available)
  if command -v free > /dev/null 2>&1; then
    MEM_AVAILABLE=$(free -h | awk 'NR==2 {print $7}' || echo "unknown")
    if [ "$JSON_OUTPUT" = false ]; then
      echo -e "  ${GREEN}✓${NC} Memory: $MEM_AVAILABLE available"
    fi
  fi

  if [ "$JSON_OUTPUT" = false ]; then
    echo ""
  fi
fi

# Ensure score doesn't go negative
if [ $HEALTH_SCORE -lt 0 ]; then
  HEALTH_SCORE=0
fi

# Output results
if [ "$JSON_OUTPUT" = true ]; then
  # JSON output
  cat <<EOF
{
  "health_score": $HEALTH_SCORE,
  "max_score": $MAX_SCORE,
  "tools": $(printf '%s\n' "${!TOOL_STATUS[@]}" | jq -R -s -c 'split("\n")[:-1]'),
  "config": $(printf '%s\n' "${!CONFIG_STATUS[@]}" | jq -R -s -c 'split("\n")[:-1]'),
  "recommendations": $(printf '%s\n' "${RECOMMENDATIONS[@]}" | jq -R -s -c 'split("\n")[:-1]' || echo '[]')
}
EOF
else
  # Human-readable output
  echo -e "${BLUE}🏥 Health Score: $HEALTH_SCORE/$MAX_SCORE${NC}"
  echo ""

  if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️ Recommendations:${NC}"
    i=1
    for rec in "${RECOMMENDATIONS[@]}"; do
      echo "  $i. $rec"
      i=$((i + 1))
    done
    echo ""
  fi

  if [ $HEALTH_SCORE -ge 90 ]; then
    echo -e "${GREEN}✨ DevContainer is healthy!${NC}"
    exit 0
  elif [ $HEALTH_SCORE -ge 70 ]; then
    echo -e "${YELLOW}⚠️ DevContainer has minor issues${NC}"
    exit 0
  else
    echo -e "${RED}❌ DevContainer has critical issues${NC}"
    exit 1
  fi
fi
