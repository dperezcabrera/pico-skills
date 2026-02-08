---
name: pico-repository
description: Creates SQLAlchemy repositories and entities with pico-sqlalchemy
argument-hint: [entity name]
---

# Pico-SQLAlchemy Repository Creator

Create a repository for: $ARGUMENTS

## Rules

- Entities extend `AppBase` from `pico_sqlalchemy`
- Repositories use `@repository` decorator (auto-registers as singleton component with transactional methods)
- Use `@query` for declarative queries (body is ignored, query auto-executed)
- Use `@transactional` for explicit transaction control
- Use `get_session(self.manager)` to access the current `AsyncSession`
- `SessionManager` is injected automatically by pico-ioc

## Entity

```python
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column
from pico_sqlalchemy import AppBase

class $ARGUMENTS(AppBase):
    __tablename__ = "${arguments_snake}s"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    active: Mapped[bool] = mapped_column(default=True)
```

## Repository

### With Declarative Queries

```python
from pico_sqlalchemy import repository, query, get_session, SessionManager, Page, PageRequest

@repository(entity=$ARGUMENTS)
class ${ARGUMENTS}Repository:
    def __init__(self, manager: SessionManager):
        self.manager = manager

    async def save(self, entity: $ARGUMENTS) -> $ARGUMENTS:
        session = get_session(self.manager)
        session.add(entity)
        return entity

    @query(expr="id = :id", unique=True)
    async def find_by_id(self, id: int) -> $ARGUMENTS | None:
        ...

    @query(expr="name = :name", unique=True)
    async def find_by_name(self, name: str) -> $ARGUMENTS | None:
        ...

    @query(expr="active = :active", paged=True)
    async def find_active(self, active: bool, page: PageRequest) -> Page[$ARGUMENTS]:
        ...
```

### With Raw SQL

```python
@repository(entity=$ARGUMENTS)
class ${ARGUMENTS}Repository:
    def __init__(self, manager: SessionManager):
        self.manager = manager

    @query(sql="SELECT * FROM ${arguments_snake}s WHERE name LIKE :pattern")
    async def search(self, pattern: str) -> list[$ARGUMENTS]:
        ...
```

### With Explicit Transactions

```python
from pico_sqlalchemy import repository, transactional, get_session, SessionManager

@repository
class ${ARGUMENTS}Repository:
    def __init__(self, manager: SessionManager):
        self.manager = manager

    @transactional(propagation="REQUIRES_NEW")
    async def save_in_new_tx(self, entity: $ARGUMENTS) -> $ARGUMENTS:
        session = get_session(self.manager)
        session.add(entity)
        return entity
```

## Service Layer

```python
from pico_ioc import component
from pico_sqlalchemy import transactional

@component
class ${ARGUMENTS}Service:
    def __init__(self, repo: ${ARGUMENTS}Repository):
        self.repo = repo

    @transactional
    async def create(self, name: str) -> $ARGUMENTS:
        entity = $ARGUMENTS(name=name)
        return await self.repo.save(entity)

    @transactional(read_only=True)
    async def get(self, id: int) -> $ARGUMENTS:
        item = await self.repo.find_by_id(id)
        if not item:
            raise ValueError(f"$ARGUMENTS {id} not found")
        return item
```

## Transaction Propagation Modes

| Mode | Behavior |
|------|----------|
| `REQUIRED` (default) | Join existing or create new |
| `REQUIRES_NEW` | Always start a fresh transaction |
| `SUPPORTS` | Join if exists, otherwise non-transactional |
| `MANDATORY` | Must have active transaction, else error |
| `NOT_SUPPORTED` | Suspend transaction, run without |
| `NEVER` | Error if transaction is active |

## Checklist

- [ ] Entity with correct column types and constraints
- [ ] Repository with `SessionManager` injected
- [ ] Declarative `@query` methods for common lookups
- [ ] Service layer with `@transactional` for business operations
- [ ] Indexes on frequently queried columns
