---
name: add-repository
description: Add a SQLAlchemy entity and repository with pico-sqlalchemy. Use when creating database models, repositories, or adding database queries.
argument-hint: [entity name]
---

# Add Repository

Create entity and repository for: $ARGUMENTS

Read the codebase to understand existing models and patterns, then create the entity and repository.

## 1. Entity

```python
from sqlalchemy import String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pico_sqlalchemy import AppBase

class $ARGUMENTS(AppBase):
    __tablename__ = "<plural_snake_case>"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    active: Mapped[bool] = mapped_column(default=True)
```

## 2. Repository with Declarative Queries

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

    @query(expr="active = true", paged=True)
    async def find_all_active(self, page: PageRequest) -> Page[$ARGUMENTS]:
        ...
```

### Raw SQL Queries

```python
    @query(sql="SELECT * FROM items WHERE name LIKE :pattern ORDER BY name")
    async def search(self, pattern: str) -> list[$ARGUMENTS]:
        ...
```

## 3. Service Layer

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

## Transaction Propagation

| Mode | Behavior |
|------|----------|
| `REQUIRED` | Join existing or create new (default) |
| `REQUIRES_NEW` | Always start a fresh transaction |
| `SUPPORTS` | Join if exists, otherwise non-transactional |
| `MANDATORY` | Must have active transaction, else error |
| `NOT_SUPPORTED` | Suspend transaction, run without |
| `NEVER` | Error if transaction is active |

## Checklist

- [ ] Entity with correct column types and constraints
- [ ] Repository with `SessionManager` injected via constructor
- [ ] `@query` methods for common lookups
- [ ] Service layer with `@transactional` for business operations
- [ ] Indexes on frequently queried columns
