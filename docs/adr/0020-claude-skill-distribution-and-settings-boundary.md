# ADR 0020: Claude スキルの配布形式と settings.json のホスト／downstream 境界

## Status

Accepted

## Context

Claude Code のアセットについて、この端末の実態と リポジトリの記述が乖離していた。

1. **スキルが読まれていなかった**
   `.claude/skills/ci-check.md` のようにフラットな `.md` で置いていたが、Claude Code は
   `<name>/SKILL.md` 形式のディレクトリしかスキルとして認識しない。AGENTS.md の一覧には
   4件が載っているのに、セッションで利用可能なスキルには 1件も現れていなかった。
   唯一使えていた `n8n-workflow-pr-review` は、`~/.claude/skills/` に手でコピーされた
   実体が別にあっただけで、リポジトリの正本とは内容がドリフトしていた。

2. **正本のないスキルが端末上に増えていた**
   `~/.claude/skills/` には、公開 config にも keito4/private-config にも存在しない
   スキルの実体が 4件あった。過去にも同じ理由で消失し、private-config の
   `4eb7c74` で復旧している。`setup-claude.sh` の private スキル展開は
   フラットな `<name>.md` しか見ておらず、`review-queue/` のようにスクリプトを伴う
   ディレクトリ形式のスキルは新端末で materialize されなかった。

3. **`.claude/settings.json` が二役を持っている**
   `~/.claude/settings.json` はこのリポジトリの `.claude/settings.json` への symlink であり、
   Claude Code はここに `enabledPlugins` / `extraKnownMarketplaces` を、agent-deck は
   `hooks` に `agent-deck hook-handler` を書き戻す。一方で同じファイルは
   ADR 0019 の downstream 同期でそのまま 8リポジトリに配布され、さらに
   **このリポジトリ自身の CI（`claude-code-review.yml` 上の Claude Code）にも読まれる**。
   実際、agent-deck の hooks を含んだ状態でコミットしたところ、`claude-review` ジョブが
   2回とも 1ターン・cost 0・約175秒で `is_error` となり失敗した（runner に `agent-deck`
   が無く SessionStart hook が解決できない）。`enabledPlugins` も同様に、downstream 側で
   25個のプラグインを有効化してしまう。

## Decision

1. **スキルは `<name>/SKILL.md` ディレクトリ形式のみとする。**
   リポジトリの 4スキルをディレクトリへ移行し、`script/update-agents-md.sh` の一覧生成も
   この形式だけを見る。フラットな `.md` は「置いても読まれない」ため許容しない。

2. **`setup-claude.sh` がスキルの唯一の配布経路になる。**
   `link_skills_from_dir` がリポジトリと private-config の両方から
   `~/.claude/skills/<name>` に symlink を張る。フラット形式（`<name>.md` →
   `<name>/SKILL.md`）とディレクトリ形式（`<name>/` をそのまま）の両方に対応し、
   名前が衝突した場合は private-config を勝たせる。source 側の symlink エントリは
   `npx skills add` でホストに入れた実体への参照なので配布対象にしない。

3. **個人情報を含むスキルは private-config が正本、それ以外は公開 config が正本。**
   どちらにも無いスキルは「存在しない」ものとして扱う（端末ローカルの実体は復元されない）。

4. **`~/.claude/settings.json` はホスト所有の実体ファイルにする。**
   追跡ファイルへの symlink をやめ、`setup-claude.sh` の `seed_user_settings` が
   リポジトリのベースラインを「初回の種」としてだけ配る（既存ファイルは上書きしない。
   旧構成の symlink は内容を保ったまま実体へ切り離す）。これにより、Claude Code や
   agent-deck の書き戻しがリポジトリを汚さなくなる。

5. **追跡する `.claude/settings.json` には端末固有の hook を入れない。**
   このファイルは downstream 8リポジトリと自身の CI の両方で読まれるため、
   `agent-deck` のようにホストにしか無いコマンドを呼ぶ hook は置かない。
   プラグインの宣言的な正本は `.claude/plugins/plugins.txt` であり、
   `enabledPlugins` は Claude Code の実行時記録として扱う。二重の防御として
   `script/sync-downstream.js` が配布時に `enabledPlugins` /
   `extraKnownMarketplaces` と `agent-deck` を呼ぶ hook を除去する。

## Consequences

### Positive

- リポジトリに置いたスキルが実際に読まれる。AGENTS.md の一覧と実態が一致する。
- 新端末で `setup-claude.sh` を実行すれば、公開／非公開どちらのスキルも復元される。
  端末ローカルにしか無いスキルという状態が構造的に発生しなくなる。
- downstream は移植可能な hooks / permissions だけを受け取る。ホストのプラグイン構成や
  agent-deck 連携が他リポジトリや CI の Claude セッションに漏れない。
- プラグインを増減させても working tree が dirty にならない。

### Negative

- `~/.claude/settings.json` が実体になるため、リポジトリのベースライン更新
  （新しい Quality Gate hook 等）は自動では反映されない。ホスト側の hooks には
  agent-deck の登録が混ざるため、機械的な上書きはできない。
- スキルを追加するときはディレクトリを切る必要がある（フラットな `.md` は無視される）。
- private-config のスキルを `~/.claude/skills` に展開する際、同名の実体コピーは
  リンクに置き換えられる（正本が明確なためドリフト除去を優先する）。

### Mitigation

- ベースラインに hooks を足したときは、`~/.claude/settings.json` にも手で反映する
  （`.claude/hooks/` 側の実体はリポジトリ参照なので、追加が必要なのは登録だけ）。
- 有効なプラグインを増やしたときは `plugins.txt` に宣言を足す。新端末の復元経路はこちら。
- 配布時の無害化は `test/sync-downstream.test.js` が、スキル展開と
  `~/.claude/settings.json` の扱いは `test/integration/setup_claude.bats` が固定する。
