#!/usr/bin/env bash
# Security Credential Scan - Detect hardcoded secrets

set -euo pipefail

# Source shared output library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/output.sh" 2>/dev/null || {
  # Fallback: minimal color definitions if lib not available
  readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
}

# Options
# shellcheck disable=SC2034
AUTO_FIX=false
REPORT_FILE=""
SCAN_PATH="."
IGNORE_PATTERN=""
STRICT_MODE=false
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --fix)
      # shellcheck disable=SC2034
      AUTO_FIX=true
      shift
      ;;
    --report)
      REPORT_FILE="$2"
      shift 2
      ;;
    --path)
      SCAN_PATH="$2"
      shift 2
      ;;
    --ignore)
      IGNORE_PATTERN="$2"
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
      echo "  --fix                Attempt automatic fixes"
      echo "  --report FILE        Generate detailed report"
      echo "  --path PATH          Path to scan (default: .)"
      echo "  --ignore PATTERN     Ignore pattern"
      echo "  --strict             Fail on critical findings"
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
  echo -e "${BLUE}🔒 Security Credential Scan${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# Patterns to detect
declare -A PATTERNS
# Cloud Provider Keys
PATTERNS["AWS Access Key"]="AKIA[0-9A-Z]{16}"
PATTERNS["AWS Secret"]="['\"][A-Za-z0-9/+=]{40}['\"]"
PATTERNS["Google API Key"]="AIza[0-9A-Za-z\\-_]{35}"
PATTERNS["Azure Service Principal"]="['\"][a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}['\"]"

# GitHub Tokens
PATTERNS["GitHub Token (classic)"]="ghp_[a-zA-Z0-9]{36}"
PATTERNS["GitHub Token (fine-grained)"]="github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}"
PATTERNS["GitHub OAuth"]="gho_[a-zA-Z0-9]{36}"
PATTERNS["GitHub App Token"]="ghu_[a-zA-Z0-9]{36}"
PATTERNS["GitHub Server-to-Server"]="ghs_[a-zA-Z0-9]{36}"
PATTERNS["GitHub Refresh Token"]="ghr_[a-zA-Z0-9]{36}"

# AI Service Keys
PATTERNS["OpenAI API Key"]="sk-proj-[a-zA-Z0-9_-]{20,}"
PATTERNS["OpenAI Legacy Key"]="sk-[a-zA-Z0-9]{48}"
PATTERNS["Anthropic API Key"]="sk-ant-[a-zA-Z0-9_-]{95,}"
PATTERNS["Cohere API Key"]="['\"]co_[a-zA-Z0-9]{32,}['\"]"
# Note: Gemini API Key uses same pattern as Google API Key (AIza...)

# Platform Keys
PATTERNS["Slack Token"]="xox[baprs]-[a-zA-Z0-9-]+"
PATTERNS["Slack Webhook"]="https://hooks\\.slack\\.com/services/[A-Z0-9]+/[A-Z0-9]+/[a-zA-Z0-9]+"
PATTERNS["Stripe Key"]="[sr]k_(live|test)_[a-zA-Z0-9]{24,}"
PATTERNS["Supabase Key"]="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\\.[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+"
# Note: Vercel Token pattern removed (too broad, causes false positives)
PATTERNS["Linear API Key"]="lin_api_[a-zA-Z0-9]{43}"
PATTERNS["Sentry DSN"]="https://[a-f0-9]{32}@[a-z0-9]+\\.ingest\\.sentry\\.io/[0-9]+"

# Generic Patterns
PATTERNS["Private Key"]="-----BEGIN.*PRIVATE KEY-----"
PATTERNS["JWT Token"]="eyJ[A-Za-z0-9_-]*\\.eyJ[A-Za-z0-9_-]*\\.[A-Za-z0-9_-]*"
PATTERNS["Password Assignment"]="password[[:space:]]*=[[:space:]]*['\"][^'\"]{8,}['\"]"
PATTERNS["Database URL"]="(postgres|mysql|mongodb)://[^:]+:[^@]+@"
PATTERNS["Bearer Token"]="Bearer[[:space:]]+[a-zA-Z0-9_-]{20,}"
PATTERNS["Basic Auth Header"]="Basic[[:space:]]+[A-Za-z0-9+/=]{20,}"

