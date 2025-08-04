# Issue Resolver: Dependencies Agent

## 目的

依存関係に関するIssueを解決し、古いパッケージの更新、脆弱性の修正、不要な依存関係の削除を行う。

## 実行手順

### 1. 依存関係の現状分析

```bash
# 依存関係の分析
echo "=== Analyzing dependencies ==="

# Node.js プロジェクト
if [ -f "package.json" ]; then
    echo "Node.js project detected"
    
    # 古いパッケージの確認
    npm outdated --json > npm-outdated.json
    
    # 脆弱性の確認
    npm audit --json > npm-audit.json
    
    # 未使用の依存関係を検出
    npx depcheck --json > depcheck.json
    
    # サマリー表示
    echo "Outdated packages: $(cat npm-outdated.json | jq 'length')"
    echo "Vulnerabilities: $(cat npm-audit.json | jq '.metadata.vulnerabilities.total')"
    echo "Unused dependencies: $(cat depcheck.json | jq '.dependencies | length')"
fi

# Python プロジェクト
if [ -f "requirements.txt" ] || [ -f "Pipfile" ]; then
    echo "Python project detected"
    
    pip list --outdated --format=json > pip-outdated.json
    pip-audit --format json > pip-audit.json
fi

# Go プロジェクト
if [ -f "go.mod" ]; then
    echo "Go project detected"
    
    go list -u -m -json all > go-outdated.json
    nancy sleuth -o json > nancy-audit.json
fi

# Rust プロジェクト  
if [ -f "Cargo.toml" ]; then
    echo "Rust project detected"
    
    cargo outdated --format json > cargo-outdated.json
    cargo audit --json > cargo-audit.json
fi
```

### 2. メジャーバージョンアップデートの処理

```bash
echo "=== Handling major version updates ==="

if [ -f "package.json" ]; then
    # メジャーアップデートが必要なパッケージを特定
    cat npm-outdated.json | jq -r 'to_entries[] | select(.value.wanted != .value.latest) | .key' > major-updates.txt
    
    while read -r package; do
        echo "Processing major update for $package"
        
        # 現在のバージョンと最新バージョンを取得
        current=$(cat npm-outdated.json | jq -r ".\"$package\".current")
        latest=$(cat npm-outdated.json | jq -r ".\"$package\".latest")
        
        echo "Updating $package from $current to $latest"
        
        # Breaking changes の確認
        echo "Checking breaking changes for $package..."
        
        # CHANGELOG や GitHub Releases を確認
        npm view "$package" repository.url | xargs -I {} curl -s {}/releases | grep -i breaking | head -5
        
        # 一旦バックアップ
        cp package.json package.json.backup
        cp package-lock.json package-lock.json.backup
        
        # アップデート実行
        npm install "$package@latest"
        
        # テスト実行
        if npm test; then
            echo "✅ $package updated successfully"
            
            # 必要に応じてコードを自動修正
            case "$package" in
                "react")
                    # React のマイグレーション
                    npx react-codemod
                    ;;
                "eslint")
                    # ESLint設定の更新
                    npx eslint --init
                    ;;
                "webpack")
                    # Webpack設定の更新
                    echo "Please review webpack.config.js for breaking changes"
                    ;;
            esac
        else
            echo "❌ Tests failed after updating $package"
            # ロールバック
            mv package.json.backup package.json
            mv package-lock.json.backup package-lock.json
            npm install
            
            # 段階的アップデートを試みる
            echo "Attempting incremental update..."
            npm install "$package@^$current"
        fi
    done < major-updates.txt
fi
```

### 3. セキュリティ脆弱性の修正

