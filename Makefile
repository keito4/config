.PHONY: version-patch version-minor version-major version-dry-run credentials clean-credentials list-credentials claude-setup nix-switch nix-build nix-update nix-check

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

# Claude Code setup
claude-setup: ## Setup Claude Code (sync settings + install plugins)
	@./script/setup-claude.sh

# Nix management
nix-switch: ## Apply Nix configuration (darwin-rebuild switch)
	sudo darwin-rebuild switch --flake ./nix

nix-build: ## Build Nix configuration without applying
	darwin-rebuild build --flake ./nix

nix-update: ## Update Nix flake inputs
	cd nix && nix flake update

nix-check: ## Check Nix flake for errors
	cd nix && nix flake check
