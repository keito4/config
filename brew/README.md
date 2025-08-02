# Homebrew Package Management

このディレクトリはHomebrewパッケージの管理ファイルを含みます。

## ファイル構造

```
brew/
├── MacOSBrewfile              # macOS用の全パッケージ（brew bundle dump --all）
├── MacOSBrewfile.lock.json    # ロックファイル
├── LinuxBrewfile              # Linux用の全パッケージ
├── LinuxBrewfile.lock.json    # ロックファイル
├── StandaloneBrewfile         # 依存関係のないパッケージのみ（自動生成）
└── CategorizedBrewfile        # カテゴリ別に整理されたスタンドアロンパッケージ（自動生成）
```

## 使用方法

### スタンドアロンパッケージの確認

```bash
# 依存関係のないパッケージ一覧を表示
make brew-leaves

# カテゴリ別に表示
make brew-categorized
```

### Brewfileの生成

```bash
# StandaloneBrewfileとCategorizedBrewfileを生成
make brew-generate
```

### パッケージの依存関係確認

```bash
# 特定のパッケージの依存関係を表示
make brew-deps pkg=git

# 特定のパッケージに依存しているパッケージを表示
make brew-uses pkg=openssl
```

## スタンドアロンパッケージとは

スタンドアロンパッケージは以下の条件を満たすパッケージです：

1. **直接インストールされた**：`brew install`コマンドで明示的にインストール
2. **他のパッケージの依存関係ではない**：他のパッケージによって自動的にインストールされていない

これにより、本当に必要なパッケージのみを管理できます。

## 推奨ワークフロー

1. **新しいマシンのセットアップ時**

   ```bash
   # 基本的なパッケージのみインストール
   brew bundle --file=brew/StandaloneBrewfile
   ```

2. **パッケージの整理時**

   ```bash
   # 現在の状態を確認
   make brew-categorized

   # 不要なパッケージを削除
   brew uninstall <package>

   # Brewfileを再生成
   make brew-generate
   ```

3. **定期的なメンテナンス**

   ```bash
   # 全体の状態をエクスポート
   ./script/export.sh

   # スタンドアロンパッケージを更新
   make brew-generate
   ```

## カテゴリ

生成されるCategorizedBrewfileでは、パッケージが以下のカテゴリに分類されます：

### Formulae（コマンドラインツール）

- **Development Tools**: プログラミング言語、ビルドツール
- **Cloud & DevOps**: クラウドCLI、インフラ管理ツール
- **Database & Backend**: データベースクライアント、バックエンドツール
- **Utilities**: 汎用ユーティリティ
- **Media & Graphics**: メディア処理、画像処理ツール
- **Fun & Misc**: エンターテインメント系ツール

### Casks（GUIアプリケーション）

- **Development Tools**: IDE、開発支援ツール
- **Communication**: チャット、ビデオ会議
- **Productivity**: 生産性向上ツール
- **Security & Privacy**: セキュリティ関連
- **AI Tools**: AI関連アプリケーション
- **Utilities**: ユーティリティアプリ
- **Browsers**: Webブラウザ
