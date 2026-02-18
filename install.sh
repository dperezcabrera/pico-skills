#!/usr/bin/env bash
# Pico-Skills installer for Claude Code and OpenAI Codex
# Usage:
#   curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash
#   curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash -s -- sqlalchemy fastapi
#   curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash -s -- --override
#   curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash -s -- --codex
set -euo pipefail

REPO="dperezcabrera/pico-skills"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/.claude/skills"

# Target directories
CLAUDE_DIR=".claude/skills"
AGENTS_DIR=".agents/skills"

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
Pico-Skills installer for Claude Code and OpenAI Codex

Usage:
  install.sh [--override] [--claude|--codex] [packages...]

Options:
  --override    Overwrite existing skills without asking
  --claude      Install only for Claude Code (.claude/skills/)
  --codex       Install only for OpenAI Codex (.agents/skills/)
                Default: install for both platforms

Examples:
  install.sh                    # Install all skills (both platforms)
  install.sh all                # Install all skills (both platforms)
  install.sh --claude           # Install all skills (Claude Code only)
  install.sh --codex            # Install all skills (Codex only)
  install.sh sqlalchemy fastapi # Install sqlalchemy + fastapi skills (+ base)
  install.sh ioc                # Install only pico-ioc skills
  install.sh --override         # Install all, overwrite existing

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
    local target_dir="$2"
    local url="${BASE_URL}/${skill_name}/SKILL.md"

    if [ -f "${target_dir}/SKILL.md" ]; then
        printf "  %s (updated)\n" "$target_dir"
    else
        printf "  %s\n" "$target_dir"
    fi

    mkdir -p "$target_dir"
    if ! curl -sfL "$url" -o "${target_dir}/SKILL.md"; then
        printf "  ERROR: failed to download %s\n" "$skill_name" >&2
        rm -rf "$target_dir"
        return 1
    fi
}

main() {
    local override=false
    local install_claude=false
    local install_codex=false
    local packages=()

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --override) override=true ;;
            --claude)   install_claude=true ;;
            --codex)    install_codex=true ;;
            --help|-h)  usage; exit 0 ;;
            *)          packages+=("$arg") ;;
        esac
    done

    # Default: install both if neither flag specified
    if [ "$install_claude" = false ] && [ "$install_codex" = false ]; then
        install_claude=true
        install_codex=true
    fi

    # No args or "all" -> install everything
    if [ ${#packages[@]} -eq 0 ] || [ "${packages[0]}" = "all" ]; then
        packages=($ALL_PACKAGES)
    fi

    # Validate packages
    for pkg in "${packages[@]}"; do
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

    # Build list of target directories
    local targets=()
    if [ "$install_claude" = true ]; then
        targets+=("$CLAUDE_DIR")
    fi
    if [ "$install_codex" = true ]; then
        targets+=("$AGENTS_DIR")
    fi

    # Check for existing skills
    if [ "$override" = false ]; then
        local existing=()
        for skill in "${!skills_to_install[@]}"; do
            for target in "${targets[@]}"; do
                if [ -f "${target}/${skill}/SKILL.md" ]; then
                    existing+=("${target}/${skill}/SKILL.md")
                fi
            done
        done

        if [ ${#existing[@]} -gt 0 ]; then
            printf "The following skills already exist and would be overwritten:\n\n"
            for path in "${existing[@]}"; do
                printf "  %s\n" "$path"
            done
            printf "\nUse --override to overwrite, or proceed interactively.\n"
            printf "Overwrite? [y/N] "
            local answer
            if read -r answer < /dev/tty 2>/dev/null; then
                case "$answer" in
                    y|Y|yes|YES) ;;
                    *) printf "Aborted.\n"; exit 0 ;;
                esac
            else
                printf "\nCannot read from terminal. Use --override to force.\n" >&2
                exit 1
            fi
        fi
    fi

    # Describe what we're installing
    local total=${#skills_to_install[@]}
    local target_desc=""
    if [ "$install_claude" = true ] && [ "$install_codex" = true ]; then
        target_desc="${CLAUDE_DIR}/ + ${AGENTS_DIR}/"
    elif [ "$install_claude" = true ]; then
        target_desc="${CLAUDE_DIR}/"
    else
        target_desc="${AGENTS_DIR}/"
    fi
    printf "Installing %d pico-framework skills into %s\n\n" "$total" "$target_desc"

    local installed=0
    local failed=0
    for skill in "${!skills_to_install[@]}"; do
        for target in "${targets[@]}"; do
            if install_skill "$skill" "${target}/${skill}"; then
                installed=$((installed + 1))
            else
                failed=$((failed + 1))
            fi
        done
    done

    echo ""
    if [ "$failed" -eq 0 ]; then
        printf "Done. %d skills installed.\n" "$installed"
    else
        printf "Done. %d installed, %d failed.\n" "$installed" "$failed" >&2
        exit 1
    fi
}

main "$@"
