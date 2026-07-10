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
- [ ] Check `.gitignore` DOES block `releases/` — release notes are local-only;
  their content is used as the GitHub release body, never committed

## 1. Pre-flight

- [ ] `cd <package-dir>`
- [ ] **`flagship-validation/preflight.sh`** — MANDATORY gate (docs-qa a
      cero + flagship hermetico). Add `--level2` (real infra + celery worker
      + JWT over uvicorn) if the release touches DB/broker/cache/auth/actuator
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
- [ ] Format: `## [X.Y.Z] - YYYY-MM-DD`
- [ ] List changes under `### Added`, `### Changed`, `### Fixed`, `### Removed` as applicable

## 3. Release Notes

- [ ] Create `releases/vX.Y.Z.md` with:
  - Summary of what's new
  - Feature list with descriptions
  - Usage examples where appropriate
  - Dependencies and compatibility notes

## 4. Dependency Chain Check

- [ ] **PIN FLOOR vs IMPORTS (hard gate)**: every `from pico_x import SYMBOL`
      in `src/` must exist in the MINIMUM version declared in pyproject.
      Check against the floor tag, not against your venv:
      `git -C ../pico-x show v<FLOOR>:src/pico_x/__init__.py | grep <SYMBOL>`.
      (pico-resilience 0.2.0 shipped importing `ConfigChanged` — new in ioc
      2.3.0 — while declaring `>= 2.2.0`; hotfix 0.2.1 the same day.)
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
- [ ] `fleet-scripts/docs-qa.py <repo>` — zero findings (snippets compile,
      imported symbols exist, no emojis)
- [ ] New features are VISIBLE: README section + `pico-conventions` skill
      section updated (a released feature nobody can read about does not
      exist). llms.txt/llms-full.txt regenerate on deploy — nothing manual

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
git tag vX.Y.Z
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
- [ ] Wait for the `publish-to-pypi` workflow to succeed, then verify the
  artifact: `pip download <package>==X.Y.Z --no-deps -d /tmp/relcheck` — the
  wheel filename must carry the exact clean version (no `.postN`, no `.devN`)

## 13. Post-release Downstream Updates

- [ ] Bump the pin in `pico-initializer/js/versions.js`
- [ ] New module? Register: conventions skill section, pico-skills README
      table, initializer (tool/registry/index.html), AGENTS.md catalog in
      pico-ioc, GitHub topics (`pico-framework` + funcionales + `llms-txt`)


- [ ] For each downstream pico-* package that depends on this one:
  - Update `pyproject.toml` dependency to `>=NEW_VERSION`
  - Commit: `chore: bump PACKAGE>=NEW_VERSION`
  - Push
- [ ] Update pico-initializer (single source of truth for generated projects):
  - Bump the constraint for this package in `pico-initializer/js/versions.js`
    (`~=NEW_VERSION` for 0.x packages; keep the `<NEXT_MAJOR` cap for 1.x+)
  - Mirror the same constraint in `pico-initializer/test/Dockerfile` and
    `pico-initializer/test/Dockerfile.integration` (pre-installed deps)
  - Commit: `chore: bump PACKAGE to NEW_VERSION in generated projects`
  - Push (CI runs the integration suite against the new release before deploying)

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