# Files to exclude
EXCLUDE_PATTERNS=(
  "node_modules"
  ".git"
  "coverage"
  "dist"
  "build"
  "*.min.js"
  "*.test.js"
  "*.test.ts"
  "*.spec.js"
  "*.spec.ts"
  "__tests__"
  "*.example"
  "*.sample"
  "*.md"
  ".env.example"
  ".env.template"
  "*.jsonl"
  "*.lock.json"
  "*.bats"
)

# Directories to exclude (--exclude-dir)
EXCLUDE_DIRS=(
  "node_modules"
  ".git"
  ".claude"
  "coverage"
  "dist"
  "build"
  "__tests__"
)

# Build grep exclude arguments
GREP_EXCLUDE=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  GREP_EXCLUDE="$GREP_EXCLUDE --exclude=$pattern"
done
for dir in "${EXCLUDE_DIRS[@]}"; do
  GREP_EXCLUDE="$GREP_EXCLUDE --exclude-dir=$dir"
done

# Scan results
CRITICAL_COUNT=0
WARNING_COUNT=0
FINDINGS=()

# Scan for patterns
for pattern_name in "${!PATTERNS[@]}"; do
  pattern="${PATTERNS[$pattern_name]}"

  # Search for pattern
  # shellcheck disable=SC2086
  while IFS=: read -r file line_num line_content; do
    # Skip if in ignore pattern
    if [ -n "$IGNORE_PATTERN" ] && [[ "$file" =~ $IGNORE_PATTERN ]]; then
      continue
    fi

    # Skip gitignored files
    if git check-ignore -q "$file" 2>/dev/null; then
      continue
    fi

    # Determine severity
    SEVERITY="WARNING"
    # Critical patterns: cloud credentials, API keys that provide full access
    if [[ "$pattern_name" == *"AWS"* ]] || \
       [[ "$pattern_name" == *"GitHub Token"* ]] || \
       [[ "$pattern_name" == *"Private Key"* ]] || \
       [[ "$pattern_name" == *"OpenAI"* ]] || \
       [[ "$pattern_name" == *"Anthropic"* ]] || \
       [[ "$pattern_name" == *"Stripe"* ]] || \
       [[ "$pattern_name" == *"Supabase"* ]] || \
       [[ "$pattern_name" == *"Slack Token"* ]] || \
       [[ "$pattern_name" == *"Database URL"* ]]; then
      SEVERITY="CRITICAL"
      CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    else
      WARNING_COUNT=$((WARNING_COUNT + 1))
    fi

    # Mask sensitive part
    # shellcheck disable=SC2001
    MASKED=$(echo "$line_content" | sed 's/[A-Za-z0-9]\{10,\}/************/g')

    FINDINGS+=("$SEVERITY|$pattern_name|$file:$line_num|$MASKED")
  done < <(grep -rn -E $GREP_EXCLUDE "$pattern" "$SCAN_PATH" 2>/dev/null || true)
done

