# Scripts

This directory contains utility scripts for managing configuration, credentials, and development workflows.

## Documentation Scripts

### check-docs-sync.sh

Verifies that generated documentation is synchronized with code changes, preventing documentation drift.

**Purpose**: Ensures developers keep generated documentation in sync with code by failing CI if docs are out of date.

**Usage**:

```bash
./script/check-docs-sync.sh
```

**Configuration**:

Set environment variables to customize behavior:

```bash
# Set documentation generation command (default: npm run docs:generate)
export DOC_GENERATE_CMD="pnpm run docs:generate"

# Set documentation directory (default: docs)
export DOCS_DIR="documentation"

# Run the checker
./script/check-docs-sync.sh
```

**How It Works**:

1. Creates a backup of current documentation
2. Runs the documentation generation command
3. Compares generated docs with the original
4. Fails with helpful error message if differences are found

**Example Output**:

Success:

```
📚 Checking documentation sync...
📝 Generating documentation...
🔍 Comparing documentation...
✅ Documentation is in sync!
```

Failure:

```
📚 Checking documentation sync...
📝 Generating documentation...
🔍 Comparing documentation...
❌ ERROR: Generated documentation is out of sync!

Differences found:
...

Please run the following command and commit the changes:
  npm run docs:generate

Or use the unified command (if available):
  npm run docs:all
```

**CI Integration**:

Add to `.github/workflows/ci.yml`:

```yaml
- name: Check documentation sync
  run: ./script/check-docs-sync.sh
```

Add to `package.json`:

```json
{
  "scripts": {
    "docs:generate": "your-doc-generator-command",
    "docs:check": "./script/check-docs-sync.sh",
    "docs:all": "npm run docs:generate && npm run docs:check"
  }
}
```

**Use Cases**:

- Projects with auto-generated API documentation
- Template-based documentation systems
- Schema-driven documentation
- Any project where docs are generated from code/metadata

**Benefits**:

- ✅ Prevents stale documentation
- ✅ No manual doc update reminders needed
- ✅ Catches issues before merge
- ✅ Clear error messages with fix commands
- ✅ Lightweight (simple bash script, no dependencies)

## Configuration Management Scripts

### export.sh

Exports configuration settings to the home directory.

### import.sh

Imports configuration settings from the home directory.

## Credential Management Scripts

### credentials.sh

Secure credential management using 1Password CLI integration.

### setup-env.sh

Sets up environment variables for DevContainer.

### setup-mcp.sh

Sets up MCP (Model Context Protocol) configuration.

## Development Scripts

### setup-claude.sh

Initializes Claude Code CLI configuration.

### version.sh

Semantic versioning helper.

### update-libraries.sh

Automated library updates for Codex/Claude Code tooling.

## Infrastructure Scripts

### brew-deps.sh

Homebrew dependency management.

### verify-container-setup.sh

Verifies DevContainer setup.

### fix-container-plugins.sh

Fixes container plugin issues.

### install-claude-plugins.sh

Installs Claude plugins.

## See Also

- [Main README](../README.md)
- [Credentials Documentation](../credentials/README.md)
- [DevContainer Documentation](../.devcontainer/README.md)
