---
name: pico-init
description: Scaffolds a new pico-framework application with pico-boot
argument-hint: [project name]
---

# Pico-Boot Application Scaffold

Scaffold a new application: $ARGUMENTS

## Rules

- Use `pico_boot.init()` as the entry point (wraps `pico_ioc.init()` with auto-discovery)
- Organize code in modules that pico-boot scans for components
- Use `@configured` dataclasses for settings
- Configuration via YAML + environment variables
- All pico-* plugins installed are auto-discovered via entry points

## Project Structure

```
$ARGUMENTS/
    __init__.py
    main.py
    config.py
    services/
        __init__.py
        ...
    repositories/
        __init__.py
        ...
    api/
        __init__.py
        controllers.py
    tests/
        __init__.py
        conftest.py
        ...
application.yaml
pyproject.toml
```

## main.py

```python
import asyncio
from pico_ioc import configuration, YamlTreeSource, EnvSource
from pico_boot import init

async def main():
    config = configuration(
        YamlTreeSource("application.yaml"),
        EnvSource(),
    )

    container = init(
        modules=["$ARGUMENTS"],
        config=config,
    )

    # Application is ready - all components registered and validated
    # Start your server, worker, etc.

if __name__ == "__main__":
    asyncio.run(main())
```

## config.py

```python
from dataclasses import dataclass, field
from pico_ioc import configured

@configured(prefix="app")
@dataclass
class AppSettings:
    name: str = "$ARGUMENTS"
    debug: bool = False

@configured(prefix="database")
@dataclass
class DatabaseSettings:
    url: str = "sqlite+aiosqlite:///./app.db"
    echo: bool = False
    pool_size: int = 5
```

## application.yaml

```yaml
app:
  name: $ARGUMENTS
  debug: false

database:
  url: "sqlite+aiosqlite:///./app.db"
  echo: false
  pool_size: 5

fastapi:
  title: "$ARGUMENTS API"
  version: "1.0.0"
  debug: false
```

## pyproject.toml (dependencies)

```toml
[project]
name = "$ARGUMENTS"
requires-python = ">=3.11"
dependencies = [
    "pico-ioc>=2.2.0",
    "pico-boot>=0.1.0",
    # Add as needed:
    # "pico-fastapi>=0.1.0",
    # "pico-sqlalchemy>=0.1.0",
    # "pico-celery>=0.1.0",
    # "pico-pydantic>=0.1.0",
    # "pico-agent>=0.1.0",
]
```

## Environment Variables

pico-boot respects:
- `PICO_BOOT_AUTO_PLUGINS=false` to disable auto-discovery of installed pico-* plugins

## Checklist

- [ ] Project structure with clear module separation
- [ ] `application.yaml` with all settings
- [ ] `@configured` dataclasses for typed settings
- [ ] `main.py` with `pico_boot.init()`
- [ ] Modules listed in `init(modules=[...])`
- [ ] Tests directory with `conftest.py`
