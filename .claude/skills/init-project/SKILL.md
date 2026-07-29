---
name: init-project
description: Generate a complete pico-boot project using pico-initializer. Use when bootstrapping a new project with specific modules (fastapi, sqlalchemy, celery, pydantic, auth).
argument-hint: [project name] [modules...]
allowed-tools: Read Grep Glob Write Edit Bash
---

# Generate Pico Project

Generate a project using pico-initializer: $ARGUMENTS

Also available as a web app: https://dperezcabrera.github.io/pico-initializer/

## Steps

1. **Parse arguments** — extract project name and optional modules from `$ARGUMENTS`.
   - First word is the project name (e.g. `my-service`)
   - Remaining words are modules: `fastapi`, `sqlalchemy`, `celery`, `pydantic`, `auth`
   - If no modules specified, default to `fastapi`

2. **Locate pico-initializer** — find the CLI:
   ```bash
   git clone https://github.com/dperezcabrera/pico-initializer.git /tmp/pico-initializer
   INITIALIZER=/tmp/pico-initializer/cli.js
   ```

3. **Build config JSON** from the parsed arguments:
   ```json
   {
     "projectName": "<name>",
     "modules": ["fastapi", "sqlalchemy"],
     "includeTests": true,
     "includeDocker": false,
     "includeCompose": false,
     "includeAuthServer": false,
     "includeExample": false
   }
   ```

   Rules:
   - If `auth` is in modules, also set `includeCompose: true` and `includeAuthServer: true`
   - If user mentions "docker" or "compose", set `includeDocker: true` / `includeCompose: true`
   - If user mentions "example" or "crud", set `includeExample: true` (requires fastapi + sqlalchemy)

4. **Run the generator**:
   ```bash
   node "$INITIALIZER" '<config-json>'
   # Or with explicit output dir:
   node "$INITIALIZER" --output-dir ./my-project '<config-json>'
   ```

5. **Verify** the generated structure:
   ```bash
   python3 -m compileall -q <project-name>/
   ```

## Generated project structure

Base files (always generated):

```
<project-name>/
├── <package>/
│   ├── __init__.py
│   ├── config.py          # @configured AppSettings
│   ├── main.py            # pico_boot.init(modules=["<package>"])
│   └── services.py        # @component ExampleService
├── application.yaml       # Config for all plugins
├── pyproject.toml         # Dependencies and build config
├── requirements.txt
├── README.md
└── .gitignore
```

Conditional files by module:

| Module | Files added |
|--------|------------|
| `fastapi` | `<package>/controllers.py` — `@controller` with `@get` routes |
| `sqlalchemy` | `<package>/models.py` — `AppBase` entity, `<package>/repositories.py` — `@repository` with `@query` |
| `celery` | `<package>/tasks.py` — `@component` with `@task` methods |
| `pydantic` | `@validate` decorator added to `services.py` (no extra file) |
| `auth` | `<package>/secure_controller.py` — `@requires_role` + `@allow_anonymous` routes |

Optional extras:

| Option | Files added |
|--------|------------|
| `includeTests` | `tests/__init__.py`, `tests/conftest.py` with container + TestClient fixtures |
| `includeDocker` | `Dockerfile` |
| `includeCompose` | `docker-compose.yml` with app service |
| `includeAuthServer` | Adds pico-auth service to `docker-compose.yml` (port 8100, admin auto-created) |
| `includeExample` | `examples/products_api/` — full CRUD with models, schemas, repositories, services, controllers, database setup |

## How pico-boot wiring works

The generated `main.py` uses a single root module:

```python
container = init(modules=["myapp"], config=config)
```

This is all that's needed because:

- **Recursive scanning** — pico-ioc scans `myapp` and all submodules, discovering every `@component`, `@controller`, `@repository`, `@configured` class.
- **Plugin auto-discovery** — pico-boot loads all installed pico-* packages via `pico_boot.modules` entry points. No need to list them in `modules=[]`.

Do NOT add submodules or pico packages to the modules list — it's redundant and may cause duplicate registration.

## Available modules

| Module | Value | Package | Description |
|--------|-------|---------|-------------|
| FastAPI | `fastapi` | pico-fastapi | REST API with `@controller` and route decorators |
| SQLAlchemy | `sqlalchemy` | pico-sqlalchemy | Database ORM with `@repository` and `@query` |
| Celery | `celery` | pico-celery | Background tasks with `@task` |
| Pydantic | `pydantic` | pico-pydantic | Method-level validation with `@validate` |
| Auth | `auth` | pico-client-auth | JWT authentication with `@requires_role` |

## Config JSON reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `projectName` | string | **required** | Project and directory name |
| `packageName` | string | derived | Python package name (auto-derived from projectName) |
| `pythonVersion` | string | `"3.12"` | Python version for pyproject.toml |
| `modules` | string[] | `[]` | Modules to include (see table above) |
| `includeTests` | bool | `true` | Generate tests/ with conftest.py |
| `includeDocker` | bool | `false` | Generate Dockerfile |
| `includeCompose` | bool | `false` | Generate docker-compose.yml |
| `includeAuthServer` | bool | `false` | Add pico-auth service to compose |
| `includeExample` | bool | `false` | Add Products CRUD example (requires fastapi + sqlalchemy) |

## CLI usage

```bash
# Minimal FastAPI project
node cli.js '{"projectName":"my-api","modules":["fastapi"]}'

# Full stack with auth + compose + example
node cli.js '{"projectName":"my-app","modules":["fastapi","sqlalchemy","pydantic","auth"],"includeCompose":true,"includeAuthServer":true,"includeExample":true}'

# Output to specific directory
node cli.js --output-dir ./workspace '{"projectName":"my-app","modules":["fastapi"]}'

# List registered generator tools
node cli.js --list
```

## After generation

```bash
cd <project-name>
python -m venv .venv && source .venv/bin/activate
pip install -e .
# FastAPI projects:
uvicorn <package>.main:app --reload
# With compose + auth:
docker compose up
```
