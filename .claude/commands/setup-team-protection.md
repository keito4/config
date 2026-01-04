チーム開発のためのリポジトリ保護設定

このコマンドは、チーム開発で推奨されるGitHub設定を自動的に構成します。

---

設定される内容

**ブランチ保護ルール（main/develop）**
• 直接プッシュ禁止
• プルリクエスト必須
• レビュー承認必須（最低1名）
• CODEOWNERSレビュー必須
• ステータスチェック必須（CI通過）
• force pushの禁止
• ブランチ削除保護
• 古いレビューの自動却下
• マージ前のブランチ更新必須

**リポジトリ設定**
• マージ方法の設定（デフォルト: Merge commitのみ、オプションで変更可能）
• 自動マージ無効（チェック通過後の自動マージを禁止）
• 自動削除（マージ後のブランチ）
• Issue/PR テンプレート有効化

**セキュリティ設定**
• Dependabot alerts 有効化
• Dependabot security updates 有効化
• Secret scanning 有効化
• Secret scanning push protection 有効化
• Private vulnerability reporting 有効化

---

実行方法

**基本実行**

このリポジトリ（config）のブランチ保護を設定:

```bash
bash script/setup-team-protection.sh
```

**別のリポジトリに対して実行**

```bash
bash script/setup-team-protection.sh owner/repo-name
```

**対話モード**

設定内容を確認しながら実行:

```bash
bash script/setup-team-protection.sh --interactive
```

**ドライラン**

実際の変更を行わずに確認:

```bash
bash script/setup-team-protection.sh --dry-run
```

---

前提条件

• GitHub CLI (`gh`) がインストールされていること
• リポジトリへの管理者権限があること
• GitHub にログインしていること (`gh auth login`)

---

設定の詳細

**main ブランチ保護**

```bash
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT \
  --field required_status_checks[strict]=true \
  --field required_status_checks[contexts][]=CI \
  --field required_pull_request_reviews[required_approving_review_count]=1 \
  --field required_pull_request_reviews[dismiss_stale_reviews]=true \
  --field required_pull_request_reviews[require_code_owner_reviews]=false \
  --field enforce_admins=false \
  --field restrictions=null \
  --field allow_force_pushes[enabled]=false \
  --field allow_deletions[enabled]=false \
  --field required_linear_history[enabled]=false
```

**必須ステータスチェック**

以下のワークフローが必須:
• CI（テスト、リント、ビルド）
• セキュリティスキャン（オプション）

**レビュー要件**

• 最低1名の承認が必要
• 変更があった場合は承認をリセット
• コードオーナーのレビューは任意（チーム判断）

---

カスタマイズ

**レビュー人数を増やす**

```bash
# 2名以上の承認が必要
bash script/setup-team-protection.sh --reviewers 2
```

**管理者も保護ルールに従う**

```bash
# 管理者も直接プッシュ不可
bash script/setup-team-protection.sh --enforce-admins
```

**develop ブランチも保護**

```bash
# main と develop の両方を保護
bash script/setup-team-protection.sh --branches main,develop
```

**マージ方法の設定**

```bash
# Merge commitのみ（デフォルト）
bash script/setup-team-protection.sh --merge-method merge

# Squash mergeのみ
bash script/setup-team-protection.sh --merge-method squash

# Rebase mergeのみ
bash script/setup-team-protection.sh --merge-method rebase

# すべてのマージ方法を許可
bash script/setup-team-protection.sh --merge-method all

# Squash mergeを無効化（merge commitとrebase mergeを許可）
bash script/setup-team-protection.sh --merge-method all
# または個別に設定したい場合は、スクリプトを直接編集
```

---

確認方法

**現在の保護設定を確認**

```bash
# main ブランチの保護設定
gh api repos/{owner}/{repo}/branches/main/protection | jq

# 全ブランチの保護状態
gh api repos/{owner}/{repo}/branches | jq '.[] | {name, protected}'
```

**設定が正しく適用されているか確認**

```bash
# テスト: 直接プッシュを試みる（失敗するはず）
git checkout main
git commit --allow-empty -m "test: direct push"
git push origin main
# エラー: main is protected
```

---

トラブルシューティング

**権限エラー**

```
Error: Resource not accessible by personal access token
```

対処法:
• リポジトリの管理者権限を確認
• `gh auth refresh -s admin:repo` で権限を再取得

**ステータスチェックが見つからない**

```
Warning: Required status check "CI" is not available
```

対処法:
• 先にCI ワークフローを実行して、ステータスチェックを登録
• または `--skip-status-checks` オプションで一時的にスキップ

**ブランチが存在しない**

```
Error: Branch not found
```

対処法:
• ブランチを作成してから実行
• または `--create-branches` オプションで自動作成

---

ベストプラクティス

**段階的な導入**

1. まず develop ブランチで試験運用
2. チームに周知・教育
3. main ブランチに適用
4. 必要に応じて厳格化

**チームサイズに応じた設定**

• 小規模チーム（2-5名）: レビュー1名
• 中規模チーム（6-15名）: レビュー2名
• 大規模チーム（16名以上）: レビュー2名 + コードオーナー

**緊急時の対応**

管理者による一時的な保護解除:

```bash
# 保護を一時的に無効化（緊急時のみ）
gh api repos/{owner}/{repo}/branches/main/protection \
  --method DELETE

# 作業完了後、すぐに再適用
bash script/setup-team-protection.sh
```

---

関連ファイル

• `.github/CODEOWNERS`: コードオーナーの定義
• `.github/PULL_REQUEST_TEMPLATE.md`: PR テンプレート
• `.github/workflows/ci.yml`: 必須ステータスチェック

---

追加可能な機能（将来の拡張）

以下の機能を追加する可能性があります：

**リポジトリ基本設定**
• デフォルトブランチの変更
• リポジトリの説明・トピック設定
• リポジトリの可視性設定（プライベート/パブリック）
• Wikiの有効/無効
• Issues/Projectsの有効/無効
• ディスカッションの有効/無効

**ブランチ保護の拡張**
• 必須ステータスチェックの詳細設定（特定のワークフローのみ必須化）
• コードオーナーのレビュー必須化
• プルリクエストのマージ前のブランチ更新必須化
• 署名済みコミットの必須化
• 保護されたブランチへのプッシュ権限の制限

**セキュリティ機能の拡張**
• Code scanningの有効化（GitHub Advanced Securityが必要）
• Secret scanningの有効化（GitHub Advanced Securityが必要）
• Dependency graphの有効化
• Security policyの設定

**自動化機能**
• 自動マージの設定（すべてのチェック通過後）
• 自動リリースノート生成
• ラベルの自動付与

**通知・統合**
• ブランチ保護違反時の通知設定
• Slack/Teamsへの通知統合

---

参考リンク

• [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
• [GitHub CLI API Reference](https://cli.github.com/manual/gh_api)
• [Team Development Best Practices](https://github.com/keito4/config/blob/main/CLAUDE.md)
