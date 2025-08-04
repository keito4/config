# issue-create

## 目的

リポジトリ全体を分析し、コード品質・セキュリティ・依存関係・ドキュメントなどの観点から改善点を特定し、自動的にGitHub Issueを作成する。

## 実行手順

### 1. リポジトリ構造の分析

```bash
# プロジェクト構造の概要を取得
echo "=== Repository Structure Analysis ==="
echo "Total files: $(find . -type f -not -path '*/\.*' -not -path '*/node_modules/*' | wc -l)"
echo "Total directories: $(find . -type d -not -path '*/\.*' -not -path '*/node_modules/*' | wc -l)"
echo ""

# 言語別ファイル数
echo "=== Language Distribution ==="
find . -type f -not -path '*/\.*' -not -path '*/node_modules/*' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10

# 大きなファイルの検出
echo -e "\n=== Large Files (>1000 lines) ==="
find . -type f -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" | xargs wc -l 2>/dev/null | sort -rn | head -10
```

### 2. コード品質の分析

```bash
echo "=== Code Quality Analysis ==="

# TODOコメントの検出
TODO_COUNT=$(rg -c "TODO|FIXME|HACK|XXX" --type-add 'code:*.{js,ts,jsx,tsx,py,go,rs,java,cs}' -tcode 2>/dev/null | wc -l)
echo "Files with TODO/FIXME comments: $TODO_COUNT"

if [ "$TODO_COUNT" -gt 0 ]; then
    echo "Creating issue for TODO comments..."
    TODOS=$(rg "TODO|FIXME|HACK|XXX" --type-add 'code:*.{js,ts,jsx,tsx,py,go,rs,java,cs}' -tcode -n 2>/dev/null | head -20)
    gh issue create \
        --title "📝 Address TODO/FIXME comments in codebase" \
        --body "Found $TODO_COUNT files with unresolved TODO/FIXME comments that need attention.

## Examples:
\`\`\`
$TODOS
\`\`\`

## Tasks:
- [ ] Review all TODO comments
- [ ] Convert to proper issues or implement fixes
- [ ] Remove resolved TODOs

## Acceptance Criteria:
- All TODO/FIXME comments are either resolved or converted to GitHub issues
- Code is clean and production-ready" \
        --label "tech-debt,enhancement"
fi

# 複雑度の高い関数の検出（簡易版）
echo -e "\n=== Complexity Analysis ==="
COMPLEX_FILES=$(find . -name "*.ts" -o -name "*.js" | xargs -I {} sh -c 'lines=$(wc -l < "{}"); if [ "$lines" -gt 300 ]; then echo "{}:$lines"; fi' 2>/dev/null | head -5)

if [ -n "$COMPLEX_FILES" ]; then
    echo "Creating issue for complex files..."
    gh issue create \
        --title "🔧 Refactor complex/large files" \
        --body "Several files exceed recommended complexity thresholds and should be refactored.

## Files needing refactoring:
\`\`\`
$COMPLEX_FILES
\`\`\`

## Recommended Actions:
- [ ] Split large files into smaller, focused modules
- [ ] Extract reusable components/functions
- [ ] Improve separation of concerns
- [ ] Add unit tests for refactored code

## Success Criteria:
- No single file exceeds 300 lines
- Cyclomatic complexity < 10 per function
- Test coverage maintained or improved" \
        --label "refactoring,code-quality"
fi
```

### 3. テストカバレッジの分析

```bash
echo "=== Test Coverage Analysis ==="

# テストファイルの存在確認
TEST_COUNT=$(find . -name "*.test.*" -o -name "*.spec.*" | wc -l)
SRC_COUNT=$(find . -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" -not -path "*/test/*" -not -path "*/tests/*" | wc -l)

echo "Test files: $TEST_COUNT"
echo "Source files: $SRC_COUNT"

if [ "$TEST_COUNT" -lt "$((SRC_COUNT / 2))" ]; then
    echo "Creating issue for low test coverage..."
    gh issue create \
        --title "🧪 Improve test coverage" \
        --body "Test coverage appears to be below recommended levels.

## Current Status:
- Test files: $TEST_COUNT
- Source files: $SRC_COUNT
- Ratio: $(echo "scale=2; $TEST_COUNT * 100 / $SRC_COUNT" | bc)%

## Required Actions:
- [ ] Identify untested modules
- [ ] Add unit tests for critical paths
- [ ] Add integration tests for key workflows
- [ ] Set up coverage reporting in CI

## Success Criteria:
- Line coverage ≥ 70%
- Critical paths have 100% coverage
- All new code includes tests" \
        --label "testing,quality"
fi
```

### 4. セキュリティ分析

