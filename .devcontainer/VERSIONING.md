# DevContainer Semantic Versioning

This document explains how to implement semantic versioning for the devcontainer image releases.

## Current Issue

Currently, all devcontainer images are tagged as `latest` only. This makes it difficult to:

- Track which version of the devcontainer you're using
- Roll back to previous versions if needed
- Understand what changes were made between versions

## Proposed Solution

### 1. Use Git Tags for Versioning

Create git tags following semantic versioning (semver) format:

- `v1.0.0` - Major version for breaking changes
- `v1.1.0` - Minor version for new features
- `v1.0.1` - Patch version for bug fixes

### 2. Version Script

Use the provided `script/version.sh` to easily create version tags:

```bash
# Bump patch version (1.0.0 -> 1.0.1)
./script/version.sh --type patch

# Bump minor version (1.0.0 -> 1.1.0)
./script/version.sh --type minor

# Bump major version (1.0.0 -> 2.0.0)
./script/version.sh --type major

# Preview next version without creating tag
./script/version.sh --dry-run
```

### 3. GitHub Workflow Modifications

The `.github/workflows/docker-image.yml` workflow needs to be updated to:

1. **Trigger on tags**: Add tag push trigger
2. **Extract version from git tag**: Use the git tag as the Docker image tag
3. **Build multiple tags**: Create both versioned tag and latest

#### Required Changes to `.github/workflows/docker-image.yml`:

**Add tag trigger:**

```yaml
on:
  push:
    branches: [main]
    tags: ['v*'] # Trigger on version tags
    paths:
      - '.devcontainer/**'
      - 'features/**'
      - '.github/workflows/devcontainer-image.yml'
```

**Add version extraction step:**

```yaml
- name: Extract version
  id: version
  run: |
    if [[ $GITHUB_REF == refs/tags/* ]]; then
      VERSION=${GITHUB_REF#refs/tags/}
    else
      VERSION=latest
    fi
    echo "version=$VERSION" >> $GITHUB_OUTPUT
    echo "Version: $VERSION"
```

**Update devcontainer build step:**

```yaml
- name: Pre-build Dev Container image
  uses: devcontainers/ci@v0.3
  with:
    imageName: ghcr.io/${{ github.repository_owner }}/config-base
    imageTag: ${{ steps.version.outputs.version }}
    platforms: linux/amd64,linux/arm64
    push: always
    runCmd: echo done
```

**Add latest tag for version releases:**

```yaml
- name: Tag as latest (for version tags)
  if: startsWith(github.ref, 'refs/tags/v')
  run: |
    docker tag ghcr.io/${{ github.repository_owner }}/config-base:${{ steps.version.outputs.version }} \
               ghcr.io/${{ github.repository_owner }}/config-base:latest
    docker push ghcr.io/${{ github.repository_owner }}/config-base:latest
```

## Usage Workflow

1. **Make changes** to devcontainer configuration
2. **Test changes** locally
3. **Create version tag**:
   ```bash
   ./script/version.sh --type patch
   git push origin v1.0.1
   ```
4. **GitHub Actions** will automatically build and push the tagged image
5. **Users can reference** specific versions:
   ```json
   {
     "image": "ghcr.io/keito4/config-base:v1.0.1"
   }
   ```

## Benefits

- **Version tracking**: Know exactly which version you're using
- **Rollback capability**: Can easily go back to previous versions
- **Change history**: Git tags provide clear version history
- **Stability**: Production environments can pin to specific versions
- **Development**: Latest tag still available for development

## Migration Plan

1. ✅ Create versioning script (`script/version.sh`)
2. ⚠️ Update GitHub workflow (requires manual modification due to permissions)
3. Create initial version tag (e.g., `v1.0.0`)
4. Test the new versioning workflow
5. Update documentation

## Notes

- The version script follows semantic versioning principles
- Git tags trigger the Docker image builds automatically
- Both versioned and `latest` tags are maintained
- The workflow cannot be automatically updated due to GitHub security restrictions