# Count files scanned
if [ -d "$SCAN_PATH" ]; then
  # shellcheck disable=SC2086
  TOTAL_FILES=$(find "$SCAN_PATH" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" | wc -l | tr -d ' ')
else
  TOTAL_FILES=1
fi

if [ "$JSON_OUTPUT" = true ]; then
  # JSON output
  cat <<EOF
{
  "critical_count": $CRITICAL_COUNT,
  "warning_count": $WARNING_COUNT,
  "total_files_scanned": $TOTAL_FILES,
  "findings": [
EOF

  first=true
  for finding in "${FINDINGS[@]}"; do
    IFS='|' read -r severity type location content <<< "$finding"
    if [ "$first" = false ]; then
      echo ","
    fi
    first=false
    cat <<EOF
    {
      "severity": "$severity",
      "type": "$type",
      "location": "$location",
      "masked_content": "$content"
    }
EOF
  done

  cat <<EOF

  ]
}
EOF
else
  # Human-readable output
  echo "📁 Scanning $TOTAL_FILES files in $SCAN_PATH..."
  echo ""

  if [ ${#FINDINGS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No credentials found!${NC}"
    echo ""
    echo "🏆 Security Score: 100/100"
    exit 0
  fi

  # Show critical findings
  if [ $CRITICAL_COUNT -gt 0 ]; then
    echo -e "${RED}🚨 CRITICAL: Potential Secrets Found${NC}"
    echo ""

    i=1
    for finding in "${FINDINGS[@]}"; do
      IFS='|' read -r severity type location content <<< "$finding"
      if [ "$severity" = "CRITICAL" ]; then
        echo "$i. $location"
        echo "   Type: $type"
        echo "   Content: $content"
        echo -e "   ${RED}🔥 Action: Remove or move to environment variable${NC}"
        echo ""
        i=$((i + 1))
      fi
    done
  fi

  # Show warnings
  if [ $WARNING_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️ WARNING: Potential Issues${NC}"
    echo ""

    i=1
    for finding in "${FINDINGS[@]}"; do
      IFS='|' read -r severity type location content <<< "$finding"
      if [ "$severity" = "WARNING" ]; then
        echo "$i. $location"
        echo "   Type: $type"
        echo "   Content: $content"
        echo -e "   ${YELLOW}ℹ️ Note: Review if this is intentional${NC}"
        echo ""
        i=$((i + 1))
      fi
    done
  fi

  # Summary
  echo -e "${BLUE}📊 Summary${NC}"
  echo ""
  echo "  Critical: $CRITICAL_COUNT findings (MUST FIX)"
  echo "  Warning: $WARNING_COUNT findings (should review)"
  echo "  Total Files Scanned: $TOTAL_FILES"
  echo ""

  # Check .env configuration
  if [ -f ".env" ]; then
    echo -e "${BLUE}✅ .env Configuration${NC}"
    echo ""

    if [ -f ".env.example" ]; then
      echo -e "  ${GREEN}✓${NC} .env.example exists"
    else
      echo -e "  ${YELLOW}⚠${NC} .env.example missing"
    fi

    if git check-ignore .env > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} .env in .gitignore"
    else
      echo -e "  ${RED}✗${NC} .env NOT in .gitignore (CRITICAL)"
      CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    fi
    echo ""
  fi

  # Recommendations
  echo -e "${BLUE}🔧 Recommended Actions${NC}"
  echo ""
  echo "1. Move secrets from committed files to environment variables"
  echo "2. Update .gitignore to include:"
  echo "   - .env.local"
  echo "   - *.key"
  echo "   - *.pem"
  echo "   - credentials.json"
  echo "3. Use secret management:"
  echo "   - 1Password CLI for local development"
  echo "   - GitHub Secrets for CI/CD"
  echo "   - AWS Secrets Manager for production"
  echo ""

  # Calculate security score
  SECURITY_SCORE=$((100 - (CRITICAL_COUNT * 20) - (WARNING_COUNT * 5)))
  if [ $SECURITY_SCORE -lt 0 ]; then
    SECURITY_SCORE=0
  fi

  if [ $SECURITY_SCORE -ge 90 ]; then
    echo -e "${GREEN}🏆 Security Score: $SECURITY_SCORE/100 (Excellent)${NC}"
  elif [ $SECURITY_SCORE -ge 70 ]; then
    echo -e "${YELLOW}⚠️ Security Score: $SECURITY_SCORE/100 (Good)${NC}"
  else
    echo -e "${RED}🚨 Security Score: $SECURITY_SCORE/100 (Critical)${NC}"
  fi
fi

# Write report
if [ -n "$REPORT_FILE" ]; then
  {
    echo "# Security Credential Scan Report"
    echo ""
    echo "Generated: $(date)"
    echo ""
    echo "## Summary"
    echo ""
    echo "- Critical Findings: $CRITICAL_COUNT"
    echo "- Warning Findings: $WARNING_COUNT"
    echo "- Files Scanned: $TOTAL_FILES"
    echo ""
    echo "## Findings"
    echo ""
    for finding in "${FINDINGS[@]}"; do
      IFS='|' read -r severity type location content <<< "$finding"
      echo "### $severity: $type"
      echo ""
      echo "- Location: $location"
      echo "- Content: $content"
      echo ""
    done
  } > "$REPORT_FILE"
  echo ""
  echo "Report written to: $REPORT_FILE"
fi

# Exit code for strict mode
if [ "$STRICT_MODE" = true ] && [ $CRITICAL_COUNT -gt 0 ]; then
  exit 1
fi

exit 0