```bash
echo "=== Security Analysis ==="

# ハードコードされた秘密情報の検出
SECRETS=$(rg -i "api[_-]?key|secret|password|token" --type-add 'config:*.{env,json,yml,yaml}' -tconfig 2>/dev/null | grep -v "example\|template\|sample" | wc -l)

if [ "$SECRETS" -gt 0 ]; then
    echo "Creating security issue..."
    gh issue create \
        --title "🔒 Security: Review potential hardcoded secrets" \
        --body "Potential security issue: Found $SECRETS instances of possible hardcoded secrets.

## Security Checklist:
- [ ] Audit all configuration files for hardcoded secrets
- [ ] Move secrets to environment variables
- [ ] Set up secret scanning in CI
- [ ] Rotate any exposed credentials
- [ ] Add .env.example file with dummy values

## Affected Patterns Found:
- API keys
- Passwords
- Tokens
- Secret keys

⚠️ **Priority: HIGH** - Security issues should be addressed immediately" \
        --label "security,critical"
fi

# 古い依存関係の検出
echo -e "\n=== Dependency Analysis ==="
if [ -f "package.json" ]; then
    OUTDATED=$(npm outdated --json 2>/dev/null | jq 'length')
    if [ "$OUTDATED" -gt 10 ]; then
        echo "Creating dependency update issue..."
        gh issue create \
            --title "📦 Update outdated dependencies" \
            --body "Found $OUTDATED outdated dependencies that should be updated.

## Actions Required:
- [ ] Review breaking changes in major version updates
- [ ] Update dependencies incrementally
- [ ] Run full test suite after updates
- [ ] Check for security vulnerabilities
- [ ] Update documentation if APIs changed

## Commands:
\`\`\`bash
npm outdated
npm audit
npm update
\`\`\`

## Success Criteria:
- All dependencies are up-to-date
- No security vulnerabilities
- All tests pass
- Application works correctly" \
            --label "dependencies,maintenance"
    fi
fi
```

### 5. ドキュメント分析

```bash
echo "=== Documentation Analysis ==="

# README.mdの存在と内容確認
if [ ! -f "README.md" ]; then
    echo "Creating documentation issue..."
    gh issue create \
        --title "📚 Add comprehensive README documentation" \
        --body "Repository lacks a README.md file.

## Required Sections:
- [ ] Project overview and purpose
- [ ] Installation instructions
- [ ] Usage examples
- [ ] Configuration options
- [ ] API documentation
- [ ] Contributing guidelines
- [ ] License information

## Success Criteria:
- README.md exists and is comprehensive
- All setup steps are documented
- Examples are runnable
- Documentation is up-to-date" \
        --label "documentation"
else
    # READMEの品質チェック
    README_LENGTH=$(wc -l < README.md)
    if [ "$README_LENGTH" -lt 50 ]; then
        echo "Creating documentation improvement issue..."
        gh issue create \
            --title "📚 Expand README documentation" \
            --body "README.md exists but appears to be minimal (only $README_LENGTH lines).

## Recommended Additions:
- [ ] Detailed setup instructions
- [ ] Architecture overview
- [ ] API documentation
- [ ] Troubleshooting section
- [ ] Contribution guidelines
- [ ] Code examples

## Success Criteria:
- README is comprehensive and helpful
- New developers can onboard easily
- Common questions are answered" \
            --label "documentation,enhancement"
    fi
fi

# API ドキュメントの確認
API_DOCS=$(find . -name "*.openapi.*" -o -name "*.swagger.*" -o -name "api-docs.*" | wc -l)
if [ "$API_DOCS" -eq 0 ] && [ -d "routes" -o -d "controllers" -o -d "api" ]; then
    echo "Creating API documentation issue..."
    gh issue create \
        --title "📖 Add API documentation" \
        --body "API endpoints detected but no OpenAPI/Swagger documentation found.

## Tasks:
- [ ] Document all API endpoints
- [ ] Add request/response schemas
- [ ] Include authentication details
- [ ] Provide example requests
- [ ] Set up API documentation generator

## Recommended Tools:
- OpenAPI/Swagger
- API Blueprint
- Postman Collections

## Success Criteria:
- All endpoints are documented
- Interactive API documentation available
- Examples for each endpoint" \
        --label "documentation,api"
fi
```

### 6. パフォーマンス分析

```bash
echo "=== Performance Analysis ==="

# 大きなバンドルサイズの検出
if [ -f "package.json" ] && grep -q "webpack\|vite\|rollup\|parcel" package.json; then
    echo "Creating performance optimization issue..."
    gh issue create \
        --title "⚡ Optimize bundle size and performance" \
        --body "Performance optimization opportunities detected.

## Optimization Tasks:
- [ ] Analyze bundle size with webpack-bundle-analyzer
- [ ] Implement code splitting
- [ ] Add lazy loading for routes/components
- [ ] Optimize images and assets
- [ ] Enable compression (gzip/brotli)
- [ ] Review and remove unused dependencies

## Metrics to Track:
- Initial bundle size
- Time to First Byte (TTFB)
- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)

## Success Criteria:
- Bundle size reduced by >20%
- Lighthouse score >90
- Core Web Vitals in green zone" \
        --label "performance,optimization"
fi
```

