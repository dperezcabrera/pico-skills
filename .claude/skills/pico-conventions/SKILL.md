---
name: pico-conventions
description: Pico-framework conventions, patterns and API reference. Use when writing code that uses pico-ioc, pico-boot, pico-fastapi, pico-sqlalchemy, pico-celery, pico-pydantic, or pico-agent.
user-invocable: false
---

# Pico-Framework Conventions

## General Rules

- Python >= 3.11 required
- All pico-ioc imports: `from pico_ioc import ...`
- All satellite packages import from their own namespace: `from pico_sqlalchemy import ...`
- Use type hints for automatic dependency injection — constructor parameters are resolved by type
- Async-first: prefer `async def` methods

## pico-ioc Core API

```python
from pico_ioc import (
    # Registration
    component,          # @component or @component(scope="singleton")
    factory,            # @factory on class containing @provides methods
    provides,           # @provides(Type, scope="singleton") on factory methods
    configured,         # @configured(prefix="key") on @dataclass for settings
    Qualifier,          # Annotated[Type, Qualifier("name")] for disambiguation

    # Container
    init,               # init(modules=[...], config=...) -> PicoContainer
    cleanup,            # cleanup() — shutdown all scopes
    PicoContainer,      # Container type

    # Configuration
    configuration,      # configuration(Source1(), Source2()) -> ContextConfig
    ContextConfig,      # Unified config object
    YamlTreeSource,     # YAML file source
    JsonTreeSource,     # JSON file source
    EnvSource,          # Environment variables
    FileSource,         # .properties / .ini files
    FlatDictSource,     # Dict source
    Value,              # @Value("key") for injecting config values

    # AOP
    MethodInterceptor,  # Base class for interceptors
    MethodCtx,          # Context passed to interceptor.invoke()
    intercepted_by,     # @intercepted_by(InterceptorClass) on methods
    health,             # @health on methods for health checks

    # Events
    EventBus,           # Event bus
    Event,              # Base event class
    subscribe,          # @subscribe(EventType) on handler methods

    # Scopes
    ScopeManager,       # Manage custom scopes
    ContextVarScope,    # ContextVar-based scope implementation
)
```

## Scopes

| Scope | Behavior |
|-------|----------|
| `singleton` | One instance per container (default for services) |
| `prototype` | New instance on every resolution |
| `request` | One instance per request context |
| `transaction` | One instance per transaction context |

## pico-boot

```python
from pico_boot import init  # Wraps pico_ioc.init() with auto-discovery

container = init(modules=["my_app"], config=config)
# All installed pico-* plugins are auto-discovered via entry points
```

Disable auto-discovery: `PICO_BOOT_AUTO_PLUGINS=false`

## pico-fastapi

```python
from pico_fastapi import (
    controller,         # @controller(prefix="/path", tags=["tag"])
    get, post, put, delete, patch, websocket,  # Route decorators
    FastApiSettings,    # @configured settings
    FastApiConfigurer,  # Protocol for app customization
)
```

`@controller` automatically applies `@component(scope="request")`.

## pico-sqlalchemy

```python
from pico_sqlalchemy import (
    repository,         # @repository or @repository(entity=Model)
    query,              # @query(expr="field = :param") or @query(sql="...")
    transactional,      # @transactional(propagation="REQUIRED", read_only=False)
    SessionManager,     # Injected dependency for session access
    get_session,        # get_session(manager) -> AsyncSession
    AppBase,            # SQLAlchemy DeclarativeBase
    Mapped, mapped_column,  # Re-exported from SQLAlchemy
    Page, PageRequest, Sort,  # Pagination types
)
```

Transaction propagation: `REQUIRED`, `REQUIRES_NEW`, `SUPPORTS`, `MANDATORY`, `NOT_SUPPORTED`, `NEVER`

## pico-celery

```python
from pico_celery import (
    task,               # @task("task.name") on async worker methods
    send_task,          # @send_task("task.name") on client methods
    celery,             # @celery on client classes
    CeleryClient,       # Protocol for client classes
    CelerySettings,     # @configured settings
)
```

## pico-pydantic

```python
from pico_pydantic import (
    validate,               # @validate on methods with BaseModel params
    ValidationFailedError,  # Raised when validation fails
)
```

## pico-agent

```python
from pico_agent import (
    agent,              # @agent(name="...", capability=..., agent_type=...)
    tool,               # @tool(name="...", description="...")
    AgentType,          # ONE_SHOT, REACT, WORKFLOW
    AgentCapability,    # FAST, SMART, REASONING, VISION, CODING
)
```
