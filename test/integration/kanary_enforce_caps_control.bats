#!/usr/bin/env bats
# kanary-enforce-caps-control.sh の振る舞いテスト
#
# 回帰の対象: darwin-rebuild の home-manager activation は PATH を nix store だけに
# 差し替えるため、/usr/bin にしか無い plutil / defaults / python3 等が解決できず、
# この helper が毎回サイレントにスキップされていた（エラーで落ちないので気付けない）。

load ../test_helper/test_helper

SCRIPT() { echo "$REPO_ROOT/script/macos/kanary-enforce-caps-control.sh"; }

# macOS 専用スクリプトなので、それ以外では丸ごとスキップする
require_macos() {
    [ "$(uname -s)" = "Darwin" ] || skip "macOS only (plutil/defaults required)"
}

# 偽 HOME に Kanary の設定 plist を作る。$1 = true|false
write_settings() {
    local caps="$1"
    mkdir -p "$TEST_TEMP_DIR/Library/Preferences"
    local plist="$TEST_TEMP_DIR/Library/Preferences/download.kanary.settings.plist"
    local json="{\"settings\":{\"windowMoveResize\":{\"capsLockRemappedToControl\":$caps}}}"
    /usr/bin/plutil -create binary1 "$plist"
    /usr/bin/plutil -insert app_settings -data "$(printf '%s' "$json" | /usr/bin/base64)" "$plist"
}

# /usr/bin を含まない PATH を作る（bash だけは shebang 解決のために置く）。
# activation 時の「nix store だけの PATH」を再現する。
restricted_path() {
    mkdir -p "$TEST_TEMP_DIR/bin"
    ln -sf "$(command -v bash)" "$TEST_TEMP_DIR/bin/bash"
    echo "$TEST_TEMP_DIR/bin"
}

@test "kanary-enforce-caps-control.sh exists and is executable" {
    assert_file_exists "$REPO_ROOT/script/macos/kanary-enforce-caps-control.sh"
    [ -x "$REPO_ROOT/script/macos/kanary-enforce-caps-control.sh" ]
}

@test "prepends the macOS system paths so activation can resolve its tools" {
    # PATH に /usr/bin が無い状態でも動く必要があるため、標準パスを先頭に足している。
    grep -q 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:\$PATH"' "$(SCRIPT)"
}

@test "reads the setting even when PATH lacks /usr/bin" {
    require_macos
    write_settings true

    run env HOME="$TEST_TEMP_DIR" PATH="$(restricted_path)" "$(SCRIPT)"
    assert_success
    # 読めなかったときだけ出るメッセージ。出ていたら PATH 解決に失敗している。
    ! printf '%s\n' "$output" | grep -q 'could not read'
    ! printf '%s\n' "$output" | grep -q 'command not found'
}

@test "is a silent no-op when the setting is already true" {
    require_macos
    write_settings true

    run env HOME="$TEST_TEMP_DIR" PATH="$(restricted_path)" "$(SCRIPT)"
    assert_success
    [ -z "$output" ]
}

# NOTE: 「設定が false のときに有効化する」書き込み経路はテストしない。
# `defaults write` は HOME ではなく cfprefsd 経由でユーザーの実ドメインに書くため、
# 偽 HOME を渡しても本物の Kanary 設定を上書きしてしまう（実際に事故を起こした）。
# さらに実行中の Kanary を quit する副作用もある。PATH 解決の回帰は上の
# 「reads the setting even when PATH lacks /usr/bin」で十分に押さえられている。

@test "skips quietly when Kanary has never been launched" {
    require_macos
    # plist を作らない

    run env HOME="$TEST_TEMP_DIR" PATH="$(restricted_path)" "$(SCRIPT)"
    assert_success
    printf '%s\n' "$output" | grep -q 'settings not found'
}
