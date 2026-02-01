# Web Development Commands

# Compose file is in same directory (build/)
# --project-directory .. ensures paths resolve from thiccc/ root
compose := "docker compose -f docker-compose.web-dev.yaml --project-directory .."

default:
    @just --list web

# Start web stack (db + web + api)
up:
    {{compose}} up -d
    @echo ""
    @echo "Services running:"
    @echo "  Database: localhost:5432"
    @echo "  Frontend: http://localhost:3000"
    @echo "  API:      http://localhost:8000"

# Stop all services
down:
    {{compose}} down

# View logs (one, many, or all services; specify: just logs api web)
logs *services:
    {{compose}} logs -f {{services}}

# Reset everything (wipes database)
reset:
    {{compose}} down -v
    {{compose}} up -d
