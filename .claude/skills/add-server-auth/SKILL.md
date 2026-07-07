---
name: add-server-auth
description: Add embedded auth server to a pico-boot app. Provides JWT issuance, wallet challenge/verify login, and JWKS endpoint via pico-server-auth.
argument-hint: [embedded|standalone]
allowed-tools: Read Grep Glob Write Edit
---

# Add Auth Server

Add pico-server-auth to the project: $ARGUMENTS

## What pico-server-auth provides

- `POST /auth/challenge` — wallet login step 1 (nonce)
- `POST /auth/wallet` — wallet login step 2 (verify signature, issue JWT)
- `POST /auth/login` — password login (admin bootstrap)
- `GET /auth/jwks` — JWKS for pico-client-auth token validation

Supports ML-DSA-65 (Dilithia), Ed25519 (Solana), secp256k1 (Ethereum) wallet signatures.

## Steps

1. **Add dependency** to `pyproject.toml`:
   ```toml
   "pico-server-auth>=0.1.0",
   ```

2. **Add config** to `application.yaml`:
   ```yaml
   server_auth:
     issuer: "http://localhost:8000"
     audience: "my-app"
     auto_create_admin: true
     admin_email: "admin@example.com"
     admin_password: "changeme"
     challenge_ttl_seconds: 60
     supported_wallet_algorithms:
       - "ML-DSA-65"
       - "Ed25519"
       - "secp256k1"
   ```

3. **For embedded mode** (auth in same process as your app):
   - pico-server-auth is auto-discovered by pico-boot — no code changes needed
   - Ensure `auth_client.issuer` matches `server_auth.issuer`
   - Both share the same FastAPI app

4. **For standalone mode** (separate auth service):
   - Create a minimal `main.py`:
     ```python
     from pico_boot import init
     from pico_ioc import configuration, YamlTreeSource
     from fastapi import FastAPI

     container = init(
         modules=[],  # pico_server_auth is auto-discovered by pico-boot
         config=configuration(YamlTreeSource("application.yaml")),
     )
     app = container.get(FastAPI)
     ```
   - Other services point `auth_client.issuer` to this service's URL

## Custom ChallengeStore

The default in-memory store works for single-process. For multi-instance, register a custom `@component` implementing `ChallengeStore`:

```python
from pico_ioc import component
from pico_server_auth import ChallengeStore

@component
class RedisChallengeStore:
    def create(self, address: str) -> str: ...
    def validate(self, address: str, nonce: str) -> bool: ...
    def cleanup(self) -> int: ...
```

## Checklist

- [ ] Dependency added to pyproject.toml
- [ ] Config section `server_auth` in application.yaml
- [ ] `auth_client.issuer` matches `server_auth.issuer` (if using pico-client-auth)
- [ ] Wallet algorithms configured for your use case
- [ ] Admin credentials changed from defaults
