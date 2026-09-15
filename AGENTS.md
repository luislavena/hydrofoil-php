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
  8.1/, 8.2/          # PHP versions (Debian bullseye)
  8.3/                # PHP 8.3 (Debian bookworm)
  8.4/, 8.5/          # PHP 8.4 and 8.5 (Debian trixie) - 8.5 is latest
    Dockerfile        # Build definition
    goss.yaml         # Test specification (8.4 and older only)
Makefile              # Build and test commands
```

## Commands

```bash
make build VERSION=8.5    # Build image (default: 8.5)
make test VERSION=8.5     # Build and test (default: 8.5)
```

Manual dgoss test (8.4 and older): `GOSS_FILE=docker/8.4/goss.yaml dgoss run ghcr.io/luislavena/hydrofoil-php:8.4 sleep infinity`

## PHP versions configuration

PHP versions defined in `.github/versions.json`. When updating:
1. Update `php_full` field in versions.json
2. Run `make test VERSION=X.Y` to verify

## Tools versions

When updating a tool:
1. Update `TOOL_VERSION` reference in the specific Dockerfile
2. Update SHA256 checksums of that tool
3. Run `make test VERSION=X.Y` to verify

## NodeJS tooling (8.5 and newer)

Version 8.5 installs NodeJS and pnpm with mise, not with per-CPU download
blocks. To change a version:

1. Edit the version in `/etc/mise/config.toml`, written in section 6 of the
   Dockerfile
2. Run `make build VERSION=8.5` to verify

No SHA256 values are needed, mise checks the downloads.

**Important:** watchexec and Overmind stay as direct downloads on purpose. mise
installs those through the GitHub API, which allows 60 requests per hour
without a token, so builds would fail at random.

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

## Image tests

Version 8.5 and newer check the image inside the build, in section 8 of the
Dockerfile. Those checks run in CI on both amd64 and arm64.

Version 8.4 and older use goss files at `docker/<version>/goss.yaml`, which run
only from `make test` on one machine. Categories: command, file, user/group,
package.

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
