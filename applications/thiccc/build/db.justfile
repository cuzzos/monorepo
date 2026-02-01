# Database Commands

default:
    @just --list db

# Run migrations (requires local sqlx-cli: cargo install sqlx-cli)
migrate:
    @echo "Running migrations..."
    sqlx migrate run --source db/migrations
    @echo "✅ Migrations complete"

# Check migration status
status:
    sqlx migrate info --source db/migrations

# Create a new migration file
new name:
    @echo "Creating migration: {{name}}"
    sqlx migrate add -r {{name}} --source db/migrations
    @echo "✅ Created migration in db/migrations/"

# Revert last migration (use with caution!)
revert:
    @echo "⚠️  Reverting last migration..."
    sqlx migrate revert --source db/migrations
    @echo "✅ Reverted"
