#!/usr/bin/env bash
# 組織固有の値（組織名・組織別の MCP サーバー名など）は公開リポジトリに置かず、
# 非公開の private-config にある config/org.env から読み込む。
#
# - ファイルが無い端末では何も設定しない（汎用の既定値で動く）
# - 呼び出し側で既に設定済みの環境変数は上書きしない
# - source/eval せず KEY=VALUE 行だけを解釈する（任意コードを実行しない）

# shellcheck disable=SC2034
PRIVATE_CONFIG_ORG_ENV_RELPATH="config/org.env"

private_config::org_env_path() {
    printf '%s/%s' "${PRIVATE_CONFIG_DIR:-$HOME/develop/github.com/keito4/private-config}" \
        "$PRIVATE_CONFIG_ORG_ENV_RELPATH"
}

private_config::load_org_env() {
    local file line key value
    file="$(private_config::org_env_path)"
    [[ -f "$file" ]] || return 0

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        [[ "$line" =~ ^([A-Z_][A-Z0-9_]*)=(.*)$ ]] || continue
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        value="${value%\"}"
        value="${value#\"}"
        [[ -n "${!key+x}" ]] && continue
        export "$key=$value"
    done <"$file"
}

# 環境変数名として展開に使う値を検証する。不正なら理由を出して終了する
# （シェルへ埋め込むので、名前以外の文字列を通すとコマンド注入になる）。
private_config::assert_env_name() {
    local label="$1" value="$2"
    [[ "$value" =~ ^[A-Z_][A-Z0-9_]*$ ]] && return 0
    printf '%s が環境変数名として不正です: %s\n' "$label" "$value" >&2
    exit 1
}

# 空白区切りの一覧 $1 に $2 が含まれるか（大文字小文字を区別しない。空の $2 は含まれない）
private_config::list_contains() {
    local list needle item
    list="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    needle="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"
    [[ -n "$needle" ]] || return 1
    for item in $list; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}
