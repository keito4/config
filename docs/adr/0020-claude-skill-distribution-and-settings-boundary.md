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
   ADR 0019 の downstream 同期でそのまま 8リポジトリに配布される。ホスト固有の状態を
   コミットすると、downstream 側では 25個のプラグインが有効化され、存在しない
   `agent-deck` を毎セッション実行して失敗する。

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

4. **`.claude/settings.json` はホストの正本のままにし、downstream 配布時に無害化する。**
   symlink 構成は変えず、`script/sync-downstream.js` が配布時に
   `enabledPlugins` / `extraKnownMarketplaces` と `agent-deck` を呼ぶ hook を除去する。
   プラグインの宣言的な正本は `.claude/plugins/plugins.txt` であり、
   `enabledPlugins` は Claude Code の実行時記録として扱う。

## Consequences

### Positive

- リポジトリに置いたスキルが実際に読まれる。AGENTS.md の一覧と実態が一致する。
- 新端末で `setup-claude.sh` を実行すれば、公開／非公開どちらのスキルも復元される。
  端末ローカルにしか無いスキルという状態が構造的に発生しなくなる。
- downstream は移植可能な hooks / permissions だけを受け取る。ホストのプラグイン構成や
  agent-deck 連携が他リポジトリや CI の Claude セッションに漏れない。

### Negative

- `~/.claude/settings.json` は引き続きリポジトリの追跡ファイルへの symlink なので、
  プラグインを増減させるたびに working tree が dirty になる。
- スキルを追加するときはディレクトリを切る必要がある（フラットな `.md` は無視される）。
- private-config のスキルを `~/.claude/skills` に展開する際、同名の実体コピーは
  リンクに置き換えられる（正本が明確なためドリフト除去を優先する）。

### Mitigation

- dirty になった `settings.json` は、プラグイン構成を変えたタイミングで
  `plugins.txt` と併せてレビューしてコミットする。
- 配布時の無害化は `test/sync-downstream.test.js` が固定し、
  スキル展開の両形式は `test/integration/setup_claude.bats` が固定する。
