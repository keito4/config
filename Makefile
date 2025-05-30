.PHONY: act-list act-run

# GitHub Actionsのワークフロー一覧を表示
act-list:
	act -l

# 特定のワークフローを実行
act-run:
	act -W .github/workflows/$(workflow).yml

# 特定のワークフローを実行（イベント指定）
act-run-event:
	act -W .github/workflows/$(workflow).yml -e $(event)

# 特定のワークフローを実行（ジョブ指定）
act-run-job:
	act -W .github/workflows/$(workflow).yml -j $(job)
