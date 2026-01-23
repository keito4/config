# DevContainer 設定テンプレート

このディレクトリには、config-base イメージに追加できるオプショナルな設定テンプレートが含まれています。

## オプショナル Features

`optional-features.json` には、プロジェクトに応じて追加できる DevContainer Features が記載されています。

### 使用方法

プロジェクトの `.devcontainer/devcontainer.json` の `features` セクションに追加してください。

**例: Python Feature を追加**

```json
{
  "name": "My Project",
  "image": "ghcr.io/keito4/config-base:latest",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "latest"
    }
  }
}
```

### 利用可能な Features

| Feature | 説明                                 |
| ------- | ------------------------------------ |
| Python  | Python 開発環境（pip, venv 含む）    |
| Ruby    | Ruby 開発環境（rbenv, bundler 含む） |
| Go      | Go 開発環境                          |
| Java    | Java 開発環境（OpenJDK）             |
| .NET    | .NET 開発環境                        |

**注意**: config-base イメージには既に基本的な Python (python3, pip) がインストールされています。
Python Feature を追加すると、pyenv による複数バージョン管理などの追加機能が利用可能になります。

## 参考

- [DevContainer Features 一覧](https://containers.dev/features)
- [config-base イメージの使用方法](../../docs/using-config-base-image.md)
