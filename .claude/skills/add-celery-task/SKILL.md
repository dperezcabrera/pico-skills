---
name: add-celery-task
description: Add a Celery task with pico-celery. Use when creating background tasks, async workers, or task clients.
argument-hint: [task name]
allowed-tools: Read Grep Glob Write Edit
---

# Add Celery Task

Create a Celery task: $ARGUMENTS

Read the codebase to understand existing tasks and patterns, then create the task.

## Worker-Side Task

Worker methods must be `async def`. They are auto-registered by `PicoTaskRegistrar` at startup.

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

## Client-Side Task Sender

The method body is never executed — calling it sends the task to the Celery broker and returns an `AsyncResult`.

```python
from pico_celery import celery, send_task, CeleryClient

@celery
class ${ARGUMENTS}Client(CeleryClient):
    @send_task("tasks.$ARGUMENTS")
    def process(self, item_id: int):
        pass
```

## Complete Example

```python
# worker.py
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

# client.py
from pico_celery import celery, send_task, CeleryClient

@celery
class EmailClient(CeleryClient):
    @send_task("notifications.send_email")
    def send_email(self, to: str, subject: str, body: str):
        pass

# usage.py
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

- [ ] Unique task name matching between `@task` and `@send_task` (e.g., `"domain.action"`)
- [ ] Worker method is `async def`
- [ ] Client class extends `CeleryClient` and uses `@celery` decorator
- [ ] Celery broker/backend configured in `CelerySettings`
