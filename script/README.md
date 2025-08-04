# Refactored Shell Scripts

This directory contains refactored shell scripts with improved modularity, error handling, and maintainability.

## 🚀 Quick Start

Run the migration script to transition to the new structure:

```bash
./script/migrate-to-refactored.sh
```

This will:
- Back up original scripts
- Create compatibility symlinks
- Set proper permissions
- Validate all scripts

## 📁 Directory Structure

```
script/
├── lib/                    # Shared libraries
│   ├── common.sh          # Common functions (logging, error handling)
│   ├── brew.sh            # Homebrew utilities
│   ├── credentials.sh     # Secure credential management
│   └── semver.sh          # Semantic versioning utilities
├── config/                # Configuration files
│   └── settings.conf      # Shared settings and constants
├── legacy/                # Backup of original scripts
├── *-refactored.sh       # Refactored main scripts
└── validate-scripts.sh    # Script validation tool
```

## 📊 Improvements

### Modular Architecture
- **Shared Libraries**: Common functionality extracted to reusable modules
- **Configuration Management**: Centralized settings in `config/settings.conf`
- **Single Responsibility**: Each script focuses on one specific task

### Enhanced Error Handling
- Comprehensive error checking with `set -euo pipefail`
- Structured logging with severity levels
- Retry mechanisms for network operations
- Graceful failure with informative messages

### Security Improvements
- Secure file permissions (600 for credentials, 700 for directories)
- Credential validation and backup
- Masked sensitive output
- 1Password integration for secrets

### Better Maintainability
- ShellCheck compliance for all scripts
- Consistent coding style with shfmt
- Comprehensive documentation
- Backward compatibility through symlinks

## 🔧 Main Scripts

### brew-deps-refactored.sh
Manages Homebrew dependencies with categorization and analysis.

```bash
# Show categorized packages
./script/brew-deps.sh categorized

# Generate Brewfiles
./script/brew-deps.sh generate

# Check dependencies
./script/brew-deps.sh deps <package>
./script/brew-deps.sh uses <package>
```

### version-refactored.sh
Semantic versioning with Git tag management.

```bash
# Bump version
./script/version.sh --type minor

# Create and push release
./script/version.sh --type major --push --release

# Preview changes
./script/version.sh --dry-run
```

### credentials-refactored.sh
Secure credential management with 1Password.

```bash
# Fetch all credentials
./script/credentials.sh fetch

# Fetch specific credential
./script/credentials.sh fetch --template aws

# Validate credentials
./script/credentials.sh validate

# Backup and restore
./script/credentials.sh backup
./script/credentials.sh restore
```

### import-refactored.sh
System configuration import with selective installation.

```bash
# Full installation
./script/import.sh

# Selective installation
./script/import.sh --skip-brew-packages

# Preview mode
./script/import.sh --dry-run

# Clone repositories
./script/import.sh --clone-repos
```

## 🧪 Validation

Validate scripts for best practices and compliance:

```bash
# Validate all scripts
./script/validate-scripts.sh --all

# Auto-fix formatting issues
./script/validate-scripts.sh --fix --all

# Validate specific script
./script/validate-scripts.sh script/import.sh
```

## 🔄 Backward Compatibility

Original script names are maintained as symbolic links to the refactored versions:

- `brew-deps.sh` → `brew-deps-refactored.sh`
- `version.sh` → `version-refactored.sh`
- `credentials.sh` → `credentials-refactored.sh`
- `import.sh` → `import-refactored.sh`

Existing workflows and scripts will continue to work without modification.

## 📝 Environment Variables

Common environment variables that affect script behavior:

- `LOG_LEVEL`: Set logging verbosity (1=ERROR, 2=WARNING, 3=INFO, 4=DEBUG)
- `DRY_RUN`: Preview mode without making changes
- `REPO_ROOT`: Override repository root directory
- `NONINTERACTIVE`: Disable interactive prompts

## 🛡️ Security Considerations

1. **Credentials**: Never commit credential files (*.env, *.key, *.pem)
2. **Templates**: Use 1Password references in templates: `op://vault/item/field`
3. **Permissions**: Ensure proper file permissions are maintained
4. **Backups**: Regular backups are created before sensitive operations

## 🤝 Contributing

When modifying scripts:

1. Follow the existing structure and patterns
2. Ensure ShellCheck compliance: `shellcheck script.sh`
3. Format with shfmt: `shfmt -w script.sh`
4. Update documentation as needed
5. Test in both macOS and Linux environments

## 📚 References

- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [Semantic Versioning](https://semver.org/)