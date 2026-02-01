# Local Development Commands

compose := "docker compose -f docker-compose.web-dev.yaml --project-directory .."

default:
    @just --list run-dev

# Start local development stack + apply migrations
up:
    @echo "🚀 Starting local development stack..."
    {{compose}} up -d
    @echo ""
    @echo "⏳ Waiting for database to be ready..."
    @sleep 2
    @echo "📦 Applying migrations..."
    @DATABASE_URL="postgres://thiccc:thiccc@localhost:5432/thiccc" sqlx migrate run --source ../db/migrations 2>/dev/null || echo "  (sqlx-cli not installed, skipping migrations)"
    @echo ""
    @echo "✅ Stack running:"
    @echo "  Database: localhost:5432"
    @echo "  API:      http://localhost:8000"
    @echo "  Frontend: http://localhost:3000"

# Stop local development stack
down:
    @echo "🛑 Stopping local development stack..."
    {{compose}} down

# View logs (optionally specify services: just run-dev logs api web)
logs *services:
    {{compose}} logs -f {{services}}

# Reset local stack (wipes database)
reset:
    @echo "🔄 Resetting local development stack..."
    {{compose}} down -v
    {{compose}} up -d
    @echo ""
    @echo "⏳ Waiting for database to be ready..."
    @sleep 2
    @echo "📦 Applying migrations..."
    @DATABASE_URL="postgres://thiccc:thiccc@localhost:5432/thiccc" sqlx migrate run --source ../db/migrations 2>/dev/null || echo "  (sqlx-cli not installed, skipping migrations)"
    @echo ""
    @echo "✅ Stack reset complete"
