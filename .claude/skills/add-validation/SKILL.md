---
name: add-validation
description: Add Pydantic validation to component methods with pico-pydantic. Use when adding input validation to services or API handlers.
argument-hint: [component or method to validate]
---

# Add Validation

Add Pydantic validation to: $ARGUMENTS

Read the codebase to understand existing models and patterns, then add validation.

## Basic Usage

`@validate` automatically validates and transforms Pydantic `BaseModel` parameters. Dicts are converted to model instances.

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
        return User(name=data.name, email=data.email, age=data.age)
```

Both of these work:
```python
await service.create_user({"name": "Alice", "email": "a@b.com", "age": 30})
await service.create_user(CreateUserRequest(name="Alice", email="a@b.com", age=30))
```

## Multiple Validated Parameters

```python
class QueryParams(BaseModel):
    limit: int = Field(default=10, gt=0, le=100)
    offset: int = Field(default=0, ge=0)

@component
class SearchService:
    @validate
    async def search(self, query: str, params: QueryParams) -> list:
        ...
```

## Error Handling

```python
from pico_pydantic import ValidationFailedError

try:
    await service.create_user({"name": "", "age": -1})
except ValidationFailedError as e:
    print(f"Method: {e.method_name}")
    print(f"Error: {e.pydantic_error}")
```

## Checklist

- [ ] Pydantic `BaseModel` defined with field constraints
- [ ] `@validate` on methods receiving external/untrusted data
- [ ] `ValidationFailedError` handled at API boundary
