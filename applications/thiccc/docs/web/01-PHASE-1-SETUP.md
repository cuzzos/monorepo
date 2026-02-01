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

- ✅ Local stack works (`just thiccc web up`)
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
just thiccc web up

# Check services
just thiccc web logs

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
just thiccc web down
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

Choose **Option A (CLI)** or **Option B (GitHub)**:

##### Option A: Railway CLI (Recommended for Monorepos)

**1. Install Railway CLI:**

```bash
brew install railway
```

**2. Login and link project:**

```bash
railway login

# From api_server directory
cd applications/thiccc/api_server
railway link
# Select your project (e.g., "astonishing-miracle")
# Select "Create new service" when prompted
```

**3. Set environment variables:**

```bash
railway variables set PORT=8000
railway variables set RUST_LOG=info
railway variables set CLERK_SECRET_KEY=sk_test_xxxxx
railway variables set DATABASE_URL="<paste-postgres-url>"
```

**4. Deploy:**

```bash
railway up
```

**Future deploys:**

```bash
cd applications/thiccc/api_server
railway up
```

---

##### Option B: Connect GitHub Repo

1. In Railway dashboard, click **"+ New"** → **"GitHub Repo"**
2. Select `cuzzo_monorepo` repository
3. Configure the service:
   - **Root Directory:** `applications/thiccc/api_server`
   - Railway will auto-detect Rust and use `railway.toml`
4. Add environment variables in **Variables** tab:
   ```
   PORT=8000
   RUST_LOG=info
   CLERK_SECRET_KEY=sk_test_xxxxx
   ```
5. For `DATABASE_URL`, click **"Add Reference"** → Select Postgres service

---

#### Step 3: Run Migrations

```bash
# From applications/thiccc directory
DATABASE_URL="<railway-postgres-url>" just thiccc db migrate
```

Or if you don't have the `db migrate` recipe:

```bash
cd applications/thiccc
DATABASE_URL="<railway-postgres-url>" sqlx migrate run --source db/migrations
```

---

#### Step 4: Verify Deployment

Once deployed, test the health endpoint:

```bash
curl https://<your-railway-url>/health
# Should return: OK

curl https://<your-railway-url>/api/health
# Should return: {"status":"healthy","database":"connected"}
```

Find your Railway URL in the dashboard under your API service → **Settings** → **Networking** → **Public Domain**.

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

#### Option A: Vercel CLI (Recommended for Monorepos)

Deploy directly without connecting your entire repo to Vercel.

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
# - Project name? thiccc-web
# - Directory with code? ./
# - Override settings? N
```

**4. Set environment variables:**

```bash
# Add each environment variable
vercel env add NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
vercel env add CLERK_SECRET_KEY
vercel env add NEXT_PUBLIC_API_URL
```

**5. Deploy to production:**

```bash
vercel --prod
```

**Future deploys:**

```bash
cd applications/thiccc/web_frontend
vercel --prod
```

---

#### Option B: Connect GitHub Repo

If you prefer automatic deploys on push:

1. Go to https://vercel.com
2. Sign up with GitHub account
3. Click "Add New Project"
4. Import `cuzzo_monorepo` repo
5. Configure:
   - **Framework Preset:** Next.js
   - **Root Directory:** `applications/thiccc/web_frontend`
6. Add Environment Variables:
   ```
   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxx
   CLERK_SECRET_KEY=sk_test_xxxxx
   NEXT_PUBLIC_API_URL=https://<your-railway-api-url>
   ```
7. Click "Deploy"

---

**🚨 Human checkpoint:**

- Vercel project created
- Environment variables configured
- Deployment succeeds (or shows what's missing)

---

## ✅ Phase Completion Checklist

- [ ] Docker running
- [ ] Local stack works (`just thiccc web up`)
- [ ] Clerk account created with API keys
- [ ] Keys added to `build/env/common.env`
- [ ] Railway CLI installed (`brew install railway`)
- [ ] Railway project created
- [ ] Railway PostgreSQL service running
- [ ] Railway API service deployed
- [ ] Railway environment variables set
- [ ] Production migrations run
- [ ] Vercel CLI installed (`brew install vercel-cli`)
- [ ] Vercel project created and deployed
- [ ] Vercel environment variables set
- [ ] Both services deploy successfully
- [ ] Health endpoints respond

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
just thiccc web down

# Or find and kill process
lsof -i :8000
kill -9 <PID>
```

### Issue: Railway build fails

**Symptom:** Cargo can't find workspace or dependencies

**Solution:**

1. If using CLI, ensure you're in `api_server/` directory when running `railway up`
2. If using GitHub, ensure Root Directory is `applications/thiccc/api_server`
3. Check that `railway.toml` exists in `api_server/`

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
3. Use GitHub integration (builds may be faster)

### Issue: Vercel build fails

**Symptom:** Next.js build errors

**Solution:**

1. Check environment variables are set: `vercel env ls`
2. If using CLI, ensure you're in the `web_frontend` directory
3. If using repo connection, ensure Root Directory is `applications/thiccc/web_frontend`

### Issue: Vercel CLI not found

**Symptom:** `vercel: command not found`

**Solution:**

```bash
brew install vercel-cli
```

---

## 📊 Progress Tracking

| Task                | Status | Type      | Notes                     |
| ------------------- | ------ | --------- | ------------------------- |
| 1. Verify Docker    | ⬜     | Human     | Start Docker Desktop      |
| 2. Test Local Stack | ⬜     | AI can do | Run just commands         |
| 3. Clerk Account    | ⬜     | Human     | Create account, get keys  |
| 4. Railway Project  | ⬜     | Human     | Create project, configure |
| 5. Vercel Project   | ⬜     | Human     | Install CLI, deploy       |

**Legend:** ⬜ Not started | ⏳ In progress | ✅ Done | ❌ Blocked

---

## Next Phase

Once this phase is complete, proceed to:
**Phase 2: Authentication** (`02-PHASE-2-AUTH.md`)
