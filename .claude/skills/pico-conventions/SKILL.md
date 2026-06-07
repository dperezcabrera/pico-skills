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
| `request` | One instance per request context (activated by pico-fastapi middleware) |
| `session` | One instance per session context |
| `websocket` | One instance per websocket connection |
| `transaction` | One instance per DB transaction — Unit-of-Work / identity-map. With **pico-sqlalchemy**, `TransactionalInterceptor` activates it on each new transaction (`REQUIRES_NEW`, or `REQUIRED` with no enclosing tx) and releases it (running `@cleanup`) on commit/rollback. Resolving one outside a transaction raises `ScopeError` |

Short-lived scopes: use `with container.scope("request", id, cleanup=True):` so per-scope instances are evicted (and their `@cleanup` hooks run) on exit.

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

## pico-client-auth

```python
from pico_client_auth import (
    # Decorators
    allow_anonymous,            # @allow_anonymous — skip auth for endpoint
    requires_role,              # @requires_role("admin", "editor") — require any of these roles
    requires_group,             # @requires_group("group-id") — require group membership

    # Context
    SecurityContext,            # Static accessor for current request's auth state
    TokenClaims,                # Frozen dataclass: sub, email, role, org_id, jti, groups

    # Extension
    RoleResolver,               # Protocol for custom role extraction
    AuthClientSettings,         # @configured settings (prefix="auth_client")

    # Errors
    AuthClientError,            # Base exception
    MissingTokenError,          # 401 — no Bearer token
    TokenExpiredError,          # 401 — expired JWT
    TokenInvalidError,          # 401 — bad signature, wrong issuer/audience
    InsufficientPermissionsError,  # 403 — missing required role/group
    AuthConfigurationError,     # Startup — missing issuer/audience
)
```

Auth is enabled by default on all routes. Use `@allow_anonymous` to opt out.

`SecurityContext` static methods:

| Method | Returns | Description |
|--------|---------|-------------|
| `get()` | `TokenClaims \| None` | Current claims, or None if unauthenticated |
| `require()` | `TokenClaims` | Current claims, raises `MissingTokenError` if absent |
| `get_roles()` | `list[str]` | Resolved roles for current request |
| `has_role(role)` | `bool` | Check if user has a role |
| `require_role(*roles)` | `None` | Assert at least one role, raises 403 |
| `get_groups()` | `tuple[str, ...]` | Group IDs from token |
| `has_group(group_id)` | `bool` | Check group membership |
| `require_group(*group_ids)` | `None` | Assert at least one group, raises 403 |

`AuthClientSettings` fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | `bool` | `True` | Enable/disable auth middleware |
| `issuer` | `str` | `""` | Expected JWT issuer |
| `audience` | `str` | `""` | Expected JWT audience |
| `jwks_ttl_seconds` | `int` | `300` | JWKS cache TTL |
| `jwks_endpoint` | `str` | `""` | Custom JWKS URL (defaults to `{issuer}/api/v1/auth/jwks`) |
| `accepted_algorithms` | `tuple[str, ...]` | `("RS256",)` | Accepted JWT algorithms (`RS256`, `ML-DSA-65`, `ML-DSA-87`) |

Post-quantum ML-DSA support (optional `pqc` extra, requires `liboqs-python`):
- `ML-DSA-65` (NIST Level 3) and `ML-DSA-87` (NIST Level 5)
- Add to `accepted_algorithms` to enable; RS256 tokens continue to work alongside
- JWK key type: `AKP` with `pub` field (base64url raw public key bytes)
- Install: `pip install pico-client-auth[pqc]`

Custom role resolver (overrides default automatically via `on_missing_selector`):

```python
@component
class MyRoleResolver:
    async def resolve(self, claims: TokenClaims, raw_claims: dict) -> list[str]:
        return raw_claims.get("roles", [])
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
