---
name: release
description: Execute a pico-* package release. Use when creating version tags, updating changelogs, release notes, docs, and publishing.
argument-hint: [package-dir version]
allowed-tools: Read Grep Glob Write Edit Bash
---

# Release Checklist

Execute the following steps in order for releasing `$ARGUMENTS`.

## 0. Version Discovery

Before any changes, pull the latest state and determine the next version:

```bash
cd <package-dir>
git fetch --tags
git tag --sort=-v:refname | head -10   # list existing tags
```

- [ ] Pull repo: `git pull`
- [ ] Fetch tags: `git fetch --tags`
- [ ] List existing tags to identify the latest version
- [ ] Determine the next version based on semver (patch for fixes, minor for features, major for breaking changes)
- [ ] Confirm the chosen version does NOT already exist as a local or remote tag
- [ ] If the user provided a version in `$ARGUMENTS`, verify it doesn't conflict with existing tags

## 1. Pre-flight

- [ ] `cd <package-dir>`
- [ ] `.venv/bin/python -m pytest tests/ -v` — all tests pass
- [ ] `.venv/bin/coverage run -m pytest tests/ && .venv/bin/coverage report` — coverage >= 95%
- [ ] `ruff check src/ tests/` (or `ruff check <pkg>/ tests/`) — clean
- [ ] `ruff format --check src/ tests/` (or `ruff format --check <pkg>/ tests/`) — clean
- [ ] If `Makefile` exists: `make docker-e2e` — Docker E2E tests pass

## 2. CHANGELOG.md

- [ ] Add new version section at the top (Keep a Changelog format)
- [ ] Format: `## vX.Y.Z — Tagline (YYYY-MM-DD)`
- [ ] List changes under `### Added`, `### Changed`, `### Fixed`, `### Removed` as applicable

## 3. Release Notes

- [ ] Create `releases/vX.Y.Z.md` with:
  - Summary of what's new
  - Feature list with descriptions
  - Usage examples where appropriate
  - Dependencies and compatibility notes

## 4. Documentation

- [ ] Update relevant docs files for new features
- [ ] Ensure nav entries exist in `mkdocs.yml` for any new pages
- [ ] If CHANGELOG is new, add symlink `docs/CHANGELOG.md` -> `../CHANGELOG.md` and nav entry
- [ ] Run `mkdocs build --strict` — no warnings or errors

## 5. README.md

- [ ] Update feature lists, API tables, and examples for new functionality
- [ ] Ensure Quick Example reflects current public API

## 6. AGENTS.md

- [ ] Update file/module descriptions for new or changed files
- [ ] Update test count to match current suite
- [ ] Add descriptions for new concepts, models, or patterns

## 7. Commit

```bash
git add CHANGELOG.md releases/vX.Y.Z.md docs/ mkdocs.yml README.md AGENTS.md src/ tests/
git commit -m "chore(release): vX.Y.Z - tagline"
```

## 8. Tag

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z - tagline"
```

## 9. Push

```bash
git push && git push --tags
```

## 10. GitHub Release

```bash
gh release create vX.Y.Z --notes-file releases/vX.Y.Z.md --title "vX.Y.Z — Tagline"
```

## 11. Verify

- [ ] `gh run list --limit 5` — wait for CI, docs, publish workflows to pass
- [ ] `gh release view vX.Y.Z` — release exists with correct notes
