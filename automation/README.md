# automation/

`weekly-ingest` スキル（[.claude/skills/weekly-ingest.md](../.claude/skills/weekly-ingest.md)）と
`screenshot-ingest` スキル（[.claude/skills/screenshot-ingest.md](../.claude/skills/screenshot-ingest.md)）が使用する定義ファイル置き場。
API が提供されていないサイト・アプリからの週次データ取り込みと、しきい値チェックを宣言的に管理する。

## 構成

| パス                 | 役割                                                                               |
| -------------------- | ---------------------------------------------------------------------------------- |
| `adapters/*.yaml`    | ブラウザ自動操作（weekly-ingest）のサイトごとの取得定義（`_` 始まりは無視）        |
| `screenshots/*.yaml` | スクショ読み取り（screenshot-ingest）のアプリごとの取得定義（`_` 始まりは無視）    |
| `rules.yaml`         | しきい値判定ルール（両スキル共用。`site` にはアダプタの `site` / `source` を指定） |

## アダプタスキーマ

```yaml
site: example-bank # 一意なサイト識別子（kebab-case）
enabled: false # true にすると週次実行の対象になる
url: https://example.com/login
auth:
  secret: EXAMPLE_BANK # Doppler / 環境変数のプレフィックス（<secret>_USER / <secret>_PASS）
  totp_secret: EXAMPLE_BANK_TOTP # TOTP 2FA がある場合のみ。シークレット名を指定（値は書かない）
metrics:
  - name: balance # 取得する値の名前
    unit: JPY
    description: 普通預金残高
steps: # ログイン〜取得までの手順（自然言語。Playwright 実行時の指示になる）
  - ログインページを開く
  - ユーザー ID とパスワードを入力してログインする
  - ホーム画面に表示される「普通預金残高」を取得する
notes: |
  レイアウト変更時の復旧に役立つ情報（対象要素の特徴など）を書いておく。
```

## スクショ定義スキーマ（screenshots/）

Web 版がなくブラウザで到達できないスマホ専用アプリ向け。ユーザーが Slack の
インボックスチャンネルに投稿したスクリーンショットから値を読み取る。

```yaml
source: example-app # 一意な識別子（kebab-case）
enabled: false # true にすると週次取り込みの対象になる
app: サンプル銀行アプリ # スマホアプリ名（画像の判別に使う）
metrics:
  - name: balance
    unit: JPY
    description: 普通預金残高
capture_hint: ホーム画面の残高表示が写るようにスクリーンショットを撮る
notion_page: '' # 任意。取り込み結果を1行追記する Notion ページ URL
notes: |
  画像判別・読み取りのヒント（画面の特徴、値の表示位置など）を書いておく。
```

## ルールスキーマ（rules.yaml）

```yaml
rules:
  - site: example-bank
    metric: balance
    condition: '< 100000' # value に対する比較式
    severity: alert # alert = 即 Slack 通知 / warn = 週次サマリに含める
    message: 残高が 10 万円を下回りました
```

## 認証情報の取り扱い

- ID・パスワード・TOTP シークレットの **値** はこのリポジトリに一切書かない。Doppler（推奨）または環境変数で管理する
- YAML に書くのはシークレットの **参照名** のみ
- 取得結果のログ・通知でも認証情報は必ず `***` でマスクする

## 制約

- 参照系のみ。書き込み系操作（振込・購入・設定変更）はアダプタとして定義しない
- 金融機関は利用規約で自動アクセスを制限している場合がある。追加前に対象サイトの規約を確認すること
