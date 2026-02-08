---
name: pico-tests
description: Generates tests for pico-framework components
argument-hint: [component to test]
---

# Pico Framework Test Generator

Generate tests for: $ARGUMENTS

## Rules

- Use `pytest` with `pytest-asyncio` for async tests
- Mock dependencies via constructor injection
- Test the component in isolation, not the container
- Follow the Arrange-Act-Assert pattern
- Name tests: `test_<method>_<scenario>`

## Component Test

```python
import pytest
from unittest.mock import AsyncMock, MagicMock

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

## Repository Test (with real database)

```python
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from pico_sqlalchemy import SessionManager

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

## Controller Test

```python
import pytest
from httpx import AsyncClient, ASGITransport

@pytest.fixture
async def client(app):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client

class TestItemController:
    @pytest.mark.asyncio
    async def test_list_items(self, client):
        response = await client.get("/items/")
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    @pytest.mark.asyncio
    async def test_create_item(self, client):
        response = await client.post("/items/", json={"name": "Test"})
        assert response.status_code == 201
```

## Validation Test

```python
import pytest
from pico_pydantic import ValidationFailedError

class TestUserServiceValidation:
    @pytest.mark.asyncio
    async def test_create_user_with_valid_data(self, service):
        result = await service.create_user({"name": "Alice", "email": "a@b.com", "age": 30})
        assert result.name == "Alice"

    @pytest.mark.asyncio
    async def test_create_user_rejects_invalid_data(self, service):
        with pytest.raises(ValidationFailedError):
            await service.create_user({"name": "", "age": -1})
```

## Integration Test (with container)

```python
import pytest
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
- [ ] Happy path covered
- [ ] Error/edge cases covered
- [ ] Async tests use `@pytest.mark.asyncio`
- [ ] Fixtures for reusable setup
- [ ] Integration test with real container (optional)
