先日、Claude Codeが勝手にgit push --forceしかけました。草
差分確認のダイアログを「Always allow」で飛ばしてた自分のせいなんですけど、冷や汗が止まらなかったです。結構大事なリポジトリだったので、、
そこから真剣にセキュリティ設定を見直しました。公式ドキュメントを改めて読み直したら、知らなかった設定がかなりあったんですよね。
Anthropicの公式ドキュメントにもこう書いてあります：
Claude Code only has the permissions you grant it. You're responsible for reviewing proposed code and commands for safety before approval.
つまり「セキュリティは自分で設定しろ」ということです。
公式ドキュメントと自分の半年間の運用経験を合わせて、「業務で使うならこれだけはやっておいてほしい」という7つの設定をまとめました。

1. サンドボックスを有効にする（そして脱出口を塞ぐ）
   これが一番大事です。サンドボックスはClaude Codeが実行するBashコマンドをOSレベルで隔離する機能で、macOSではSeatbelt、LinuxではBubble Wrapが使われます。
   有効化は/sandboxコマンドで確認できます。設定ファイルに書く場合はこうです：
   {
   "sandbox": {
   "enabled": true,
   "allowUnsandboxedCommands": false
   }
   }
   ポイントは2行目のallowUnsandboxedCommands: false。
   実はサンドボックスを有効にしただけでは不十分で、dangerouslyDisableSandboxパラメータを使えばサンドボックスを回避できてしまいます。allowUnsandboxedCommands: falseを設定して初めて、この脱出口が完全に塞がります。
   自分はこれを知らずにサンドボックス有効にしただけで安心してました。「有効化」と「完全に塞ぐ」は別物です。
2. denyルールで危険なコマンドを止める
   Claude Codeのパーミッション評価はdeny → ask → allowの順番で処理されます。denyは最優先。後からallowで上書きされません。
   これが地味に強力で、セッション中に「Always allow」を連打しても、denyに入っているコマンドは絶対に実行されません。
   {
   "permissions": {
   "deny": [
   "Bash(rm -rf *)",
   "Bash(curl *)",
   "Bash(wget *)",
   "Bash(git push --force *)",
   "Bash(chmod 777 *)"
   ]
   }
   }
   公式ドキュメントにも「curlとwgetはデフォルトでブロック」と書いてありますが、明示的にdenyに入れておくと確実です。
   自分の場合はgit push --forceとgit reset --hardもdenyに入れています。force pushやreset --hardの事故は取り返しがつきません。
3. 機密ファイルへのアクセスを塞ぐ
   .envファイル、SSH鍵、AWSクレデンシャル。これらをClaude Codeに読まれたくない場合は、明示的にブロックします。
   {
   "permissions": {
   "deny": [
   "Read(./.env)",
   "Read(./.env.*)",
   "Read(**/*.pem)",
   "Read(**/*.key)"
   ]
   },
   "sandbox": {
   "filesystem": {
   "denyRead": ["~/.aws/credentials", "~/.ssh"]
   }
   }
   }
   パーミッションのdenyはClaude Codeの「Read」ツール経由のアクセスをブロックします。sandboxのfilesystem.denyReadはBashコマンド経由（cat ~/.ssh/id_rsa等）もブロックします。両方設定しておくのが確実です。
   プロンプトインジェクション攻撃（悪意あるコードにAIの指示が埋め込まれるケース）では、Claude Codeが意図せず機密ファイルを読もうとする可能性があります。だからこそ、読み取り自体をブロックしておくのが重要です...！
4. ネットワークのホワイトリストを設定する
   サンドボックスのネットワーク設定で、アクセス可能なドメインをホワイトリスト方式で制限できます。GitHub、npm、PyPIなど業務に必要なドメインだけを許可し、それ以外をブロックする形です。
   Managed Settingsを使う場合は allowManagedDomainsOnly: true で、管理者が指定したドメインのみに制限することもできます。
   これが効くのはプロンプトインジェクション対策です。悪意あるコードがClaude Codeを操って外部サーバーにデータを送信しようとしても、ホワイトリスト外のドメインへの通信はブロックされます。
   Anthropicの公式ドキュメントでも「Web fetchは別のコンテキストウィンドウを使って、悪意あるプロンプトの注入を防いでいる」と説明されていますが、ネットワーク自体を絞っておけばさらに安全です。
