# Phase 1: Development Environment Setup

> **TLDR:** Set up complete dev environment for thiccc web app. Verify Docker, test local stack with `just` commands, set up Clerk (auth), Railway (PostgreSQL + backend hosting), and Vercel (frontend hosting).

## Table of Contents

- [AI Agent Instructions](#-ai-agent-instructions)
- [Required Context](#-required-context)
- [Feature Overview](#-feature-overview)
- [Tasks](#-tasks)
  - [Task 1: Verify Docker](#task-1-verify-docker)
  - [Task 2: Test Local Stack](#task-2-test-local-stack)
  - [Task 3: Setup Clerk Account](#task-3-setup-clerk-account)
  - [Task 4: Setup Railway Project](#task-4-setup-railway-project)
  - [Task 5: Setup Vercel Project](#task-5-setup-vercel-project)
- [Phase Completion Checklist](#-phase-completion-checklist)
- [Common Issues](#-common-issues)
- [Next Phase](#next-phase)

---

## 🤖 AI Agent Instructions

**When starting this phase:**

1. Read the project structure: `docs/STRUCTURE.md`
2. Understand we're verifying local dev + setting up deployment accounts
3. Follow tasks sequentially
4. Stop at human checkpoints (marked with 🚨)

---

## 📚 Required Context

Read these files first:

- `docs/STRUCTURE.md` - Project layout
- `docs/web/00-OVERVIEW.md` - Overall architecture
- `build/env/README.md` - Environment configuration

---

## 🎯 Feature Overview

**What we're building:** Complete development and deployment environment

**Success criteria:**

- ✅ Local stack works (`just run-dev up`)
- ✅ Clerk account created with API keys
- ✅ Railway project created with PostgreSQL
- ✅ Vercel project created
- ✅ Environment variables configured

---

## 🔨 Tasks

### Task 1: Verify Docker (Estimated: 2 mins)

**Goal:** Docker is required for local development

**🚨 Human action required:** Start Docker Desktop if not running

```bash
# Check if Docker is running
docker ps

# If not running, start Docker Desktop
open -a Docker
```

**Validation:**

```bash
docker ps
# Should connect (empty list is fine)
```

---

### Task 2: Test Local Stack (Estimated: 5 mins)

**Goal:** Verify the full local development stack works

**Commands:**

```bash
# Start everything (db + migrations + api + web)
just run-dev up

# Check services
just run-dev logs

# Test endpoints
curl http://localhost:8000/health   # API
open http://localhost:3000          # Frontend
```

**Expected:**

- Database: `localhost:5432`
- API: `http://localhost:8000/health` returns "OK"
- Frontend: `http://localhost:3000` shows welcome page

**Stop stack when done:**

```bash
just run-dev down
```

---

### Task 3: Setup Clerk Account (Estimated: 10 mins)

**Goal:** Create Clerk account for authentication

**🚨 Human action required:** Create Clerk account and get API keys

**Instructions:**

1. Go to https://clerk.com
2. Sign up for free account
3. Create new application: "Thiccc Web"
4. Go to API Keys section
5. Copy:
   - Publishable Key (starts with `pk_test_`)
   - Secret Key (starts with `sk_test_`)

**Add keys to environment:**

```bash
# Edit build/env/common.env (gitignored)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxx
CLERK_SECRET_KEY=sk_test_xxxxx
```

**🚨 Human checkpoint:** Confirm Clerk keys are in `build/env/common.env`

---

### Task 4: Setup Railway Project (Estimated: 15 mins)

**Goal:** Create Railway project for backend + database hosting

**🚨 Human action required:** Create Railway account and project

#### Step 1: Create Railway Account & PostgreSQL

1. Go to https://railway.app
2. Sign up (GitHub or email)
3. Click **"New Project"** → **"Deploy PostgreSQL"**
4. Wait for PostgreSQL to deploy (shows "Online")
5. Click on Postgres → **Variables** tab → Copy `DATABASE_URL`

---

#### Step 2: Deploy API Server

**1. Install Railway CLI:**

```bash
brew install railway
```

**2. Initialize and link project:**

```bash
cd applications/thiccc

# Create new Railway project
railway init
# Name it: thiccc-api

# Deploy (auto-creates service from Dockerfile)
railway up

# Link to the created service
railway service link thiccc-api
```

**3. Set environment variables:**

```bash
railway variables set PORT=8000
railway variables set RUST_LOG=info
railway variables set DATABASE_URL="<paste-postgres-url>"
```

**4. Generate public domain:**

```bash
railway domain
```

**5. Future deploys:**

```bash
just deploy api
```

---

#### Step 3: Run Migrations

```bash
# Requires sqlx-cli: cargo install sqlx-cli --no-default-features --features native-tls,postgres
just deploy db
```

---

#### Step 4: Verify Deployment

Test the health endpoints:

```bash
curl https://thiccc-api-production.up.railway.app/health
# Should return: OK

curl https://thiccc-api-production.up.railway.app/api/health
# Should return: {"status":"healthy","database":"connected"}
```

---

**🚨 Human checkpoint:**

- Railway project created
- PostgreSQL service running (shows "Online")
- API service deployed (check logs for errors)
- Health endpoints respond
- Migrations run successfully

---

### Task 5: Setup Vercel Project (Estimated: 10 mins)

**Goal:** Create Vercel project for frontend hosting

**🚨 Human action required:** Create Vercel account and deploy

**1. Install Vercel CLI:**

```bash
brew install vercel-cli
```

**2. Login to Vercel:**

```bash
vercel login
```

**3. Deploy from web_frontend directory:**

```bash
cd applications/thiccc/web_frontend

# First deploy (will prompt for project setup)
vercel

# Follow prompts:
# - Set up and deploy? Y
# - Which scope? (select your account)
# - Link to existing project? N
# - Project name? thiccc
# - Directory with code? ./
# - Override settings? N
```

**4. Set environment variables:**

```bash
vercel env add NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
vercel env add CLERK_SECRET_KEY
vercel env add NEXT_PUBLIC_API_URL
```

**5. Deploy to production:**

```bash
just deploy web prod
```

---

**🚨 Human checkpoint:**

- Vercel project created
- Environment variables configured
- Deployment succeeds

---

## ✅ Phase Completion Checklist

- [x] Docker running
- [x] Local stack works (`just run-dev up`)
- [x] Clerk account created with API keys
- [x] Keys added to `build/env/common.env`
- [x] Railway CLI installed (`brew install railway`)
- [x] Railway project created
- [x] Railway PostgreSQL service running
- [x] Railway API service deployed
- [x] Railway environment variables set
- [x] Production migrations run (`just deploy db`)
- [x] Vercel CLI installed (`brew install vercel-cli`)
- [x] Vercel project created and deployed
- [x] Vercel environment variables set
- [x] Both services deploy successfully
- [x] Health endpoints respond

**API URL:** https://thiccc-api-production.up.railway.app
**Web URL:** https://thiccc.vercel.app

---

## 🚨 Common Issues

### Issue: Docker not running

**Symptom:** `Cannot connect to Docker daemon`

**Solution:**

```bash
open -a Docker
# Wait 30 seconds, then retry
```

### Issue: Port already in use

**Symptom:** `Address already in use`

**Solution:**

```bash
# Stop any existing stack
just run-dev down

# Or find and kill process
lsof -i :8000
kill -9 <PID>
```

### Issue: Railway build fails

**Symptom:** Cargo can't find workspace or dependencies

**Solution:**

1. Ensure you're in `applications/thiccc/` directory when running `railway up`
2. Check that `railway.toml` and `api_server/Dockerfile` exist
3. Verify Rust version in Dockerfile matches your local version

### Issue: Railway CLI not found

**Symptom:** `railway: command not found`

**Solution:**

```bash
brew install railway
```

### Issue: Railway deploy times out

**Symptom:** Build takes too long and fails

**Solution:** Rust builds can be slow. Railway's free tier has build time limits. If this happens:

1. Try deploying during off-peak hours
2. Consider upgrading to a paid plan
3. Subsequent builds are faster due to caching

### Issue: Vercel build fails

**Symptom:** Next.js build errors

**Solution:**

1. Check environment variables are set: `vercel env ls`
2. Ensure you're in the `web_frontend` directory
3. Check for missing Clerk keys

### Issue: Vercel CLI not found

**Symptom:** `vercel: command not found`

**Solution:**

```bash
brew install vercel-cli
```

### Issue: sqlx-cli not found

**Symptom:** `sqlx: command not found` when running migrations

**Solution:**

```bash
cargo install sqlx-cli --no-default-features --features native-tls,postgres
```

---

## 📊 Progress Tracking

| Task                | Status | Type      | Notes                   |
| ------------------- | ------ | --------- | ----------------------- |
| 1. Verify Docker    | ✅     | Human     | Docker Desktop running  |
| 2. Test Local Stack | ✅     | AI can do | `just run-dev up` works |
| 3. Clerk Account    | ✅     | Human     | Keys in common.env      |
| 4. Railway Project  | ✅     | Human     | API + DB deployed       |
| 5. Vercel Project   | ✅     | Human     | Frontend deployed       |

**Legend:** ⬜ Not started | ⏳ In progress | ✅ Done | ❌ Blocked

---

## Next Phase

**Phase 1 is complete!** 🎉

Proceed to: **Phase 2: Authentication** (`02-PHASE-2-AUTH.md`)

### Quick Reference - Deployment Commands

```bash
# Production deployment
just deploy api          # Deploy API to Railway
just deploy web          # Deploy web to Vercel (preview)
just deploy web prod     # Deploy web to Vercel (production)
just deploy db           # Run migrations on Railway

# Local development
just run-dev up          # Start local stack
just run-dev down        # Stop local stack
just run-dev logs        # View logs
just run-dev reset       # Reset (wipes database)

# Cleanup
just clean               # Clean build artifacts
```
