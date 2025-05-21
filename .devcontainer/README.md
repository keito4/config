# 共通 devcontainer コンポーネント

このディレクトリには他のリポジトリから利用できる共通の devcontainer 設定が含まれています。

## 使い方

1. `.devcontainer` ディレクトリをプロジェクトにコピーするか、`devcontainer.json` からこのディレクトリを参照します。
2. devcontainer を起動すると `features/common` が実行され、シェルの関数や Git 設定がホームディレクトリにコピーされます。

```jsonc
"features": {
    "../features/common": {}
}
```

Homebrew などの重いパッケージはインストールされず、最小限の設定のみが適用されます。
