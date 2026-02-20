# Pico-Skills

[Claude Code](https://code.claude.com) and [OpenAI Codex](https://openai.com/index/introducing-codex/) skills for the [pico-boot](https://github.com/dperezcabrera/pico-boot) ecosystem.

AI-assisted code generation following pico framework patterns and best practices.

## Platform Compatibility

Pico-Skills follows the [Agent Skills](https://agent-skills.org) standard and supports multiple AI coding agents:

| Platform | Skills directory | Status |
|----------|-----------------|--------|
| [Claude Code](https://code.claude.com) | `.claude/skills/` | Canonical source |
| [OpenAI Codex](https://openai.com/index/introducing-codex/) | `.agents/skills/` | Symlinks to `.claude/skills/` |

The `.agents/skills/` directory contains symlinks to the canonical `.claude/skills/` files, so both platforms always use the same skill definitions.

## Available Skills

### User-invocable (slash commands)

| Command | Package | Description |
|---------|---------|-------------|
| `/add-component` | pico-ioc | Add components, factories, interceptors, event subscribers, settings |
| `/add-repository` | pico-sqlalchemy | Add SQLAlchemy entities and repositories with transactions |
| `/add-controller` | pico-fastapi | Add FastAPI controllers with route decorators |
| `/add-celery-task` | pico-celery | Add Celery worker tasks and client senders |
| `/add-validation` | pico-pydantic | Add Pydantic validation to component methods |
| `/add-agent` | pico-agent | Add LLM agents and tools |
| `/add-auth` | pico-client-auth | Add JWT authentication, role-based access control, custom role resolvers |
| `/add-app` | pico-boot | Scaffold a new pico-boot application |
| `/add-tests` | all | Generate tests for any pico component |

### Auto-loaded by Claude (background knowledge)

| Skill | Description |
|-------|-------------|
| `pico-conventions` | API reference and patterns for all pico-* packages. Loaded automatically when Claude detects pico framework usage. |

## Installation

### All skills (recommended)

```bash
curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash
```

By default, skills are installed for both Claude Code (`.claude/skills/`) and OpenAI Codex (`.agents/skills/`).

### Platform-specific installation

```bash
# Claude Code only
curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash -s -- --claude

# OpenAI Codex only
curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash -s -- --codex
```

### Only the packages you use

```bash
curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash -s -- sqlalchemy fastapi
```

Base skills (`pico-conventions`, `add-component`, `add-tests`) are always included.

### Available packages

| Package | Skill installed |
|---------|-----------------|
| `ioc` | `add-component` (included by default) |
| `boot` | `add-app` |
| `fastapi` | `add-controller` |
| `sqlalchemy` | `add-repository` |
| `celery` | `add-celery-task` |
| `pydantic` | `add-validation` |
| `agent` | `add-agent` |
| `auth` | `add-auth` |

### User-level (all projects)

```bash
cd ~ && curl -sL https://raw.githubusercontent.com/dperezcabrera/pico-skills/main/install.sh | bash
```

## Usage

```
/add-component UserService
/add-repository Product
/add-controller /api/orders
/add-celery-task send_notification
/add-validation UserService
/add-agent support_bot
/add-auth DatabaseRoleResolver
/add-app my-app
/add-tests UserService
```

## Skill Structure

Each skill follows the [Agent Skills](https://agent-skills.org) standard:

```
pico-skills/
├── .claude/skills/                # Canonical source (Claude Code)
│   ├── add-component/SKILL.md
│   ├── add-repository/SKILL.md
│   ├── add-controller/SKILL.md
│   ├── add-celery-task/SKILL.md
│   ├── add-validation/SKILL.md
│   ├── add-agent/SKILL.md
│   ├── add-auth/SKILL.md
│   ├── add-app/SKILL.md
│   ├── add-tests/SKILL.md
│   └── pico-conventions/SKILL.md
├── .agents/skills/                # Symlinks for Codex
│   ├── add-component/SKILL.md → ../../.claude/skills/add-component/SKILL.md
│   ├── add-auth/SKILL.md → ../../.claude/skills/add-auth/SKILL.md
│   ├── add-repository/SKILL.md → ...
│   └── ...
├── install.sh
└── README.md
```

## Pico Ecosystem Packages

| Package | PyPI | Description |
|---------|------|-------------|
| [pico-ioc](https://github.com/dperezcabrera/pico-ioc) | [![PyPI](https://img.shields.io/pypi/v/pico-ioc)](https://pypi.org/project/pico-ioc/) | IoC container (foundation) |
| [pico-boot](https://github.com/dperezcabrera/pico-boot) | [![PyPI](https://img.shields.io/pypi/v/pico-boot)](https://pypi.org/project/pico-boot/) | Orchestration & plugin discovery |
| [pico-fastapi](https://github.com/dperezcabrera/pico-fastapi) | [![PyPI](https://img.shields.io/pypi/v/pico-fastapi)](https://pypi.org/project/pico-fastapi/) | FastAPI integration |
| [pico-sqlalchemy](https://github.com/dperezcabrera/pico-sqlalchemy) | [![PyPI](https://img.shields.io/pypi/v/pico-sqlalchemy)](https://pypi.org/project/pico-sqlalchemy/) | SQLAlchemy + transactions |
| [pico-celery](https://github.com/dperezcabrera/pico-celery) | [![PyPI](https://img.shields.io/pypi/v/pico-celery)](https://pypi.org/project/pico-celery/) | Celery task integration |
| [pico-pydantic](https://github.com/dperezcabrera/pico-pydantic) | [![PyPI](https://img.shields.io/pypi/v/pico-pydantic)](https://pypi.org/project/pico-pydantic/) | Pydantic validation AOP |
| [pico-client-auth](https://github.com/dperezcabrera/pico-client-auth) | [![PyPI](https://img.shields.io/pypi/v/pico-client-auth)](https://pypi.org/project/pico-client-auth/) | JWT authentication client |
| [pico-agent](https://github.com/dperezcabrera/pico-agent) | [![PyPI](https://img.shields.io/pypi/v/pico-agent)](https://pypi.org/project/pico-agent/) | LLM agent framework |

## Requirements

- [Claude Code](https://code.claude.com) CLI or [OpenAI Codex](https://openai.com/index/introducing-codex/)
- Python >= 3.11
- Relevant pico packages installed in your project

## License

MIT License - see [LICENSE](LICENSE).
