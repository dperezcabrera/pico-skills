---
name: pico-task
description: Creates Celery tasks integrated with pico-ioc via pico-celery
argument-hint: [task name]
---

# Pico-Celery Task Creator

Create a Celery task: $ARGUMENTS

## Rules

- Worker-side tasks use `@task("task.name")` on `async def` methods
- Client-side senders use `@send_task("task.name")` on methods in a `@celery` class
- Task names must match between worker and client
- All imports from `pico_celery`

## Worker-Side Task Definition

```python
from pico_ioc import component
from pico_celery import task

@component
class ${ARGUMENTS}Worker:
    def __init__(self, service: SomeService):
        self.service = service

    @task("tasks.$ARGUMENTS")
    async def process(self, item_id: int) -> dict:
        result = await self.service.process(item_id)
        return {"status": "done", "item_id": item_id}
```

Tasks are auto-registered by `PicoTaskRegistrar` at startup.

## Client-Side Task Sender

```python
from pico_celery import celery, send_task, CeleryClient

@celery
class ${ARGUMENTS}Client(CeleryClient):
    @send_task("tasks.$ARGUMENTS")
    def process(self, item_id: int):
        pass  # Body is never executed; sends task to Celery broker
```

Calling `client.process(42)` returns a Celery `AsyncResult`.

## Configuration

```python
from dataclasses import dataclass
from pico_ioc import configured

@configured(prefix="celery")
@dataclass
class CelerySettings:
    broker_url: str = "redis://localhost:6379/0"
    backend_url: str = "redis://localhost:6379/1"
    task_track_started: bool = True
```

## Complete Example (Worker + Client)

```python
# tasks.py - Worker side
from pico_ioc import component
from pico_celery import task

@component
class EmailWorker:
    def __init__(self, email_service: EmailService):
        self.email_service = email_service

    @task("notifications.send_email")
    async def send_email(self, to: str, subject: str, body: str) -> dict:
        await self.email_service.send(to=to, subject=subject, body=body)
        return {"sent_to": to}

# client.py - Client side (e.g., from a FastAPI controller)
from pico_celery import celery, send_task, CeleryClient

@celery
class EmailClient(CeleryClient):
    @send_task("notifications.send_email")
    def send_email(self, to: str, subject: str, body: str):
        pass

# usage in a service
@component
class OrderService:
    def __init__(self, email_client: EmailClient):
        self.email_client = email_client

    async def complete_order(self, order: Order):
        # ... business logic ...
        self.email_client.send_email(
            to=order.customer_email,
            subject="Order confirmed",
            body=f"Order {order.id} is confirmed",
        )
```

## Checklist

- [ ] Unique, descriptive task name (e.g., `"domain.action"`)
- [ ] Task name matches between `@task` and `@send_task`
- [ ] Worker method is `async def`
- [ ] Celery broker/backend configured
- [ ] Error handling and retries considered
