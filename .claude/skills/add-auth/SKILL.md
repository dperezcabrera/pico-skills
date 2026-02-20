---
name: add-auth
description: Add JWT authentication to pico-fastapi controllers. Use when protecting endpoints, adding role-based access control, implementing custom role resolvers, or configuring SecurityContext.
argument-hint: [endpoint or role resolver name]
allowed-tools: Read Grep Glob Write Edit
---

# Add Authentication

Add JWT authentication for: $ARGUMENTS

Read the codebase to understand existing controllers and patterns, then add authentication following these templates.

## Protect All Routes (Default)

pico-client-auth protects all routes by default. Just add the dependency and configure:

```yaml
# application.yaml
auth_client:
  issuer: https://auth.example.com
  audience: my-api
```

```python
from pico_boot import init
from pico_ioc import configuration, YamlTreeSource
from fastapi import FastAPI

config = configuration(YamlTreeSource("application.yaml"))
container = init(modules=["myapp"], config=config)
app = container.get(FastAPI)
# All routes are now protected — pico-client-auth is auto-discovered
```

## Public Endpoint

```python
from pico_fastapi import controller, get
from pico_client_auth import allow_anonymous

@controller(prefix="/api")
class HealthController:
    @get("/health")
    @allow_anonymous
    async def health(self):
        return {"status": "ok"}
```

## Role-Protected Endpoint

```python
from pico_fastapi import controller, get, post
from pico_client_auth import SecurityContext, requires_role

@controller(prefix="/api/admin", tags=["admin"])
class AdminController:
    def __init__(self, service: AdminService):
        self.service = service

    @get("/users")
    @requires_role("admin")
    async def list_users(self):
        return await self.service.list_users()

    @post("/users/{user_id}/ban")
    @requires_role("admin", "moderator")
    async def ban_user(self, user_id: str):
        return await self.service.ban(user_id)
```

## Access Claims in Services

`SecurityContext` works anywhere within a request — controllers, services, repositories:

```python
from pico_ioc import component
from pico_client_auth import SecurityContext

@component
class AuditService:
    async def log_action(self, action: str):
        claims = SecurityContext.require()
        print(f"[{claims.sub}] {action}")

    async def get_current_org(self) -> str:
        return SecurityContext.require().org_id
```

## Custom Role Resolver (Roles Array)

Override when tokens use a `roles` array instead of a single `role` string:

```python
from pico_ioc import component
from pico_client_auth import RoleResolver, TokenClaims

@component
class ArrayRoleResolver:
    async def resolve(self, claims: TokenClaims, raw_claims: dict) -> list[str]:
        return raw_claims.get("roles", [])
```

## Database Role Resolver with TTL Cache

When roles are stored in a database:

```python
import time

from pico_ioc import component
from pico_client_auth import RoleResolver, TokenClaims

@component
class DatabaseRoleResolver:
    def __init__(self, role_repository: RoleRepository):
        self._repo = role_repository
        self._cache: dict[str, tuple[float, list[str]]] = {}
        self._ttl = 300  # 5 minutes

    async def resolve(self, claims: TokenClaims, raw_claims: dict) -> list[str]:
        cached = self._cache.get(claims.sub)
        if cached and (time.monotonic() - cached[0]) < self._ttl:
            return cached[1]

        roles = await self._repo.find_roles_by_user(claims.sub)
        self._cache[claims.sub] = (time.monotonic(), roles)
        return roles
```

## Keycloak Realm Roles

```python
@component
class KeycloakRoleResolver:
    async def resolve(self, claims: TokenClaims, raw_claims: dict) -> list[str]:
        realm_access = raw_claims.get("realm_access", {})
        return realm_access.get("roles", [])
```

## Disable Auth for Development

```yaml
auth_client:
  enabled: false
```

## Checklist

- [ ] `auth_client.issuer` and `auth_client.audience` configured
- [ ] Public endpoints marked with `@allow_anonymous`
- [ ] Admin endpoints protected with `@requires_role`
- [ ] `SecurityContext.require()` used in services (not just controllers)
- [ ] Custom `RoleResolver` registered if token structure differs from default
- [ ] Tests use RSA keypair fixture and `make_token` factory
