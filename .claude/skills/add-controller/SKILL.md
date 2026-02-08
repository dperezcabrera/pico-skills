---
name: add-controller
description: Add a FastAPI controller with pico-fastapi. Use when creating REST API endpoints, WebSocket handlers, or HTTP routes.
argument-hint: [controller name or endpoint path]
---

# Add Controller

Create a FastAPI controller for: $ARGUMENTS

Read the codebase to understand existing controllers and patterns, then create the controller.

## Basic Controller

`@controller` automatically applies `@component(scope="request")`.

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

## WebSocket Endpoint

```python
from pico_fastapi import controller, websocket

@controller(prefix="/ws")
class ChatController:
    def __init__(self, chat_service: ChatService):
        self.chat_service = chat_service

    @websocket("/chat")
    async def chat(self, ws):
        await ws.accept()
        async for message in ws.iter_text():
            response = await self.chat_service.process(message)
            await ws.send_text(response)
```

## Custom App Configurer (Middleware)

```python
from fastapi import FastAPI
from pico_ioc import component
from pico_fastapi import FastApiConfigurer

@component
class CorsConfigurer(FastApiConfigurer):
    priority = -10  # Negative = outer middleware

    def configure(self, app: FastAPI) -> None:
        from fastapi.middleware.cors import CORSMiddleware
        app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"])
```

## Checklist

- [ ] Controller with appropriate prefix and tags
- [ ] Route methods with correct HTTP verbs and status codes
- [ ] Request/response Pydantic models defined
- [ ] Dependencies injected via constructor
- [ ] Error handling for domain exceptions
