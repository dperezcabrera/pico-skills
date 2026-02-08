---
name: pico-validate
description: Adds Pydantic validation to pico-ioc component methods via pico-pydantic
argument-hint: [component or method to validate]
---

# Pico-Pydantic Validation

Add validation to: $ARGUMENTS

## Rules

- Use `@validate` decorator on methods that receive external/untrusted data
- Pydantic `BaseModel` parameters are automatically validated and transformed
- Works with both sync and async methods
- Catches `ValidationFailedError` for error handling
- All imports from `pico_pydantic`

## Basic Usage

```python
from pydantic import BaseModel, Field
from pico_ioc import component
from pico_pydantic import validate

class CreateUserRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str
    age: int = Field(gt=0, lt=150)

@component
class UserService:
    @validate
    async def create_user(self, data: CreateUserRequest) -> User:
        # data is already validated and transformed from dict if needed
        return User(name=data.name, email=data.email, age=data.age)
```

## Dict-to-Model Transformation

The `@validate` interceptor automatically converts dicts to Pydantic models:

```python
# This works - dict is validated and converted to CreateUserRequest
await service.create_user({"name": "Alice", "email": "alice@example.com", "age": 30})

# This also works - already a model instance
await service.create_user(CreateUserRequest(name="Alice", email="alice@example.com", age=30))
```

## Multiple Validated Parameters

```python
class QueryParams(BaseModel):
    limit: int = Field(default=10, gt=0, le=100)
    offset: int = Field(default=0, ge=0)
    search: str | None = None

class SortParams(BaseModel):
    field: str
    direction: str = "asc"

@component
class SearchService:
    @validate
    async def search(self, query: QueryParams, sort: SortParams) -> list:
        ...
```

## Error Handling

```python
from pico_pydantic import ValidationFailedError

try:
    await service.create_user({"name": "", "email": "invalid", "age": -1})
except ValidationFailedError as e:
    print(f"Method: {e.method_name}")
    print(f"Error: {e.pydantic_error}")
```

## Generic Types with Models

`@validate` also handles generic types containing Pydantic models:

```python
@component
class BatchService:
    @validate
    async def process_batch(self, items: list[CreateUserRequest]) -> list[User]:
        # Each item in the list is validated
        ...

    @validate
    async def process_optional(self, item: CreateUserRequest | None = None) -> User | None:
        ...
```

## Checklist

- [ ] Pydantic models defined for input data
- [ ] `@validate` on methods receiving external data
- [ ] Field constraints defined (min/max, patterns, etc.)
- [ ] `ValidationFailedError` handled at API boundary
