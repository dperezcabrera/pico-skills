---
name: add-tests
description: Generate tests for pico-framework components. Use when creating unit tests, integration tests, or test fixtures for services, repositories, controllers, or agents.
argument-hint: [component to test]
---

# Add Tests

Generate tests for: $ARGUMENTS

Read the component source code first, then generate tests following these patterns.

## Service Test (unit)

```python
import pytest
from unittest.mock import AsyncMock

class TestMyService:
    @pytest.fixture
    def mock_repo(self):
        repo = AsyncMock()
        repo.find_by_id.return_value = User(id=1, name="Alice")
        return repo

    @pytest.fixture
    def service(self, mock_repo):
        return MyService(repo=mock_repo)

    @pytest.mark.asyncio
    async def test_get_user_returns_user(self, service):
        result = await service.get_user(1)
        assert result.name == "Alice"

    @pytest.mark.asyncio
    async def test_get_user_raises_when_not_found(self, service, mock_repo):
        mock_repo.find_by_id.return_value = None
        with pytest.raises(ValueError, match="not found"):
            await service.get_user(999)
```

## Repository Test (integration, in-memory DB)

```python
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from pico_sqlalchemy import SessionManager, AppBase

@pytest.fixture
async def session_manager():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(AppBase.metadata.create_all)
    sm = SessionManager(async_sessionmaker(engine))
    yield sm
    await engine.dispose()

@pytest.fixture
def repo(session_manager):
    return UserRepository(manager=session_manager)

class TestUserRepository:
    @pytest.mark.asyncio
    async def test_save_and_find(self, repo, session_manager):
        async with session_manager.transaction():
            user = await repo.save(User(name="Alice"))
            found = await repo.find_by_id(user.id)
            assert found.name == "Alice"
```

## Controller Test (HTTP)

```python
import pytest
from httpx import AsyncClient, ASGITransport

@pytest.fixture
async def client(app):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c

class TestItemController:
    @pytest.mark.asyncio
    async def test_list_items(self, client):
        response = await client.get("/items/")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_create_item(self, client):
        response = await client.post("/items/", json={"name": "Test"})
        assert response.status_code == 201
```

## Container Integration Test

```python
from pico_ioc import init

class TestIntegration:
    @pytest.fixture
    def container(self):
        return init(modules=[__name__])

    def test_service_resolves(self, container):
        service = container.get(MyService)
        assert service is not None
```

## Checklist

- [ ] Unit tests with mocked dependencies
- [ ] Happy path and error cases covered
- [ ] Async tests use `@pytest.mark.asyncio`
- [ ] Fixtures for reusable setup
- [ ] Test naming: `test_<method>_<scenario>`
