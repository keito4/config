.PHONY: version-patch version-minor version-major version-dry-run credentials clean-credentials list-credentials brew-leaves brew-categorized brew-generate test test-verbose test-shell test-setup test-coverage

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

# Testing
test: test-setup test-shell ## Run all tests

test-setup: ## Setup test framework
	@echo "Setting up test framework..."
	@cd test && ./setup.sh

test-shell: test-setup ## Run shell script tests
	@echo "Running shell script tests..."
	@cd test && ./run-tests.sh

test-verbose: test-setup ## Run tests with verbose output
	@echo "Running tests with verbose output..."
	@cd test && ./run-tests.sh --verbose

test-coverage: test-setup ## Check test coverage
	@echo "Checking test coverage..."
	@cd test && ./run-tests.sh | grep -q "Coverage meets 70% threshold" && echo "✓ Coverage meets requirements" || (echo "✗ Coverage below 70% threshold" && exit 1)

test-filter: test-setup ## Run specific tests (use with filter=<pattern>)
	@if [ -z "$(filter)" ]; then echo "Usage: make test-filter filter=<pattern>"; exit 1; fi
	@echo "Running tests matching: $(filter)"
	@cd test && ./run-tests.sh --filter "$(filter)"
