# Database

Database schema and migrations for Thiccc.

## Structure

```
db/
├── migrations/     # SQL migration files
└── README.md
```

## Running Migrations

### Local Development (Docker)

Migrations run automatically when you start the stack:

```bash
just thiccc web up    # db-migrate service runs before API starts
```

### Manual Migration

For running migrations manually (requires `sqlx-cli`):

```bash
# Install sqlx-cli (one-time)
cargo install sqlx-cli --no-default-features --features postgres

# Run migrations
just thiccc db migrate

# Check status
just thiccc db status
```

## Creating Migrations

```bash
# Create a new migration (creates up/down files)
just thiccc db new add_workouts_table
```

This creates files in `db/migrations/` with timestamp prefix.

### Migration Best Practices

1. **One change per migration** - easier to debug and rollback
2. **Write reversible migrations** - always include down migration
3. **Test locally first** - run against local DB before deploying
4. **Never edit deployed migrations** - create a new one instead

## Local Development

The local PostgreSQL runs in Docker via `just thiccc web up`:

| Setting | Value |
|---------|-------|
| Host | `localhost:5432` |
| Database | `thiccc` |
| User | `postgres` |
| Password | `postgres` |

Connection string: `postgres://postgres:postgres@localhost:5432/thiccc`

## Production

Production database is hosted on Railway. Run migrations manually before deploying API changes that require schema updates:

```bash
DATABASE_URL=<production-url> just thiccc db migrate
```

### Future: CI/CD Migrations

When ready to automate, add a GitHub Actions step that runs migrations after PR merge but before deploy:

```yaml
# .github/workflows/deploy.yml
- name: Run database migrations
  run: |
    cargo install sqlx-cli --no-default-features --features postgres
    just thiccc db migrate
  env:
    DATABASE_URL: ${{ secrets.RAILWAY_DATABASE_URL }}

- name: Deploy to Railway
  # ... deploy step
```

This ensures migrations are reviewed in PRs and run automatically on merge.
