# VSCode 設定テンプレート

このディレクトリには、プロジェクト固有の VSCode 設定テンプレートが含まれています。
必要に応じて各プロジェクトの `.vscode/` ディレクトリにコピーして使用してください。

## 利用可能なテンプレート

### Tailwind CSS + CVA IntelliSense

Tailwind CSS と Class Variance Authority (CVA) を使用するプロジェクト向けの設定。

**ファイル:**

- `tailwind-cva-settings.json` - VSCode 設定
- `tailwind-extensions.json` - 推奨拡張機能

**使用方法:**

1. 推奨拡張機能を追加:

```bash
# .vscode/extensions.json にマージ
cat .vscode/templates/tailwind-extensions.json
```

2. VSCode 設定を追加:

```bash
# .vscode/settings.json にマージ
cat .vscode/templates/tailwind-cva-settings.json
```

**機能:**

- `cva()` 関数内での Tailwind クラス補完
- `cx()` 関数内での Tailwind クラス補完
- ファイルネスティング（package.json → lock files など）
