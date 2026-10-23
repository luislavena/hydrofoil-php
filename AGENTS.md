# Agents guide

Guidance for AI coding agents working in this repository.

## Project overview

**Docker image build project** (not a PHP application) that creates development
container images for PHP. Contains Dockerfiles, image tests (Brat) and CI/CD
workflows.

Technologies: Dockerfile, YAML (GitHub Actions), Makefile, Shell (Brat), JSON

## Repository structure

```
.github/
  workflows/ci.yml    # CI pipeline with change detection
  workflows/image.yml # Build, test and publish one PHP version
  versions.json       # PHP version definitions (source of truth)
docker/
  8.1/                # PHP 8.1, end of life: kept for reference, not built
  8.2/, 8.3/          # PHP 8.2 and 8.3 (Debian bookworm)
  8.4/, 8.5/          # PHP 8.4 and 8.5 (Debian trixie) - 8.5 is latest
    Dockerfile        # Build definition
    test/             # Image tests: symlinks to test/, plus version-only tests
test/                 # Shared image tests (Brat)
vendor/brat           # Brat test runner (single file, committed)
Makefile              # Build and test commands
```

## Commands

```bash
make build VERSION=8.5    # Build image (default: 8.5)
make test VERSION=8.5     # Build and test (default: 8.5)
```

Run one test file or one test, against an image you built:

```bash
IMAGE=ghcr.io/luislavena/hydrofoil-php:8.5 vendor/brat docker/8.5/test/php.brat
IMAGE=ghcr.io/luislavena/hydrofoil-php:8.5 vendor/brat docker/8.5/test/php.brat:10
```

## PHP versions configuration

PHP versions defined in `.github/versions.json`. When updating:
1. Update `php_full` field in versions.json
2. Update the `ARG PHP_VERSION` default in the Dockerfile (`make` uses it)
3. Run `make test VERSION=X.Y` to verify

To retire a version that reached end of life, remove it from versions.json
and move its badge to the unsupported row in `README.md`. Keep its
`docker/<version>` folder.

## Tools versions

When updating a tool:
1. Update `TOOL_VERSION` reference in the specific Dockerfile
2. Update SHA256 checksums of that tool
3. Run `make test VERSION=X.Y` to verify

For NodeJS and pnpm on PHP 8.5 and newer, this does not apply. See
"NodeJS tooling (8.5 and newer)" below instead.

## NodeJS tooling (8.5 and newer)

Version 8.5 installs NodeJS and pnpm with mise, not with per-CPU download
blocks. To change a version:

1. Edit the `node = "..."` or `pnpm = "..."` line in section 6 of the
   Dockerfile, which writes `/etc/mise/config.toml` at build time
2. Run `make test VERSION=8.5` to verify

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

Supported versions use [Brat](https://codeberg.org/sstephenson/brat) tests
in `docker/<version>/test/*.brat`. The tests run on the host and start the image
with `docker run`, so they also check the fixuid entrypoint and the non-root
user. `make test` runs them locally, and CI runs them on amd64 and arm64 before
it publishes the image.

- Put a test that applies to every version in the shared `test/` folder, and
  symlink it from each `docker/<version>/test` folder (Eg.
  `ln -s ../../../test/php.brat docker/8.5/test/php.brat`). Put a test that
  applies to one version only in that version folder (Eg.
  `docker/8.5/test/mise.brat`). 8.4 and older symlink `nodesource.brat`.
- Brat sets `DIR` from the path it was given, without following symlinks, so
  each version folder also symlinks `helper.sh`. `helper.sh` sets
  `PHP_MAJOR_MINOR` from the folder name (`docker/8.5/test` gives `8.5`).
- Start containers with `in_image` from `test/helper.sh`. It runs as uid 1000,
  the way a devcontainer starts the image.
- Write one assertion per line, not loops. On a failure Brat prints the trace
  up to the failing line, so short lines show the problem at once.
- Do not put tool versions in tests (only the PHP major and minor), so a tool
  update only touches the Dockerfile.

```sh
@test "runs the PHP version of its folder" {
  [ "$(in_image php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')" = "$PHP_MAJOR_MINOR" ]
}
```

To update Brat, replace `vendor/brat` with the bundle of the new version from
`https://codeberg.org/api/packages/sstephenson/generic/brat/<version>/brat`.

## Git conventions

**Commits:** 50 char subject, capitalized, imperative mood, no period. Body at 72 chars explains what/why.

**Branches:** Use dashes: `feature-new-functionality` (not slashes)

**Worktrees:** Create in `.worktrees/` directory

## CI/CD

Pipeline detects changes in `docker/`, builds affected versions with matrix strategy,
supports amd64/arm64, pushes to GHCR on main. Manual dispatch available. A
change in the shared `test/` folder builds and tests every version.

`ci.yml` calls `image.yml` once per changed version. `image.yml` runs three
jobs for that version:

1. Build: Depot builds amd64 and arm64 in one go and saves the result in the
   Depot Registry. Nothing goes to GHCR yet.
2. Test: one job per CPU type on native runners (`ubuntu-24.04`,
   `ubuntu-24.04-arm`) pulls the saved image for its CPU type and runs the
   Brat tests. Versions without a `test/` folder skip this job.
3. Publish: on `main` only, `depot push` copies the same saved build to GHCR.
   It does not run when a test fails.

Each version has its own jobs, so a failing test in one version does not stop
another version from publishing.

## Contribution policy

Bug fixes only. Features require GitHub issue discussion first.
