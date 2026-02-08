#!/usr/bin/env bash
# Pico-Skills installer for Claude Code
# Usage:
#   curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash
#   curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash -s -- sqlalchemy fastapi
#   curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash -s -- all
set -euo pipefail

REPO="dperezcabrera/pico-skills"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/.claude/skills"

# Base skills (always installed)
BASE_SKILLS="pico-conventions add-component add-tests"

# Package-to-skill mapping
declare -A SKILL_MAP=(
    [ioc]="add-component"
    [boot]="add-app"
    [fastapi]="add-controller"
    [sqlalchemy]="add-repository"
    [celery]="add-celery-task"
    [pydantic]="add-validation"
    [agent]="add-agent"
)

ALL_PACKAGES="ioc boot fastapi sqlalchemy celery pydantic agent"

usage() {
    cat <<'USAGE'
Pico-Skills installer for Claude Code

Usage:
  install.sh [packages...]

Examples:
  install.sh                    # Install all skills
  install.sh all                # Install all skills
  install.sh sqlalchemy fastapi # Install sqlalchemy + fastapi skills (+ base)
  install.sh ioc                # Install only pico-ioc skills

Available packages:
  ioc         add-component (included by default)
  boot        add-app
  fastapi     add-controller
  sqlalchemy  add-repository
  celery      add-celery-task
  pydantic    add-validation
  agent       add-agent

Base skills (always installed):
  pico-conventions, add-component, add-tests
USAGE
}

install_skill() {
    local skill_name="$1"
    local target_dir=".claude/skills/${skill_name}"
    local url="${BASE_URL}/${skill_name}/SKILL.md"

    if [ -f "${target_dir}/SKILL.md" ]; then
        printf "  %s (updated)\n" "$skill_name"
    else
        printf "  %s\n" "$skill_name"
    fi

    mkdir -p "$target_dir"
    if ! curl -sfL "$url" -o "${target_dir}/SKILL.md"; then
        printf "  ERROR: failed to download %s\n" "$skill_name" >&2
        rm -rf "$target_dir"
        return 1
    fi
}

main() {
    local packages=("$@")

    # No args or "all" -> install everything
    if [ ${#packages[@]} -eq 0 ] || [ "${packages[0]}" = "all" ]; then
        packages=($ALL_PACKAGES)
    fi

    # Validate packages
    for pkg in "${packages[@]}"; do
        if [ "$pkg" = "--help" ] || [ "$pkg" = "-h" ]; then
            usage
            exit 0
        fi
        if [ -z "${SKILL_MAP[$pkg]+x}" ]; then
            printf "Unknown package: %s\n\n" "$pkg" >&2
            usage >&2
            exit 1
        fi
    done

    # Collect unique skills to install
    local -A skills_to_install
    for skill in $BASE_SKILLS; do
        skills_to_install[$skill]=1
    done
    for pkg in "${packages[@]}"; do
        skills_to_install[${SKILL_MAP[$pkg]}]=1
    done

    local total=${#skills_to_install[@]}
    printf "Installing %d pico-framework skills into .claude/skills/\n\n" "$total"

    local installed=0
    local failed=0
    for skill in "${!skills_to_install[@]}"; do
        if install_skill "$skill"; then
            installed=$((installed + 1))
        else
            failed=$((failed + 1))
        fi
    done

    echo ""
    if [ "$failed" -eq 0 ]; then
        printf "Done. %d skills installed in .claude/skills/\n" "$installed"
    else
        printf "Done. %d installed, %d failed.\n" "$installed" "$failed" >&2
        exit 1
    fi
}

main "$@"