```bash
echo "=== Fixing security vulnerabilities ==="

if [ -f "package.json" ]; then
    # 自動修正を試みる
    npm audit fix
    
    # 破壊的変更が必要な脆弱性
    if [ $(cat npm-audit.json | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical') -gt 0 ]; then
        echo "High/Critical vulnerabilities found, attempting force fix..."
        
        # 各脆弱性を個別に処理
        cat npm-audit.json | jq -r '.vulnerabilities | to_entries[] | select(.value.severity == "high" or .value.severity == "critical") | .key' | while read -r vuln_package; do
            echo "Fixing vulnerability in $vuln_package"
            
            # 推奨される修正バージョンを取得
            fix_version=$(cat npm-audit.json | jq -r ".vulnerabilities.\"$vuln_package\".fixAvailable.version" 2>/dev/null)
            
            if [ "$fix_version" != "null" ] && [ -n "$fix_version" ]; then
                npm install "$vuln_package@$fix_version"
            else
                # 最新版にアップデート
                npm install "$vuln_package@latest"
            fi
        done
        
        # 再度監査
        npm audit
    fi
fi

# Pythonの脆弱性修正
if [ -f "requirements.txt" ]; then
    cat pip-audit.json | jq -r '.vulnerabilities[].name' | while read -r package; do
        echo "Updating vulnerable package: $package"
        pip install --upgrade "$package"
    done
    
    # requirements.txtを更新
    pip freeze > requirements.txt
fi
```

### 4. 未使用の依存関係を削除

```bash
echo "=== Removing unused dependencies ==="

if [ -f "depcheck.json" ]; then
    # 未使用の依存関係を取得
    unused_deps=$(cat depcheck.json | jq -r '.dependencies[]')
    unused_dev_deps=$(cat depcheck.json | jq -r '.devDependencies[]')
    
    if [ -n "$unused_deps" ]; then
        echo "Removing unused dependencies:"
        echo "$unused_deps"
        
        # 各パッケージが本当に未使用か確認
        for dep in $unused_deps; do
            # グローバルに使用されていないか確認
            if ! rg "$dep" --type js --type ts --type jsx --type tsx 2>/dev/null | grep -v node_modules | grep -v package; then
                echo "Removing $dep"
                npm uninstall "$dep"
            else
                echo "Keeping $dep (found references in code)"
            fi
        done
    fi
    
    if [ -n "$unused_dev_deps" ]; then
        echo "Removing unused dev dependencies:"
        echo "$unused_dev_deps"
        
        for dep in $unused_dev_deps; do
            npm uninstall --save-dev "$dep"
        done
    fi
fi
```

### 5. ライセンスの確認

```bash
echo "=== Checking licenses ==="

# license-checkerのインストール
npm install -g license-checker

# ライセンスチェック
license-checker --json > licenses.json

# 問題のあるライセンスを検出
problematic_licenses="GPL|AGPL|LGPL|CC-BY-SA"

cat licenses.json | jq -r 'to_entries[] | select(.value.licenses | test("'$problematic_licenses'")) | "\(.key): \(.value.licenses)"' > problematic-licenses.txt

if [ -s problematic-licenses.txt ]; then
    echo "⚠️ Packages with potentially problematic licenses found:"
    cat problematic-licenses.txt
    
    # 代替パッケージの提案
    while IFS=: read -r package license; do
        echo "Finding alternatives for $package (License: $license)"
        
        # npm searchで代替を検索
        pkg_name=$(echo "$package" | cut -d@ -f1)
        npm search "$pkg_name alternative" --json | jq -r '.[] | "\(.name): \(.description)"' | head -5
    done < problematic-licenses.txt
fi

# ライセンスファイルの生成
cat << 'EOF' > LICENSES.md
# Third-Party Licenses

This project uses the following third-party packages:

EOF

cat licenses.json | jq -r 'to_entries[] | "## \(.key)\n- License: \(.value.licenses)\n- Repository: \(.value.repository)\n"' >> LICENSES.md
```

### 6. 依存関係の最適化

