---
name: pico-component
description: Creates pico-ioc components with dependency injection, scopes, factories and interceptors
argument-hint: [component name]
---

# Pico-IoC Component Creator

Create a component for pico-ioc: $ARGUMENTS

## Rules

- All imports from `pico_ioc`
- Use type hints for automatic dependency injection
- Choose the right scope: `singleton` (stateless services), `prototype` (stateful), `request` (per-request)
- Define a Protocol/Interface when multiple implementations exist
- Use `@factory` + `@provides` when the component needs complex construction logic

## Patterns

### Basic Component

```python
from pico_ioc import component

@component
class UserService:
    def __init__(self, repo: UserRepository):
        self.repo = repo

    async def get_user(self, user_id: int) -> User:
        return await self.repo.find_by_id(user_id)
```

### With Scope

```python
@component(scope="singleton")
class CacheService:
    def __init__(self):
        self._cache: dict = {}
```

### Factory Provider

Use when the component requires construction logic or wraps an external library:

```python
from pico_ioc import factory, provides

@factory
class InfraFactory:
    @provides(RedisClient, scope="singleton")
    def create_redis(self, settings: AppSettings) -> RedisClient:
        return RedisClient(host=settings.redis_host, port=settings.redis_port)
```

### With AOP Interceptor

```python
from pico_ioc import component, intercepted_by, MethodInterceptor, MethodCtx

@component(scope="singleton")
class LoggingInterceptor(MethodInterceptor):
    async def invoke(self, ctx: MethodCtx, call_next):
        print(f"Calling {ctx.method_name}")
        result = await call_next(ctx)
        return result

@component
class OrderService:
    @intercepted_by(LoggingInterceptor)
    async def place_order(self, order: Order) -> Order:
        ...
```

### Configuration Dataclass

```python
from dataclasses import dataclass
from pico_ioc import configured

@configured(prefix="app")
@dataclass
class AppSettings:
    name: str = "My App"
    debug: bool = False
    max_connections: int = 10
```

### Event Subscriber

```python
from pico_ioc import component, subscribe, Event

class UserCreatedEvent(Event):
    def __init__(self, user_id: int):
        self.user_id = user_id

@component
class NotificationService:
    @subscribe(UserCreatedEvent)
    async def on_user_created(self, event: UserCreatedEvent):
        await self.send_welcome_email(event.user_id)
```

## Checklist

- [ ] Appropriate scope selected
- [ ] Dependencies injected via constructor type hints
- [ ] Protocol defined if there are multiple implementations
- [ ] Component is testable (dependencies can be mocked)
