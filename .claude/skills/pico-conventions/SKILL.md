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
    ConfigChanged,      # Event published by container.refresh_config() (pico-ioc >= 2.3.0)

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

## pico-server-auth

Embeddable auth server, auto-discovered by pico-boot. Exposes
`POST /auth/challenge`, `POST /auth/wallet` (wallet login: ML-DSA-65, Ed25519,
secp256k1), `POST /auth/login` (password), `GET /auth/jwks`. Configure under
the `server_auth:` prefix (`issuer`, `audience`, `auto_create_admin`,
`challenge_ttl_seconds`, `supported_wallet_algorithms`). Pair with
pico-client-auth: `auth_client.issuer` must match `server_auth.issuer`.

## pico-actuator

Spring Boot-style actuator, auto-discovered by pico-boot — zero config needed.
Endpoints: `/actuator/health`, `/health/live`, `/health/ready`, `/info`,
`/metrics` (extra `pico-actuator[metrics]`).

```python
from pico_ioc import component
from pico_actuator import HealthIndicator, InfoContributor  # protocols

@component
class DbHealth:  # satisfies HealthIndicator — no registration needed
    name = "db"

    def check(self):  # sync or async; return dict or truthy
        return {"status": "UP"}
```

`POST /actuator/refresh` re-reads tree config sources and publishes
`ConfigChanged` (Spring Cloud style); subscribed components re-read their
config — pico-resilience toggles its policies live through it.

Settings under the `actuator:` prefix: `enabled`, `show_components`,
`check_timeout_seconds` (per-indicator budget, default 5s), `info` (static map).
Indicators run concurrently; a raising/hanging indicator reports `DOWN` in
isolation (endpoint answers `503`, never 500s). Liveness is dependency-free by
design — wire `/health/live` to `livenessProbe` and `/health/ready` to
`readinessProbe`.

## pico-scheduling

`@scheduled` methods on components, auto-discovered by pico-boot. Exactly one
of `every=` (seconds) or `cron=` (5-field crontab). Sync or async. Jobs start
with the container and stop with it; a raising job logs and keeps its schedule.

```python
from pico_ioc import component
from pico_scheduling import scheduled

@component
class Reports:
    @scheduled(every=300)
    def refresh_cache(self): ...

    @scheduled(cron="0 3 * * *")
    async def nightly_rollup(self): ...
```

Settings under `scheduling:`: `enabled` (kill-switch for tests/scripts).

Note on pico-resilience (>= 0.2.0): `resilience.enabled` hot-reloads via
`ConfigChanged`; requires an EventBus (`pico_ioc.event_bus`) or startup
fails fast — opt out with `resilience.hot_reload: false`. pico-ioc >= 2.3.0.
pico-sqlalchemy (>= 0.5.0): `database.migrations_path` runs Alembic
`upgrade head` on startup (extra `[migrations]`).

## pico-httpx

Declarative HTTP clients: the class is the interface, the implementation is
generated. Path `{placeholders}` bind to parameters, `json` is the body,
other params become query params (`None` dropped). Return annotation
`httpx.Response` = raw; anything else = `response.json()`. Non-2xx raises
`httpx.HTTPStatusError` — stack `@retryable` on top for retries.

```python
from pico_httpx import http_client, get, post

@http_client(name="users")  # base_url from http.clients.users.base_url
class UsersApi:
    @get("/users/{user_id}")
    def get_user(self, user_id: int) -> dict: ...

    @post("/users")
    async def create_user(self, json: dict) -> dict: ...
```

Settings under `http:`: `timeout_seconds`, `clients.<name>.base_url`.
Clients close on container shutdown.

## pico-data-redis

Redis integration: injectable `redis.Redis` singleton plus a distributed
`CacheBackend` for pico-caching. Installing it is opting in — `@cacheable`
switches to Redis automatically (interceptor prefers non-in-memory backends).
Fail-open: Redis down degrades to cache misses, never errors. Values are
pickled — the Redis instance must be trusted.

Settings under `redis:`: `url`, `socket_timeout_seconds`, `cache_prefix`.

## pico-rabbitmq

RabbitMQ pub-sub (aio-pika) — events, fan-out and topic routing (pico-celery
stays for tasks). Runs on a dedicated background loop: no lifespan wiring.
Ack on success; on exception the message is logged and rejected WITHOUT
requeue (use a dead-letter exchange to keep failures).

```python
from pico_rabbitmq import consumer, publisher, publish

@component
class Projections:
    @consumer("orders-projection", exchange="events", routing_key="orders.*")
    async def on_order(self, message: dict): ...

@publisher
class Events:
    @publish(exchange="events", routing_key="orders.created")
    def order_created(self, message): ...
```

Settings under `rabbitmq:`: `url`, `enabled`, `prefetch_count`,
`publish_timeout_seconds`.

## pico-kafka

Kafka (aiokafka), same shape as pico-rabbitmq. A raising handler logs and
SKIPS its record (offsets advance — poison records never stall a partition).
Different `group_id`s on the same topic fan the stream out.

```python
from pico_kafka import kafka_consumer, kafka_producer, produce

@component
class Projection:
    @kafka_consumer("orders")
    async def on_order(self, message: dict): ...

@kafka_producer
class Events:
    @produce("orders")
    def order_created(self, message): ...
```

Settings under `kafka:`: `bootstrap_servers`, `enabled`, `group_id`,
`produce_timeout_seconds`.

## pico-testing

Pytest plugin, active on install. Sets `PICO_BOOT_AUTO_PLUGINS=false` for
every test (suite results never depend on what else is installed in the
venv); opt back in per-test with `@pytest.mark.pico_auto_plugins`. Provides
`make_container(*modules, config=dict|configuration, boot=False)` with
automatic shutdown on teardown — replaces the hand-written conftest fixtures.
