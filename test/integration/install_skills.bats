#!/usr/bin/env bats
# install-skills.sh の導入判定に関する回帰テスト
#
# インストールは常にグローバル (`npx skills add -g` → ~/.agents/skills) で行うため、
# 「導入済みか」の判定もグローバルだけを見なければならない。プロジェクト配下
# (.agents/skills/) を判定に含めると、そこに実体がある限りグローバル導入が
# 恒久的にスキップされ、当該スキルが他ディレクトリから見えなくなる (#1196)。

load ../test_helper/test_helper

# npx を stub して、skills.txt のエントリに対して実際にインストールが
# 走ったかどうかをログファイルで観測できるサンドボックスを用意する。
setup_skill_sandbox() {
    REPO_ROOT_ABS="$(cd "$REPO_ROOT" && pwd)"
    SANDBOX="${TEST_TEMP_DIR}/sandbox"
    FAKE_HOME="${SANDBOX}/home"
    PROJECT_DIR="${SANDBOX}/project"
    STUB_BIN="${SANDBOX}/bin"
    NPX_LOG="${SANDBOX}/npx.log"
    SKILLS_FILE="${PROJECT_DIR}/.claude/skills/skills.txt"

    mkdir -p "$FAKE_HOME" "$(dirname "$SKILLS_FILE")" "$STUB_BIN"

    cat > "${STUB_BIN}/npx" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "${NPX_LOG}"
STUB
    chmod +x "${STUB_BIN}/npx"

    printf '%s\n' "example/demo-skill" > "$SKILLS_FILE"
}

run_installer() {
    cd "$PROJECT_DIR" || return 1
    run env HOME="$FAKE_HOME" PATH="${STUB_BIN}:${PATH}" \
        "${REPO_ROOT_ABS}/script/install-skills.sh" "$SKILLS_FILE"
}

@test "install-skills.sh installs globally even if the skill exists in the project dir" {
    setup_skill_sandbox
    # 過去に -g なしで導入された等の理由でプロジェクト配下に実体がある状態
    mkdir -p "${PROJECT_DIR}/.agents/skills/demo-skill"

    run_installer

    assert_success
    grep -q "example/demo-skill" "$NPX_LOG"
}

@test "install-skills.sh skips installation when the skill exists globally" {
    setup_skill_sandbox
    mkdir -p "${FAKE_HOME}/.agents/skills/demo-skill"

    run_installer

    assert_success
    [ ! -s "$NPX_LOG" ]
}
