# Pico-Skills

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills for the [pico-framework](https://github.com/dperezcabrera) ecosystem.

These skills provide AI-assisted code generation following pico-framework patterns and best practices.

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **Component** | `/pico-component` | Create pico-ioc components with DI, scopes, factories, interceptors |
| **Repository** | `/pico-repository` | Create SQLAlchemy entities and repositories with pico-sqlalchemy |
| **Controller** | `/pico-controller` | Create FastAPI controllers with pico-fastapi |
| **Task** | `/pico-task` | Create Celery tasks with pico-celery |
| **Validate** | `/pico-validate` | Add Pydantic validation with pico-pydantic |
| **Agent** | `/pico-agent` | Create LLM agents and tools with pico-agent |
| **Init** | `/pico-init` | Scaffold a new pico-boot application |
| **Tests** | `/pico-tests` | Generate tests for any pico-framework component |

## Installation

### Project-level (recommended)

Copy the skills into your project so all contributors benefit:

```bash
# From your project root
cp -r path/to/pico-skills/.claude .claude
```

### User-level

Install for all your projects:

```bash
cp -r path/to/pico-skills/.claude/skills/* ~/.claude/skills/
```

### Cherry-pick

Copy only the skills you need:

```bash
# Example: only pico-ioc and pico-sqlalchemy skills
mkdir -p .claude/skills
cp path/to/pico-skills/.claude/skills/pico-component.md .claude/skills/
cp path/to/pico-skills/.claude/skills/pico-repository.md .claude/skills/
```

## Usage

In Claude Code, invoke any skill with its slash command:

```
/pico-component UserService
/pico-repository Product
/pico-controller /api/orders
/pico-task send_notification
/pico-validate UserService
/pico-agent support_bot
/pico-init my-app
/pico-tests UserService
```

## Pico-Framework Packages

| Package | PyPI | Description |
|---------|------|-------------|
| [pico-ioc](https://github.com/dperezcabrera/pico-ioc) | [![PyPI](https://img.shields.io/pypi/v/pico-ioc)](https://pypi.org/project/pico-ioc/) | IoC container (foundation) |
| [pico-boot](https://github.com/dperezcabrera/pico-boot) | [![PyPI](https://img.shields.io/pypi/v/pico-boot)](https://pypi.org/project/pico-boot/) | Orchestration & plugin discovery |
| [pico-fastapi](https://github.com/dperezcabrera/pico-fastapi) | [![PyPI](https://img.shields.io/pypi/v/pico-fastapi)](https://pypi.org/project/pico-fastapi/) | FastAPI integration |
| [pico-sqlalchemy](https://github.com/dperezcabrera/pico-sqlalchemy) | [![PyPI](https://img.shields.io/pypi/v/pico-sqlalchemy)](https://pypi.org/project/pico-sqlalchemy/) | SQLAlchemy + transactions |
| [pico-celery](https://github.com/dperezcabrera/pico-celery) | [![PyPI](https://img.shields.io/pypi/v/pico-celery)](https://pypi.org/project/pico-celery/) | Celery task integration |
| [pico-pydantic](https://github.com/dperezcabrera/pico-pydantic) | [![PyPI](https://img.shields.io/pypi/v/pico-pydantic)](https://pypi.org/project/pico-pydantic/) | Pydantic validation AOP |
| [pico-agent](https://github.com/dperezcabrera/pico-agent) | [![PyPI](https://img.shields.io/pypi/v/pico-agent)](https://pypi.org/project/pico-agent/) | LLM agent framework |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Python >= 3.11
- Relevant pico-framework packages installed in your project

## License

MIT License - see [LICENSE](LICENSE).
