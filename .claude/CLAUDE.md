# CLAUDE.md

## 目的

全社・全組織横断で “最低保証される開発品質・コミュニケーション品質” を定義する。

---

## 1. Conversation Guidelines

- **日本語で応答**
  - コード・ログ・エラーメッセージは原文保持
- **思考の透明化**
  - Step-by-step Reasoning を簡潔に示す
- **フォーマット統一**
  - Markdown 見出し（##）と箇条書きを基本
  - コードブロックは lang 明示、120 行以内
- **外部情報**
  - 参照 URL は脚注形式で列挙
  - 著作権を侵害する長文引用は禁止
- **出力サイズ制限**
  - 1レスで ソース200行／トークン3,000を超えない
  - 上限超過が必要な場合は「続く」宣言で分割
- **セキュリティ配慮**
  - 資格情報・機密値は必ず \*\*\* マスク

---

## 2. Development Philosophy（共通ベースライン）

### 2.1 Test-Driven Development (TDD)

| ルール     | 値                                                        |
| ---------- | --------------------------------------------------------- |
| 原則       | Red → Green → Refactor                                    |
| 階層       | Unit / Component / E2E                                    |
| 基準       | 全リポジトリ 70%+ 行カバレッジ、クリティカルパスは 100%   |
| 失敗時対応 | CI Red → Slack #ci-alerts → 24h以内修正 or Owner Escalate |

### 2.2 Static Quality Gates

| ツール                   | CI Blocker レベル        |
| ------------------------ | ------------------------ |
| Lint（各言語推奨セット） | Error=Fail               |
| Prettier / fmt           | Auto-fix無効時はFail     |
| SAST / 依存脆弱性        | Critical検知でFail       |
| license-checker          | 禁止ライセンス混入でFail |

### 2.3 Git Workflow

1. Branch命名：`feat|fix|chore/<issue#>-slug`
2. Commit規約：Conventional Commits（日本語サマリ可）
3. Pull Requestガード
   - Diff ≤ 400行／ファイル数 ≤ 25
   - Linked Issue必須
   - 緑テスト＋レビュー1名以上

### 2.4 CI/CD パイプライン最小ステージ

Lint → Test → Build → SCA → Deploy:Stg → E2E → Deploy:Prod
デプロイは Blue-Green もしくは Canary + Auto-Rollback を推奨。

---

## 3. AI Prompt Design Baseline

| シナリオ | 必須指示                       | 禁止                   |
| -------- | ------------------------------ | ---------------------- |
| 要件定義 | 「前提・制約・成功基準を列挙」 | いきなりコード生成     |
| 実装     | 「まずテストのみ」             | テスト＋実装同時       |
| バグ報告 | 「再現手順→原因推定→修正案」   | 原因不確定のままパッチ |

---

## 4. Definition of Ready / Done（横断）

- **Ready**
  1. Acceptance Criteria 明文化
  2. 依存関係チケット解決済み
- **Done**
  1. すべての Quality Gate Pass
  2. ドキュメント更新（README / API Spec / ADR）
  3. モニタリング閾値内で安定
  4. リリースノート記載

## 5. 環境作成

基本的にdevcontainerを使用する。
またベースはghcr.io/keito4/config-base:1.43.0を使用する。

## 6. デプロイ

基本的にgithub actionsを使用する。

## 7. Quality Gates（品質ゲート）

Git操作（commit/push）の前に自動的に品質チェックを実行する仕組みを導入しています。

### 実行されるチェック

1. **Format Check** - コードフォーマットの検証
2. **Lint** - コード品質の検証
3. **Test** - ユニットテストの実行
4. **ShellCheck** - シェルスクリプトの検証
5. **Security Credential Scan** - 認証情報の漏洩チェック
6. **Code Complexity Check** - コード複雑度の検証

### Hooks設定

`.claude/hooks/` ディレクトリに以下のHooksスクリプトが配置されています：

- `block_git_no_verify.py`: `--no-verify` や `HUSKY=0` の使用をブロック
- `pre_git_quality_gates.py`: Git操作前にQuality Gatesを実行

これらは `.claude/settings.local.json` の `hooks` フィールドで設定されており、Claudeによる `git commit` や `git push` の実行前に自動的にトリガーされます。

詳細は [.claude/hooks/README.md](./.claude/hooks/README.md) を参照してください。