### 7. CI/CD 改善提案

```bash
echo "=== CI/CD Analysis ==="

# GitHub Actions の確認
if [ ! -d ".github/workflows" ]; then
    echo "Creating CI/CD setup issue..."
    gh issue create \
        --title "🚀 Set up CI/CD pipeline" \
        --body "No GitHub Actions workflows detected.

## Recommended Workflows:
- [ ] Continuous Integration (lint, test, build)
- [ ] Security scanning (SAST, dependency audit)
- [ ] Automated deployment (staging/production)
- [ ] Release automation
- [ ] Documentation generation

## Basic CI Pipeline:
\`\`\`yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
      - run: npm run lint
\`\`\`

## Success Criteria:
- All PRs run through CI checks
- Automated deployments configured
- Security scanning enabled" \
        --label "ci-cd,infrastructure"
fi
```

### 8. アクセシビリティ分析

```bash
echo "=== Accessibility Analysis ==="

# フロントエンドプロジェクトの検出
if [ -f "package.json" ] && grep -q "react\|vue\|angular\|svelte" package.json; then
    echo "Creating accessibility issue..."
    gh issue create \
        --title "♿ Improve accessibility (a11y)" \
        --body "Frontend application detected - accessibility audit recommended.

## Accessibility Checklist:
- [ ] Add proper ARIA labels
- [ ] Ensure keyboard navigation
- [ ] Provide alt text for images
- [ ] Check color contrast ratios
- [ ] Add skip navigation links
- [ ] Test with screen readers

## Tools to Use:
- axe DevTools
- WAVE
- Lighthouse
- Pa11y

## Success Criteria:
- WCAG 2.1 AA compliance
- No critical a11y violations
- Keyboard fully navigable
- Screen reader compatible" \
        --label "accessibility,frontend"
fi
```

### 9. 最終レポート生成

```bash
echo "=== Issue Creation Summary ==="

# 作成されたIssueの集計
CREATED_ISSUES=$(gh issue list --author @me --limit 10 --json number,title,createdAt | jq -r --arg date "$(date -d '5 minutes ago' -Iseconds 2>/dev/null || date -v-5M -Iseconds)" '.[] | select(.createdAt >= $date) | "#\(.number): \(.title)"')

if [ -n "$CREATED_ISSUES" ]; then
    echo "Successfully created the following issues:"
    echo "$CREATED_ISSUES"
else
    echo "No issues were created. Repository appears to be in good shape!"
fi

# 改善提案サマリー
cat << EOF

=== Repository Health Report ===
Date: $(date)

Analysis Complete. Review created issues and prioritize based on:
1. 🔒 Security issues (Critical)
2. 🧪 Test coverage gaps (High)
3. 📚 Documentation needs (Medium)
4. ⚡ Performance optimizations (Medium)
5. 🔧 Code quality improvements (Low)

Next Steps:
1. Review and triage created issues
2. Assign priorities and owners
3. Create milestones for grouped work
4. Begin with critical security issues

EOF
```

## 成功基準

- ✅ リポジトリ全体の分析が完了している
- ✅ 識別された問題に対してIssueが作成されている
- ✅ 各Issueに適切なラベルが付与されている
- ✅ 優先度に基づいた改善計画が立てられる
- ✅ レポートが生成され、次のアクションが明確である

## トラブルシューティング

### ripgrepがインストールされていない場合

```bash
# ripgrepのインストール
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
sudo dpkg -i ripgrep_13.0.0_amd64.deb
# または
brew install ripgrep  # macOS
```

### Issue作成の重複を防ぐ

```bash
# 同じタイトルのIssueが既に存在するかチェック
check_duplicate_issue() {
    local title="$1"
    existing=$(gh issue list --search "$title" --json number | jq 'length')
    [ "$existing" -eq 0 ]
}

# 使用例
if check_duplicate_issue "Improve test coverage"; then
    gh issue create --title "Improve test coverage" ...
fi
```

### バッチ処理モード

```bash
# 非対話的にすべてのIssueを作成
export GH_PROMPT_DISABLED=1
bash .claude/commands/issue-create.md --batch
```

## カスタマイズオプション

### 特定の分析のみ実行

```bash
# 環境変数で制御
ANALYZE_SECURITY=true \
ANALYZE_TESTS=false \
ANALYZE_DOCS=true \
bash .claude/commands/issue-create.md
```

### Issue テンプレートの利用

```bash
# .github/ISSUE_TEMPLATE/ のテンプレートを使用
gh issue create --template bug_report.md
gh issue create --template feature_request.md
```
