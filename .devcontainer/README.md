# 共通 devcontainer コンポーネント

このディレクトリには他のリポジトリから利用できる共通の devcontainer 設定が含まれています。

## 使い方

1. `.devcontainer` ディレクトリをプロジェクトにコピーするか、`devcontainer.json` からこのディレクトリを参照します。
2. devcontainer を起動すると、`features/common` が実行され、リポジトリ内の `script/import.sh` を用いて各種設定が自動で適用されます。

```jsonc
"features": {
    "../features/common": {}
}
```

これにより、シェル設定や VS Code 拡張などがインストールされます。
