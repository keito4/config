.PHONY: act-list act-run version-patch version-minor version-major version-dry-run credentials clean-credentials list-credentials brew-leaves brew-categorized brew-generate

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

# Credential management
credentials: ## Fetch credentials from 1Password
	@echo "Fetching credentials from 1Password..."
	@./script/credentials.sh fetch

clean-credentials: ## Clean up credential files
	@echo "Cleaning up credential files..."
	@./script/credentials.sh clean

list-credentials: ## List available credential templates
	@./script/credentials.sh list

# Brew dependency management
brew-leaves: ## List Homebrew packages without dependencies
	@./script/brew-deps.sh leaves

brew-categorized: ## List Homebrew packages organized by category
	@./script/brew-deps.sh categorized

brew-generate: ## Generate Brewfiles for standalone packages
	@echo "Generating standalone Brewfiles..."
	@./script/brew-deps.sh generate

brew-deps: ## Show dependencies of a specific package
	@if [ -z "$(pkg)" ]; then echo "Usage: make brew-deps pkg=<package>"; exit 1; fi
	@./script/brew-deps.sh deps $(pkg)

brew-uses: ## Show packages that depend on a specific package
	@if [ -z "$(pkg)" ]; then echo "Usage: make brew-uses pkg=<package>"; exit 1; fi
	@./script/brew-deps.sh uses $(pkg)
