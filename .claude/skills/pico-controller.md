---
name: pico-controller
description: Creates FastAPI controllers integrated with pico-ioc
argument-hint: [controller name or endpoint path]
---

# Pico-FastAPI Controller Creator

Create a controller for: $ARGUMENTS

## Rules

- Use `@controller` decorator (automatically applies `@component` with `scope="request"`)
- Use `@get`, `@post`, `@put`, `@delete`, `@patch`, `@websocket` for route methods
- Dependencies are injected via constructor type hints (no `Depends(inject(...))` needed)
- All imports from `pico_fastapi` for decorators, from `pico_ioc` for DI

## Basic Controller

```python
from pico_fastapi import controller, get, post, put, delete

@controller(prefix="/items", tags=["items"])
class ItemController:
    def __init__(self, service: ItemService):
        self.service = service

    @get("/")
    async def list_items(self, limit: int = 10, offset: int = 0):
        return await self.service.list(limit=limit, offset=offset)

    @get("/{item_id}")
    async def get_item(self, item_id: int):
        return await self.service.get(item_id)

    @post("/", status_code=201)
    async def create_item(self, data: ItemCreate):
        return await self.service.create(data)

    @put("/{item_id}")
    async def update_item(self, item_id: int, data: ItemUpdate):
        return await self.service.update(item_id, data)

    @delete("/{item_id}", status_code=204)
    async def delete_item(self, item_id: int):
        await self.service.delete(item_id)
```

## With Custom Scope

```python
@controller(prefix="/admin", tags=["admin"], scope="singleton")
class AdminController:
    def __init__(self, admin_service: AdminService):
        self.admin_service = admin_service

    @get("/stats")
    async def stats(self):
        return await self.admin_service.get_stats()
```

## WebSocket Endpoint

```python
from pico_fastapi import controller, websocket

@controller(prefix="/ws")
class ChatController:
    def __init__(self, chat_service: ChatService):
        self.chat_service = chat_service

    @websocket("/chat")
    async def chat(self, websocket):
        await websocket.accept()
        async for message in websocket.iter_text():
            response = await self.chat_service.process(message)
            await websocket.send_text(response)
```

## FastAPI Configuration

```python
from dataclasses import dataclass
from pico_ioc import configured

@configured(prefix="fastapi")
@dataclass
class FastApiSettings:
    title: str = "My API"
    version: str = "1.0.0"
    debug: bool = False
```

## Custom App Configurer

Use `FastApiConfigurer` to add middleware or customize the FastAPI app:

```python
from fastapi import FastAPI
from pico_ioc import component
from pico_fastapi import FastApiConfigurer

@component
class CorsConfigurer(FastApiConfigurer):
    priority = -10  # Negative = outer middleware (applied after inner)

    def configure(self, app: FastAPI) -> None:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_methods=["*"],
        )
```

## Checklist

- [ ] Controller with appropriate prefix and tags
- [ ] Route methods with correct HTTP verbs
- [ ] Request/response models defined (Pydantic)
- [ ] Error handling for domain exceptions
- [ ] Services injected via constructor