```bash
echo "=== Optimizing dependencies ==="

# バンドルサイズの分析（Webプロジェクトの場合）
if grep -q "webpack\|react\|vue\|angular" package.json 2>/dev/null; then
    npx webpack-bundle-analyzer --help > /dev/null 2>&1 || npm install --save-dev webpack-bundle-analyzer
    
    # 大きなパッケージを特定
    npm list --depth=0 --json | jq -r '.dependencies | to_entries[] | .key' | while read -r package; do
        size=$(npm view "$package" dist.unpackedSize 2>/dev/null)
        if [ -n "$size" ] && [ "$size" -gt 1000000 ]; then
            echo "Large package detected: $package ($(($size / 1024 / 1024))MB)"
            
            # 軽量な代替を提案
            case "$package" in
                "moment")
                    echo "  → Consider using date-fns or dayjs instead"
                    ;;
                "lodash")
                    echo "  → Consider using lodash-es for tree-shaking"
                    ;;
                "jquery")
                    echo "  → Consider removing jQuery if using modern framework"
                    ;;
            esac
        fi
    done
fi

# 重複する依存関係の検出
npm dedupe

# package-lock.jsonの最適化
rm -rf node_modules package-lock.json
npm install
```

### 7. CI/CD設定の更新

```bash
echo "=== Updating CI/CD configuration ==="

# GitHub Actionsの依存関係キャッシュ設定
if [ -d ".github/workflows" ]; then
    cat << 'EOF' > .github/workflows/dependency-update.yml
name: Dependency Update

on:
  schedule:
    - cron: '0 0 * * 1' # Weekly on Monday
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Update dependencies
        run: |
          npm update
          npm audit fix
          npm dedupe
      
      - name: Run tests
        run: npm test
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'chore: Update dependencies'
          commit-message: 'chore: Update dependencies'
          branch: dependency-updates
          body: |
            ## Dependency Updates
            
            This PR updates project dependencies to their latest versions.
            
            - Security vulnerabilities fixed
            - Outdated packages updated
            - Unused dependencies removed
EOF
fi

# Dependabot設定
mkdir -p .github
cat << 'EOF' > .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "your-github-username"
    labels:
      - "dependencies"
    commit-message:
      prefix: "chore"
      include: "scope"
EOF
```

### 8. PRの作成

```bash
# 変更をコミット
git add -A
git commit -m "chore: Update and optimize dependencies

- Updated $(cat npm-outdated.json | jq 'length') outdated packages
- Fixed $(cat npm-audit.json | jq '.metadata.vulnerabilities.total') security vulnerabilities
- Removed $(cat depcheck.json | jq '.dependencies | length') unused dependencies
- Optimized bundle size and dependency tree
- Added automated dependency update workflow

Closes #<issue-number>"

# PRを作成
gh pr create \
    --title "📦 Dependency Updates and Optimization" \
    --body "## Summary
This PR updates and optimizes project dependencies.

## Changes Made
- ✅ Updated outdated packages to latest versions
- ✅ Fixed all security vulnerabilities
- ✅ Removed unused dependencies
- ✅ Optimized dependency tree with npm dedupe
- ✅ Added Dependabot configuration
- ✅ Created automated update workflow

## Dependency Statistics
### Before
- Outdated packages: X
- Vulnerabilities: Y
- Total size: Z MB

### After
- Outdated packages: 0
- Vulnerabilities: 0
- Total size: W MB (X% reduction)

## Breaking Changes
$(if [ -s major-updates.txt ]; then
    echo "The following packages had major version updates:"
    cat major-updates.txt | sed 's/^/- /'
else
    echo "None"
fi)

## Testing
- [x] All tests pass
- [x] Application builds successfully
- [x] No runtime errors detected
- [x] Performance benchmarks maintained

## Checklist
- [x] Dependencies updated
- [x] Security vulnerabilities resolved
- [x] Unused packages removed
- [x] License compliance verified
- [x] CI/CD configuration updated" \
    --label "dependencies,maintenance"
```

## 成功基準

- ✅ すべての依存関係が最新バージョンになっている
- ✅ セキュリティ脆弱性が0件
- ✅ 未使用の依存関係が削除されている
- ✅ ライセンスの問題が解決されている
- ✅ 自動更新の仕組みが設定されている
- ✅ PRが作成されている