---
name: add-component
description: Add a new pico-ioc component with dependency injection. Use when creating services, factories, interceptors, event subscribers, or configured settings.
argument-hint: [component name]
allowed-tools: Read Grep Glob Write Edit
---

# Add Pico-IoC Component

Create a component: $ARGUMENTS

Read the codebase to understand existing patterns, then create the component following these templates.

## Basic Component

```python
from pico_ioc import component

@component
class $ARGUMENTS:
    def __init__(self, dependency: SomeDependency):
        self.dependency = dependency

    async def do_something(self) -> Result:
        return await self.dependency.process()
```

## With Scope

```python
@component(scope="singleton")  # singleton | prototype | request
class $ARGUMENTS:
    ...
```

## Factory Provider

Use when the component needs complex construction or wraps an external library:

```python
from pico_ioc import factory, provides

@factory
class InfraFactory:
    @provides(ExternalClient, scope="singleton")
    def create_client(self, settings: AppSettings) -> ExternalClient:
        return ExternalClient(url=settings.url, timeout=settings.timeout)
```

## AOP Interceptor

```python
from pico_ioc import component, MethodInterceptor, MethodCtx

@component(scope="singleton")
class LoggingInterceptor(MethodInterceptor):
    async def invoke(self, ctx: MethodCtx, call_next):
        print(f"Calling {ctx.method_name}")
        result = await call_next(ctx)
        return result
```

Apply with `@intercepted_by(LoggingInterceptor)` on methods.

## Configuration Dataclass

```python
from dataclasses import dataclass
from pico_ioc import configured

@configured(prefix="section_name")
@dataclass
class MySettings:
    host: str = "localhost"
    port: int = 8080
    debug: bool = False
```

Reads from YAML:
```yaml
section_name:
  host: "0.0.0.0"
  port: 9090
```

## Event Subscriber

```python
from pico_ioc import component, subscribe, Event

class OrderPlacedEvent(Event):
    def __init__(self, order_id: int):
        self.order_id = order_id

@component
class NotificationService:
    @subscribe(OrderPlacedEvent)
    async def on_order_placed(self, event: OrderPlacedEvent):
        await self.notify(event.order_id)
```

## Checklist

- [ ] Scope matches lifecycle needs (singleton for stateless, prototype for stateful, request for per-request)
- [ ] Dependencies injected via constructor type hints
- [ ] Protocol/interface defined if multiple implementations exist
- [ ] Component is testable with mocked dependencies