5. PreToolUseフックで独自の安全チェックを挟む
   ここからは中〜上級者向けです。Claude Codeにはhooksという仕組みがあって、ツール実行の前後にカスタムスクリプトを挟めます。
   自分は実際にhooksを使っていて、セッション終了時の通知やpermission確認の通知を設定しています。セキュリティ用途でも同じ仕組みで使えます。
   セキュリティ用途では、Bashコマンド実行前に危険なパターンを検出するスクリプトを挟めます：
   {
   "hooks": {
   "PreToolUse": [
   {
   "matcher": "Bash",
   "hooks": [{
   "type": "command",
   "command": ".claude/hooks/validate-command.sh"
   }]
   }
   ]
   }
   }
   フックスクリプトでexit 2を返すとコマンドがブロックされます。denyルールでは対応しきれない複雑な条件分岐（「本番環境への接続を含むコマンドはブロック」等）に使えます。
   フックの種類は4つ：コマンド実行、HTTP webhook、LLMプロンプト評価、エージェント型。セキュリティ要件に応じて選べます。
6. /permissionsで定期的に棚卸しする
   Claude Codeを長く使っていると、セッション中に「Always allow」で許可したルールがどんどん蓄積されます。
   /permissionsコマンドで現在の権限設定を一覧表示できます。/statusでどの設定ファイルが読み込まれているか、エラーがないかも確認できます。
   月1回くらいで棚卸しするのがおすすめです。不要なallowルールが残っていないか、denyルールが意図通りに設定されているかを確認してください。
   最近のアップデートでConfigChangeフックが追加されました。セッション中に権限設定が変更されたタイミングで通知を飛ばしたり、変更を監査ログに記録したりできます。チーム開発ではかなり使えます。
7. チーム開発：Managed Settingsで組織ポリシーを強制する
   個人で使う分には1〜6で十分です。チームで使う場合は、Managed Settingsで組織全体にポリシーを強制できます。
   2つの方式があります：
   Server-managed settings（Public Beta）: Claude.aiの管理コンソールから設定を配信。MDM不要でリモートワーク環境でも使えます
   Endpoint-managed settings: JamfやIntuneでデバイスに直接配置。セキュリティ重視の組織向け
   組織管理者が設定すべき主要キー：
   {
   "permissions": {
   "disableBypassPermissionsMode": "disable"
   },
   "allowManagedPermissionRulesOnly": true,
   "allowManagedHooksOnly": true,
   "allowManagedMcpServersOnly": true
   }
   allowManagedPermissionRulesOnly: trueにすると、ユーザーが独自に設定したallow/denyルールは全て無効化され、管理者が設定したルールだけが適用されます。
   MCPサーバーも管理者が許可したものだけに限定できます。勝手にサードパーティのMCPサーバーを追加されるリスクがなくなります。
   もっと堅くしたい人向けのオススメ
   devcontainerで完全隔離
   Anthropic公式がdevcontainerのリファレンス実装を公開しています。VS Codeの「Reopen in Container」で簡単に起動でき、ホストマシンから完全に隔離された環境でClaude Codeを動かせます。
   devcontainer内ならネットワークもファイルシステムも隔離されるので、最もセキュアな環境になります。ただし環境構築のコストはあります。
   外部サンドボックス（OpenShell / NemoClaw）

NVIDIAのNemoClaw経由でOpenShellを使うと、プロセス自体を外側からサンドボックスできます。エージェントが自分でガードレールを外すことができないので、インプロセスのガードレールより堅牢です。エンタープライズ向け。
AgentShield
Anthropicのハッカソンから生まれたオープンソースツールです。1,282テスト・102ルールでClaude Codeのワークフローをスキャンします。トークン使用量を約60%削減しつつ本番レベルの問題を検出できると謳っています。
便利さと安全性のバランス...
Claude Codeは便利すぎて、セキュリティ設定を後回しにしがちです。
でも、AIエージェントが人間と同じ権限でコマンドを実行できるということは、設定を間違えたときのリスクも人間と同じということです。
全部を常時オンにする必要はありません。まずは1〜4の基本設定だけでも、センシティブな作業のときに切り替えられるようにしておいてください。それだけで「何も設定していない状態」とは雲泥の差になります。
セキュリティは「やりすぎ」くらいがちょうどいいと思っています...
（ちなみに自分は普段はbypassPermissionsで全開にして使ってます。笑 ただ、しっかりした開発案件やセンシティブな情報を扱うときだけ、ここで紹介した設定に切り替えてます。全部を常時オンにする必要はなくて、場面に応じて使い分けるのがおすすめです）
