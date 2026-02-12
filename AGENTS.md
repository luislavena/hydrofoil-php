# Agents guide

Guidance for AI coding agents working in this repository.

## Project overview

**Docker image build project** (not a PHP application) that creates development
container images for PHP. Contains Dockerfiles, goss tests, and CI/CD workflows.

Technologies: Dockerfile, YAML (goss/GitHub Actions), Makefile, Shell, JSON

## Repository structure

```
.github/
  workflows/ci.yml    # CI pipeline with change detection
  versions.json       # PHP version definitions (source of truth)
docker/
  8.1/, 8.2/, 8.3/    # PHP versions (Debian bullseye)
  8.4/                # PHP 8.4 (Debian trixie) - latest
    Dockerfile        # Build definition
    goss.yaml         # Test specification
Makefile              # Build and test commands
```

## Commands

```bash
make build VERSION=8.4    # Build image (default: 8.4)
make test VERSION=8.4     # Build and test (default: 8.4)
```

Manual dgoss test: `GOSS_FILE=docker/8.4/goss.yaml dgoss run ghcr.io/luislavena/hydrofoil-php:8.4 sleep infinity`

## PHP versions configuration

PHP versions defined in `.github/versions.json`. When updating:
1. Update `php_full` field in versions.json
2. Run `make test VERSION=X.Y` to verify

## Tools versions

When updating a tool:
1. Update `TOOL_VERSION` reference in the specific Dockerfile
2. Update SHA256 checksums of that tool
3. Run `make test VERSION=X.Y` to verify

## Dockerfile conventions

**Structure:**
- Use BuildKit syntax: `# syntax = docker/dockerfile:1.4`
- Numbered section comments: `# ---\n# 1. Section name`
- Use `set -eux` in all RUN commands

**Cache mounts:** Use BuildKit cache for apt (see existing Dockerfiles for pattern)

**Multi-arch:** Support amd64/arm64 using `case "$(arch)" in x86_64|aarch64`

**Security:**
- Verify all downloads with SHA256: `echo "$SHA256 *file" | sha256sum -c -`
- Use `curl --fail`
- Add smoke tests: `[ "$(command -v tool)" = '/path/tool' ]; tool --version`

**Cleanup:** Remove archives after extraction; clean backup files from system commands

## Goss tests

Tests in `docker/<version>/goss.yaml`. Categories: command, file, user/group, package

```yaml
command:
  php-installed:
    exec: "php --version"
    exit-status: 0
```

## Git conventions

**Commits:** 50 char subject, capitalized, imperative mood, no period. Body at 72 chars explains what/why.

**Branches:** Use dashes: `feature-new-functionality` (not slashes)

**Worktrees:** Create in `.worktrees/` directory

## CI/CD

Pipeline detects changes in `docker/`, builds affected versions with matrix strategy,
supports amd64/arm64, pushes to GHCR on main. Manual dispatch available.

## Contribution policy

Bug fixes only. Features require GitHub issue discussion first.
