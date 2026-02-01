# Thiccc Project Structure

## Directory Overview

```
applications/thiccc/
│
├── 🦀 Shared Rust Core
│   ├── shared/                 # Business logic (Crux) - used by iOS & Web
│   └── shared_types/           # Generated types (Swift + TypeScript)
│
├── 📱 iOS App
│   └── ios/                    # SwiftUI app + Xcode project
│       └── Mintfile            # Swift tool dependencies (XcodeGen)
│
├── 🌐 Web App
│   ├── web_frontend/           # Next.js frontend
│   └── api_server/             # Rust API server (Axum)
│
├── 🗄️ Database
│   └── db/
│       └── migrations/         # SQL migration files
│
├── 📚 Documentation
│   └── docs/
│       ├── web/                # Web development phases
│       ├── feature_migration_plans/  # iOS migration phases
│       └── testing_strategies/ # Testing guides
│
├── 🔧 Build & Configuration
│   ├── build/                  # All build tooling
│   │   ├── web.justfile        # Web dev commands
│   │   ├── ios.justfile        # iOS dev commands
│   │   ├── docker-compose.web-dev.yaml
│   │   ├── Makefile            # iOS build commands
│   │   ├── env/                # Environment configs
│   │   │   ├── common.env      # Secrets (gitignored)
│   │   │   ├── api.env         # API config
│   │   │   ├── web.env         # Web config
│   │   │   └── docker.env      # Docker overrides
│   │   └── scripts/            # Setup & verification scripts
│   │       ├── setup-mac.sh
│   │       └── verify-*.sh
│   ├── .cursor/rules/          # AI agent rules
│   ├── justfile                # Main just commands
│   ├── Cargo.toml              # Rust workspace
│   └── rust-toolchain.toml     # Rust version
│
└── 📄 Root Files
    ├── .cargo/config.toml      # Cargo aliases (xcode)
    └── README.md
```

## Key Directories

| Directory | Purpose | Tech |
|-----------|---------|------|
| `shared/` | Core business logic (iOS + Web) | Rust, Crux |
| `shared_types/` | Generated type bindings | Swift, TypeScript |
| `ios/` | iOS application | SwiftUI, Xcode |
| `web_frontend/` | Web frontend | Next.js, React |
| `api_server/` | Backend API | Rust, Axum |
| `db/` | Database schema & migrations | SQL, PostgreSQL |
| `build/` | All build tooling | Justfiles, Makefile, Docker, env |
| `docs/` | Documentation | Markdown |

## Commands

```bash
# Web development
just thiccc web up      # Start local stack
just thiccc web down    # Stop stack
just thiccc web logs    # View logs

# iOS development  
just thiccc ios run     # Build and run simulator
just thiccc ios test    # Run Rust tests
just thiccc ios verify  # Full verification

# Cleanup
just thiccc clean       # Remove all build artifacts
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    shared/ (Rust + Crux)                │
│                   Business Logic + Models               │
└─────────────────────────────────────────────────────────┘
                    │                    │
                    ▼                    ▼
    ┌───────────────────────┐  ┌───────────────────────┐
    │   shared_types/       │  │   shared_types/       │
    │   → Swift types       │  │   → TypeScript types  │
    └───────────────────────┘  └───────────────────────┘
                │                        │
                ▼                        ▼
    ┌───────────────────────┐  ┌───────────────────────┐
    │       ios/            │  │   api_server/         │
    │   SwiftUI App         │  │   Rust API            │
    └───────────────────────┘  └───────────────────────┘
                                         │
                                         ▼
                               ┌───────────────────────┐
                               │   web_frontend/       │
                               │   Next.js App         │
                               └───────────────────────┘
```

Both iOS and Web share the same Rust business logic in `shared/`.
