.PHONY: act-list act-run version-patch version-minor version-major version-dry-run

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

# Semantic versioning for devcontainer
version-patch:
	./script/version.sh --type patch && echo "Created patch version tag. Push with: git push origin \$$(git describe --tags --abbrev=0)"

version-minor:
	./script/version.sh --type minor && echo "Created minor version tag. Push with: git push origin \$$(git describe --tags --abbrev=0)"

version-major:
	./script/version.sh --type major && echo "Created major version tag. Push with: git push origin \$$(git describe --tags --abbrev=0)"

version-dry-run:
	./script/version.sh --dry-run
