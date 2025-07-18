# Python環境をuvに移行する手順

## 現状
- pyenv: Python 3.11.5を管理
- miniconda: インストール済み（削除予定）
- Homebrew Python: 3.10, 3.11, 3.12, 3.13（一部は依存関係あり）

## uvへの移行メリット
1. **高速**: pip/pipenvより数十倍速い
2. **統合管理**: Pythonバージョンとパッケージを一元管理
3. **シンプル**: pyenv + pip + virtualenvの機能を統合
4. **モダン**: Rust製で最新のベストプラクティスに対応

## 移行手順

### 1. 現在のPython環境をバックアップ
```bash
# 現在のglobalパッケージをエクスポート
pip freeze > ~/python-packages-backup.txt
```

### 2. uvでPythonをインストール
```bash
# Python 3.11をインストール
uv python install 3.11

# デフォルトとして設定
uv python pin 3.11
```

### 3. プロジェクトでの使用
```bash
# プロジェクトディレクトリで
uv venv
source .venv/bin/activate

# 依存関係のインストール
uv pip install -r requirements.txt
```

### 4. 不要なツールの削除
```bash
# pyenvの削除
brew uninstall pyenv
rm -rf ~/.pyenv

# minicondaの削除
brew uninstall --cask miniconda
sudo rm -rf /opt/homebrew/miniconda

# 不要なPythonバージョンの削除
brew uninstall python@3.10 python@3.11
# python@3.12, python@3.13は依存関係があるため保持
```

### 5. シェル設定の更新
`.zshrc`から以下を削除：
```bash
# pyenv設定
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# miniconda/anaconda設定
export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
```

## uvの基本的な使い方

### Pythonバージョン管理
```bash
# 利用可能なバージョンを表示
uv python list

# 特定バージョンをインストール
uv python install 3.12

# プロジェクトでバージョンを固定
uv python pin 3.12
```

### パッケージ管理
```bash
# 仮想環境作成
uv venv

# パッケージインストール
uv pip install requests pandas

# requirements.txtから
uv pip install -r requirements.txt

# 依存関係の確認
uv pip freeze
```

### プロジェクト管理
```bash
# pyproject.tomlベースのプロジェクト
uv init my-project
cd my-project
uv sync  # 依存関係をインストール
```

## 注意事項
- gcloud-cli, llvmなどが依存するPythonは残す
- 既存プロジェクトは段階的に移行
- チームで作業している場合は事前に相談