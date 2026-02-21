---
name: release
description: Execute a pico-* package release. Use when creating version tags, updating changelogs, release notes, docs, and publishing.
argument-hint: [package-dir version]
allowed-tools: Read Grep Glob Write Edit Bash
---

# Release Checklist

Execute the following steps in order for releasing `$ARGUMENTS`.

## 0. Environment & Remote Validation

Before making any changes, verify the environment is ready and determine the correct version.

```bash
cd <package-dir>
git pull --rebase
git fetch --tags
git tag --sort=-v:refname | head -10
```

- [ ] `git pull --rebase` — sync with remote
- [ ] `git fetch --tags` — pull all remote tags
- [ ] List existing tags to identify the latest version
- [ ] Determine the next version based on semver:
  - **patch** (X.Y.Z+1): bug fixes only
  - **minor** (X.Y+1.0): new features, backward-compatible
  - **major** (X+1.0.0): breaking changes
- [ ] Confirm the chosen version does NOT exist as a local or remote tag:
  ```bash
  git tag -l "vX.Y.Z"                      # local
  git ls-remote --tags origin "vX.Y.Z"     # remote
  ```
- [ ] If the user provided a version in `$ARGUMENTS`, verify it doesn't conflict
- [ ] Verify `gh auth status` works — if 401, try `unset GITHUB_TOKEN` and retry
- [ ] Locate tools — check `.venv/bin/` first, then system PATH:
  ```bash
  command -v ruff || .venv/bin/ruff --version
  command -v mkdocs || .venv/bin/mkdocs --version
  ```
- [ ] Check `.gitignore` does NOT block `releases/` — if it does, remove the entry now

## 1. Pre-flight

- [ ] `cd <package-dir>`
- [ ] `.venv/bin/python -m pytest tests/ -v` — all tests pass
- [ ] `.venv/bin/coverage run -m pytest tests/ && .venv/bin/coverage report` — coverage >= 95%
- [ ] `ruff check src/ tests/` (or `ruff check <pkg>/ tests/`) — clean
- [ ] `ruff format --check src/ tests/` (or `ruff format --check <pkg>/ tests/`) — clean
- [ ] If `Makefile` exists: `make docker-e2e` — Docker E2E tests pass

## 2. CHANGELOG.md

- [ ] If CHANGELOG.md is **new**:
  - Create the file with header and format preamble
  - Create symlink: `ln -sf ../CHANGELOG.md docs/CHANGELOG.md`
  - Add nav entry to `mkdocs.yml`: `- Changelog: CHANGELOG.md`
- [ ] Add new version section at the top (Keep a Changelog format)
- [ ] Format: `## vX.Y.Z — Tagline (YYYY-MM-DD)`
- [ ] List changes under `### Added`, `### Changed`, `### Fixed`, `### Removed` as applicable

## 3. Release Notes

- [ ] Create `releases/vX.Y.Z.md` with:
  - Summary of what's new
  - Feature list with descriptions
  - Usage examples where appropriate
  - Dependencies and compatibility notes

## 4. Dependency Chain Check

- [ ] If this package is a **dependency** of other pico-* packages:
  - Identify which downstream `pyproject.toml` files reference this package
  - Note they will need `>=NEW_VERSION` after this release
- [ ] If this package **depends** on a pico-* package being released in the same session:
  - Verify that upstream dependency was already released and tagged
  - Update `pyproject.toml` to `>=UPSTREAM_VERSION` before continuing

## 5. Documentation

- [ ] Update relevant docs files for new features
- [ ] Ensure nav entries exist in `mkdocs.yml` for any new pages
- [ ] Run `mkdocs build --strict` — no warnings or errors

## 6. README.md

- [ ] Update feature lists, API tables, and examples for new functionality
- [ ] Ensure Quick Example reflects current public API

## 7. AGENTS.md

- [ ] Update file/module descriptions for new or changed files
- [ ] Update test count to match current suite
- [ ] Add descriptions for new concepts, models, or patterns

## 8. Commit

- [ ] Stage files explicitly (never `git add -A`):
  ```bash
  git add CHANGELOG.md releases/vX.Y.Z.md docs/ mkdocs.yml README.md AGENTS.md \
          src/ tests/ .gitignore pyproject.toml
  ```
- [ ] Review staged changes: `git diff --cached --stat`
- [ ] Check for untracked release-related files: `git status --short`
- [ ] Commit:
  ```bash
  git commit -m "chore(release): vX.Y.Z - tagline"
  ```

## 9. Tag

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z - tagline"
```

## 10. Push

```bash
git push && git push --tags
```

## 11. GitHub Release

```bash
gh release create vX.Y.Z --notes-file releases/vX.Y.Z.md --title "vX.Y.Z — Tagline"
```

If `gh release create` fails with 401/403:
- Try: `unset GITHUB_TOKEN && gh release create ...`
- If still failing, print manual URL for the user:
  ```
  https://github.com/OWNER/REPO/releases/new?tag=vX.Y.Z
  ```

## 12. Verify

- [ ] `gh run list --limit 5` — wait for CI, docs, publish workflows to pass
- [ ] `gh release view vX.Y.Z` — release exists with correct notes

## 13. Post-release Downstream Updates

- [ ] For each downstream pico-* package that depends on this one:
  - Update `pyproject.toml` dependency to `>=NEW_VERSION`
  - Commit: `chore: bump PACKAGE>=NEW_VERSION`
  - Push

## Rollback (if needed)

If something goes wrong after push, follow these steps to undo:

```bash
# Delete remote tag
git push origin :refs/tags/vX.Y.Z

# Delete local tag
git tag -d vX.Y.Z

# Delete GitHub release (if created)
gh release delete vX.Y.Z --yes

# Revert the commit (safe — don't use reset --hard)
git revert HEAD
git push
```
