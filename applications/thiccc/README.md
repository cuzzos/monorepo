# Thiccc - Workout Tracking App

iOS workout tracker with **Rust business logic** + **SwiftUI UI**, plus a **Web app** (Next.js + Rust API).

## Quick Start

```bash
# iOS development
just thiccc ios run      # Build and run in simulator

# Web development  
just thiccc web up       # Start local stack (DB + API + Frontend)
just thiccc web down     # Stop stack
```

**First time?** → Run `build/scripts/setup-mac.sh` first

## What Is This?

**Architecture:** Shared Rust core + platform-specific UIs

- Rust business logic (portable, testable)
- SwiftUI for iOS interface
- Next.js for web frontend
- Rust/Axum for web API
- Automatic Rust↔Swift bridge (UniFFI)

**Features:** Workout tracking, exercise sets, timer, history, plate calculator

## Project Structure

```
thiccc/
├── shared/           # Rust core (business logic)
├── shared_types/     # Generated types (Swift + TypeScript)
├── ios/              # SwiftUI app
├── web_frontend/     # Next.js app
├── api_server/       # Rust API (Axum)
├── build/            # Build tooling (justfiles, docker, env, scripts)
└── docs/             # Documentation
```

**Full details:** [docs/STRUCTURE.md](./docs/STRUCTURE.md)

## Commands

```bash
just thiccc              # List all commands
just thiccc ios run      # Build and run iOS simulator
just thiccc ios test     # Run Rust tests
just thiccc web up       # Start web dev stack
just thiccc web logs     # View container logs
just thiccc clean        # Remove all build artifacts
```

## Documentation

- **[docs/STRUCTURE.md](./docs/STRUCTURE.md)** - Project structure overview
- **[docs/QUICKSTART.md](./docs/QUICKSTART.md)** - Setup instructions
- **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - How it works
- **[docs/web/](./docs/web/)** - Web development phases

## Stack

**Rust:** Crux, UniFFI, Axum, SQLx, serde  
**Swift:** iOS 18+, SwiftUI, UniFFI-generated bindings  
**Web:** Next.js, React, TypeScript, Clerk (auth)
