# Phase 1: Development Environment Setup

> **TLDR:** Set up complete dev environment for thiccc web app. Install Dagger CLI, verify Docker, create project structure, initialize Rust backend and Next.js frontend, set up Clerk (auth), Railway (PostgreSQL + backend hosting), and Vercel (frontend hosting). Test full stack locally. Estimated time: 1 week. Multiple human checkpoints for account creation and API keys.

## Table of Contents
- [AI Agent Instructions](#-ai-agent-instructions)
- [Required Context](#-required-context)
- [Feature Overview](#-feature-overview)
- [Tasks](#-tasks)
  - [Task 1: Install Dagger CLI](#task-1-install-dagger-cli-estimated-5-mins)
  - [Task 2: Verify Docker is Running](#task-2-verify-docker-is-running-estimated-2-mins)
  - [Task 2.5: Create Dagger Module](#task-25-create-dagger-module-estimated-20-mins)
  - [Task 3: Create Project Structure](#task-3-create-project-structure-estimated-10-mins)
  - [Task 4: Initialize Backend (Rust)](#task-4-initialize-backend-rust-estimated-15-mins)
  - [Task 5: Initialize Frontend (Next.js)](#task-5-initialize-frontend-nextjs-estimated-15-mins)
  - [Task 6: Setup Clerk Account](#task-6-setup-clerk-account-estimated-10-mins)
  - [Task 7: Setup Railway Project](#task-7-setup-railway-project-estimated-10-mins)
  - [Task 8: Setup Vercel Project](#task-8-setup-vercel-project-estimated-5-mins)
  - [Task 9: Test Full Stack Locally](#task-9-test-full-stack-locally-estimated-15-mins)
- [Phase Completion Checklist](#-phase-completion-checklist)
- [Common Issues](#-common-issues)
- [Dependencies](#-dependencies)
- [Progress Tracking](#-progress-tracking)
- [Next Phase](#next-phase)

---

## 🤖 AI Agent Instructions

**When starting this phase:**
1. Read all files in "Required Context" section below
2. Understand we're setting up local dev environment + deployment accounts
3. Follow tasks sequentially
4. Validate each step before proceeding
5. Stop at human checkpoints (marked with 🚨)

**When stuck:**
- Check "Common Issues" section at bottom
- Ask human for clarification

---

## 📚 Required Context

Auto-read these files before starting:

### Project structure
- `@applications/thiccc/docs/web/00-OVERVIEW.md` - Overall architecture
- `@applications/thiccc/shared/Cargo.toml` - Existing Rust core dependencies
- `@applications/thiccc/shared_types/generated/typescript/` - Generated TypeScript types

### Dagger documentation
- `@docs/dagger/QUICKSTART.md` - Dagger installation
- `@docs/dagger/TOOLCHAINS.md` - Available commands
- `@docs/dagger/AI-AGENT-GUIDE.md` - How AI agents use Dagger

---

## 🎯 Feature Overview

**What we're building:** Complete development environment for thiccc web app

**Why:** Before writing code, we need:
- Local development tools (via Dagger)
- Authentication service (Clerk accounts)
- Deployment infrastructure (Railway + Vercel accounts)
- Project scaffolding (folders, configs, dependencies)

**Success criteria:**
- ✅ Dagger installed and working
- ✅ Clerk account created with API keys
- ✅ Railway project created with PostgreSQL
- ✅ Vercel project created
- ✅ Frontend and backend folders created
- ✅ "Hello World" deployed to both platforms
- ✅ Local development works (frontend + backend + DB)

---

## 🔨 Tasks

### Task 1: Install Dagger CLI (Estimated: 5 mins)

**Goal:** Install Dagger so AI agents can run containerized tools

**🚨 Human action required:** User must install Dagger (AI can't install software)

**Instructions for human:**

```bash
# macOS
brew install dagger/tap/dagger

# Or using curl
curl -fsSL https://dl.dagger.io/dagger/install.sh | sh

# Verify installation
dagger version
```

**Validation:**
```bash
dagger version
```

**Expected output:**
```
dagger v0.9.x
```

**🚨 Human checkpoint:** After this task, confirm Dagger is installed.

---

### Task 2: Verify Docker is Running (Estimated: 2 mins)

**Goal:** Dagger requires Docker to run containers

**🚨 Human action required:** User must start Docker Desktop

**Instructions for human:**

```bash
# Check if Docker is running
docker ps

# If not running, start Docker Desktop
open -a Docker
```

**Validation:**
```bash
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

(Empty list is fine - just needs to connect)

**🚨 Human checkpoint:** Confirm Docker is running.

---

### Task 2.5: Create Dagger Module (Estimated: 20 mins)

**Goal:** Create Dagger module with toolchain functions for Rust, Node.js, and PostgreSQL

**Files to create:**
```
dagger/
  dagger.json
  src/
    main.go
```

**Implementation:**

Create `dagger/dagger.json`:
```json
{
  "name": "cuzzo-tools",
  "sdk": "go",
  "source": "./src"
}
```

Create `dagger/src/main.go`:
```go
package main

import (
	"context"
	"dagger/cuzzo-tools/internal/dagger"
)

type CuzzoTools struct{}

// RustBuild builds a Rust project
func (m *CuzzoTools) RustBuild(
	ctx context.Context,
	// +required
	source *dagger.Directory,
) (string, error) {
	return dag.Container().
		From("rust:1.75-slim").
		WithDirectory("/src", source).
		WithWorkdir("/src").
		WithExec([]string{"cargo", "build", "--release"}).
		Stdout(ctx)
}

// RustServe runs a Rust API server
func (m *CuzzoTools) RustServe(
	ctx context.Context,
	// +required
	source *dagger.Directory,
	// +optional
	// +default=8000
	port int,
) *dagger.Service {
	return dag.Container().
		From("rust:1.75-slim").
		WithDirectory("/src", source).
		WithWorkdir("/src").
		WithExec([]string{"cargo", "build", "--release"}).
		WithExec([]string{"cargo", "run", "--release"}).
		WithExposedPort(port).
		AsService()
}

// NodeBuild builds a Next.js project
func (m *CuzzoTools) NodeBuild(
	ctx context.Context,
	// +required
	source *dagger.Directory,
) (string, error) {
	return dag.Container().
		From("node:20-slim").
		WithDirectory("/app", source).
		WithWorkdir("/app").
		WithExec([]string{"npm", "install"}).
		WithExec([]string{"npm", "run", "build"}).
		Stdout(ctx)
}

// NodeDev runs Next.js dev server
func (m *CuzzoTools) NodeDev(
	ctx context.Context,
	// +required
	source *dagger.Directory,
	// +optional
	// +default=3000
	port int,
) *dagger.Service {
	return dag.Container().
		From("node:20-slim").
		WithDirectory("/app", source).
		WithWorkdir("/app").
		WithExec([]string{"npm", "install"}).
		WithExec([]string{"npm", "run", "dev"}).
		WithExposedPort(port).
		AsService()
}

// NodeTypecheck runs TypeScript type checking
func (m *CuzzoTools) NodeTypecheck(
	ctx context.Context,
	// +required
	source *dagger.Directory,
) (string, error) {
	return dag.Container().
		From("node:20-slim").
		WithDirectory("/app", source).
		WithWorkdir("/app").
		WithExec([]string{"npm", "install"}).
		WithExec([]string{"npm", "run", "type-check"}).
		Stdout(ctx)
}

// DbServe runs a PostgreSQL database
func (m *CuzzoTools) DbServe(
	ctx context.Context,
	// +optional
	// +default=5432
	port int,
) *dagger.Service {
	return dag.Container().
		From("postgres:16-alpine").
		WithEnvVariable("POSTGRES_PASSWORD", "postgres").
		WithEnvVariable("POSTGRES_DB", "thiccc").
		WithExposedPort(port).
		AsService()
}
```

Create `dagger/src/go.mod`:
```go
module dagger/cuzzo-tools

go 1.21

require (
	github.com/99designs/gqlgen v0.17.31
	github.com/Khan/genqlient v0.6.0
	golang.org/x/exp v0.0.0-20231006140011-7918f672742d
	golang.org/x/sync v0.6.0
)
```

**Validation:**
```bash
cd dagger
dagger init --sdk=go
dagger develop

# Test commands
dagger functions
```

**Expected output:**
```
rust-build      Build a Rust project
rust-serve      Run a Rust API server
node-build      Build a Next.js project
node-dev        Run Next.js dev server
node-typecheck  Run TypeScript type checking
db-serve        Run a PostgreSQL database
```

**Notes:**
- This creates a reusable Dagger module at the monorepo root
- All other applications can use these same tools
- Functions are containerized - no local Rust/Node installation needed

---

### Task 3: Create Project Structure (Estimated: 10 mins)

**Goal:** Create folder structure for web app

**Files to create:**
```
applications/thiccc/web_frontend/
applications/thiccc/api_server/
applications/thiccc/api_server/src/
applications/thiccc/api_server/migrations/
```

**Implementation:**

```bash
cd applications/thiccc
mkdir -p web_frontend
mkdir -p api_server/src
mkdir -p api_server/migrations
```

**Validation:**
```bash
ls -la applications/thiccc/
```

**Expected output:**
```
drwxr-xr-x  api_server/
drwxr-xr-x  web_frontend/
```

---

### Task 4: Initialize Backend (Rust) (Estimated: 15 mins)

**Goal:** Create Rust backend project that imports `shared` crate

**Files to create:**
```
api_server/Cargo.toml
api_server/src/main.rs
api_server/.gitignore
```

**Implementation:**

Create `api_server/Cargo.toml`:
```toml
[package]
name = "thiccc-backend"
version = "0.1.0"
edition = "2021"

[dependencies]
# Import shared business logic
shared = { path = "../app/shared" }

# Web framework
axum = "0.7"
tokio = { version = "1", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Database
sqlx = { version = "0.7", features = ["runtime-tokio", "postgres", "uuid", "chrono", "migrate"] }

# Authentication
jsonwebtoken = "9"

# Utilities
tracing = "0.1"
tracing-subscriber = "0.3"
uuid = { version = "1.0", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
dotenv = "0.15"
```

Create `api_server/src/main.rs`:
```rust
use axum::{routing::get, Router};
use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    // Build router
    let app = Router::new()
        .route("/health", get(health_check));

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], 8000));
    tracing::info!("Server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health_check() -> &'static str {
    "OK"
}
```

Create `api_server/.gitignore`:
```
/target
.env
.env.local
```

**Validation:**
```bash
dagger call rust-build --source=applications/thiccc/api_server
```

**Expected outcome:**
- Rust project compiles successfully
- Can run: `dagger call rust-serve --source=applications/thiccc/api_server --port=8000`
- Health check works: `curl http://localhost:8000/health` returns "OK"

---

### Task 5: Initialize Frontend (Next.js) (Estimated: 15 mins)

**Goal:** Create Next.js project with TypeScript

**Files to create:**
```
web_frontend/package.json
web_frontend/tsconfig.json
web_frontend/next.config.js
web_frontend/.gitignore
web_frontend/app/layout.tsx
web_frontend/app/page.tsx
```

**Implementation:**

Create `web_frontend/package.json`:
```json
{
  "name": "thiccc-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "@tanstack/react-query": "^5.0.0",
    "@clerk/nextjs": "^5.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "typescript": "^5.3.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "tailwindcss": "^3.4.0",
    "eslint": "^8.0.0",
    "eslint-config-next": "^15.0.0"
  }
}
```

Create `web_frontend/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "preserve",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowJs": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "incremental": true,
    "paths": {
      "@/*": ["./*"]
    },
    "plugins": [
      {
        "name": "next"
      }
    ]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

Create `web_frontend/next.config.js`:
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: {
    serverActions: {
      bodySizeLimit: '2mb',
    },
  },
};

module.exports = nextConfig;
```

Create `web_frontend/.gitignore`:
```
# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local
.env

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts
```

Create `web_frontend/app/layout.tsx`:
```typescript
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Thiccc - Workout Tracker',
  description: 'Track your workouts, analyze your progress',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

Create `web_frontend/app/page.tsx`:
```typescript
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold">Welcome to Thiccc</h1>
      <p className="mt-4 text-xl">Workout tracking app</p>
    </main>
  );
}
```

Create `web_frontend/app/globals.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Create `web_frontend/tailwind.config.ts`:
```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
export default config;
```

Create `web_frontend/postcss.config.js`:
```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

**Validation:**
```bash
# Type check
dagger call node-typecheck --source=applications/thiccc/web_frontend

# Build
dagger call node-build --source=applications/thiccc/web_frontend

# Dev server (in background)
dagger call node-dev --source=applications/thiccc/web_frontend --port=3000
```

**Expected outcome:**
- TypeScript compiles without errors
- Next.js builds successfully
- Dev server runs on localhost:3000
- Shows "Welcome to Thiccc" page

---

### Task 6: Setup Clerk Account (Estimated: 10 mins)

**Goal:** Create Clerk account for authentication

**🚨 Human action required:** User must create Clerk account and get API keys

**Instructions for human:**

1. Go to https://clerk.com
2. Sign up for free account
3. Create new application: "Thiccc Web"
4. Go to API Keys section
5. Copy:
   - Publishable Key (starts with `pk_test_`)
   - Secret Key (starts with `sk_test_`)

**Files to create:**
```
web_frontend/.env.example
web_frontend/.env.local
```

Create `web_frontend/.env.example`:
```bash
# Clerk API Keys
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxx
CLERK_SECRET_KEY=sk_test_xxxxx

# Backend API URL
NEXT_PUBLIC_API_URL=http://localhost:8000
```

Create `web_frontend/.env.local` (user fills in real values):
```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_ACTUAL_KEY_HERE
CLERK_SECRET_KEY=sk_test_ACTUAL_KEY_HERE
NEXT_PUBLIC_API_URL=http://localhost:8000
```

**🚨 Human checkpoint:** User provides Clerk API keys.

---

### Task 7: Setup Railway Project (Estimated: 10 mins)

**Goal:** Create Railway project for backend + database hosting

**🚨 Human action required:** User must create Railway account and project

**Instructions for human:**

1. Go to https://railway.app
2. Sign up with GitHub account
3. Click "New Project"
4. Select "Deploy PostgreSQL"
5. Note the project name
6. Click "Add Service" → "Empty Service" (for Rust backend later)
7. Go to PostgreSQL service → Variables
8. Copy `DATABASE_URL`

Create `api_server/.env.example`:
```bash
# Database (from Railway PostgreSQL)
DATABASE_URL=postgresql://user:password@host:port/database

# Clerk JWT validation
CLERK_JWT_ISSUER=https://your-app.clerk.accounts.dev
CLERK_JWKS_URL=https://your-app.clerk.accounts.dev/.well-known/jwks.json

# Server
PORT=8000
RUST_LOG=info
```

Create `api_server/.env.local` (user fills in real values):
```bash
DATABASE_URL=postgresql://ACTUAL_URL_FROM_RAILWAY
CLERK_JWT_ISSUER=https://ACTUAL_FROM_CLERK
CLERK_JWKS_URL=https://ACTUAL_FROM_CLERK/.well-known/jwks.json
PORT=8000
RUST_LOG=info
```

**🚨 Human checkpoint:** User provides Railway DATABASE_URL.

---

### Task 8: Setup Vercel Project (Estimated: 5 mins)

**Goal:** Create Vercel project for frontend hosting

**🚨 Human action required:** User must create Vercel account and connect repo

**Instructions for human:**

1. Go to https://vercel.com
2. Sign up with GitHub account
3. Click "Add New Project"
4. Import `cuzzo_monorepo` repo
5. Set root directory: `applications/thiccc/web_frontend`
6. Framework: Next.js (auto-detected)
7. Add environment variables (from `.env.local`)
8. Click "Deploy"

**Note:** Don't deploy yet - we'll do this in Phase 2 after auth is setup.

**🚨 Human checkpoint:** User confirms Vercel project is created (don't deploy yet).

---

### Task 9: Test Full Stack Locally (Estimated: 15 mins)

**Goal:** Verify everything works together

**Implementation:**

Terminal 1 - Start PostgreSQL:
```bash
dagger call db-serve --port=5432
```

Terminal 2 - Start backend:
```bash
dagger call rust-serve --source=applications/thiccc/api_server --port=8000
```

Terminal 3 - Start frontend:
```bash
dagger call node-dev --source=applications/thiccc/web_frontend --port=3000
```

Terminal 4 - Test:
```bash
# Test backend health check
curl http://localhost:8000/health

# Open frontend in browser
open http://localhost:3000
```

**Validation:**
- ✅ Backend health check returns "OK"
- ✅ Frontend loads in browser
- ✅ No console errors

---

## ✅ Phase Completion Checklist

- [ ] Dagger installed and working
- [ ] Docker running
- [ ] Dagger module created with toolchain functions
- [ ] Project structure created
- [ ] Backend compiles and runs
- [ ] Frontend builds and runs
- [ ] Clerk account created with API keys
- [ ] Railway project created with PostgreSQL
- [ ] Vercel project created
- [ ] Local full stack works (all 3 services)
- [ ] `.env.example` files created
- [ ] `.env.local` files created (user has real keys)
- [ ] All `.env.local` files in `.gitignore`

---

## 🚨 Common Issues

### Issue: Dagger command not found

**Symptom:** `command not found: dagger`

**Solution:**
```bash
# Add to PATH
export PATH="$HOME/.dagger/bin:$PATH"

# Or reinstall
brew install dagger/tap/dagger
```

### Issue: Docker not running

**Symptom:** `Cannot connect to Docker daemon`

**Solution:**
```bash
# Start Docker Desktop
open -a Docker

# Wait 30 seconds for it to start
docker ps
```

### Issue: Port already in use

**Symptom:** `Address already in use (os error 48)`

**Solution:**
```bash
# Find process using port
lsof -i :8000

# Kill it
kill -9 PID

# Or use different port
dagger call rust-serve --source=... --port=8001
```

### Issue: Rust compilation fails

**Symptom:** `error: could not compile shared`

**Solution:**
```bash
# Clean build
cd applications/thiccc/shared
cargo clean

# Try again
dagger call rust-build --source=applications/thiccc/web/backend
```

### Issue: Next.js build fails

**Symptom:** TypeScript errors

**Solution:**
```bash
# Check tsconfig.json is correct
# Verify all imports are valid
dagger call node-typecheck --source=applications/thiccc/web/frontend
```

---

## 🔗 Dependencies

**Requires:**
- Phase 0: Overview (read first)
- Dagger documentation (`/docs/dagger/`)

**Blocks:**
- Phase 2: Auth (needs Clerk + project structure)

---

## 📊 Progress Tracking

| Task | Status | AI Agent | Human Review | Notes |
|------|--------|----------|--------------|-------|
| 1. Install Dagger | ⬜ | N/A | Required | Human must install |
| 2. Verify Docker | ⬜ | N/A | Required | Human must start |
| 2.5. Create Dagger module | ⬜ | Can do | Review code | Creates toolchain |
| 3. Project structure | ⬜ | Can do | Optional | |
| 4. Backend init | ⬜ | Can do | Review Cargo.toml | |
| 5. Frontend init | ⬜ | Can do | Review package.json | |
| 6. Clerk account | ⬜ | N/A | Required | Human must create |
| 7. Railway project | ⬜ | N/A | Required | Human must create |
| 8. Vercel project | ⬜ | N/A | Required | Human must create |
| 9. Test locally | ⬜ | Can test | Required | Verify all works |

**Legend:** ⬜ Not started | ⏳ In progress | ✅ Done | ❌ Blocked

---

## Next Phase

Once this phase is complete, proceed to:
**Phase 2: Authentication** (`02-PHASE-2-AUTH.md`)

