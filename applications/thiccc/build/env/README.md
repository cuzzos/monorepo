# Environment Configuration

Environment files for local development. Docker Compose loads these in layers where later files override earlier ones.

## Files

| File | Purpose | Committed? |
|------|---------|------------|
| `common.env` | Shared secrets (Clerk keys) | No (gitignored) |
| `db.env` | PostgreSQL config + DATABASE_URL | Yes |
| `api.env` | API server config (PORT, RUST_LOG) | Yes |
| `web.env` | Web frontend config (PORT) | Yes |
| `example.env` | Template for `common.env` | Yes |

## Setup

```bash
# From thiccc/ root:
cp build/env/example.env build/env/common.env
# Then fill in your Clerk keys
```

## How Docker Compose Uses These

In `build/docker-compose.web-dev.yaml`:

```yaml
# Database service loads:
env_file:
  - build/env/db.env      # POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

# Migration service loads:
env_file:
  - build/env/db.env      # DATABASE_URL

# Web service loads:
env_file:
  - build/env/common.env  # Clerk keys
  - build/env/web.env     # PORT=3000

# API service loads:
env_file:
  - build/env/common.env  # Clerk keys
  - build/env/api.env     # PORT=8000, RUST_LOG
  - build/env/db.env      # DATABASE_URL
```

## Production Secrets

Production secrets are **never stored locally**. They're configured in:
- **Railway** → Environment Variables (API + Database)
- **Vercel** → Environment Variables (Web)

The `common.env` file only contains development/test keys (e.g., `pk_test_*`, `sk_test_*`).
