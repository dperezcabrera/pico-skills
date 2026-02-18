---
name: add-app
description: Scaffold a new pico-framework application with pico-boot. Use when starting a new project or setting up the application skeleton.
argument-hint: [project name]
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Edit Bash
---

# Scaffold Pico Application

Create a new application: $ARGUMENTS

## Project Structure

```
$ARGUMENTS/
    __init__.py
    main.py
    config.py
    services/
        __init__.py
    repositories/
        __init__.py
    api/
        __init__.py
        controllers.py
    tests/
        __init__.py
        conftest.py
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
    container = init(modules=["$ARGUMENTS"], config=config)

if __name__ == "__main__":
    asyncio.run(main())
```

## config.py

```python
from dataclasses import dataclass
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

fastapi:
  title: "$ARGUMENTS API"
  version: "1.0.0"
```

## pyproject.toml

```toml
[project]
name = "$ARGUMENTS"
requires-python = ">=3.11"
dependencies = [
    "pico-ioc>=2.2.0",
    "pico-boot>=0.1.0",
    # "pico-fastapi>=0.1.0",
    # "pico-sqlalchemy>=0.1.0",
    # "pico-celery>=0.1.0",
    # "pico-pydantic>=0.1.0",
    # "pico-agent>=0.1.0",
]
```

## Checklist

- [ ] Project structure with module separation
- [ ] `application.yaml` with settings
- [ ] `@configured` dataclasses for typed settings
- [ ] `main.py` with `pico_boot.init()`
- [ ] `pyproject.toml` with dependencies
- [ ] Tests directory with `conftest.py`
