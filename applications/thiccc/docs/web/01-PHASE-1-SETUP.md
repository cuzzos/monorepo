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

**Instructions:**

1. Go to https://railway.app
2. Sign up with GitHub account
3. Click "New Project" → "Deploy PostgreSQL"
4. Once created, click "Add Service" → "GitHub Repo"
5. Select `cuzzo_monorepo` repository
6. Configure the service:
   - **Root Directory:** `applications/thiccc`
   - **Build Command:** `cargo build --release -p thiccc-api`
   - **Start Command:** `./target/release/thiccc-api`

**Configure Environment Variables (in Railway dashboard):**

For the **API service:**

```
PORT=8000
RUST_LOG=info
DATABASE_URL=<auto-linked from PostgreSQL service>
CLERK_SECRET_KEY=<from Clerk dashboard>
```

For the **PostgreSQL service:**

- Railway auto-configures this, just note the `DATABASE_URL`

**Run migrations:**

```bash
# Get the production DATABASE_URL from Railway dashboard
DATABASE_URL=<railway-url> just thiccc db migrate
```

**🚨 Human checkpoint:**

- Railway project created
- PostgreSQL service running
- API service configured (may not deploy yet - that's ok)
- Migrations run against production DB

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
- [ ] Railway project created
- [ ] Railway PostgreSQL service running
- [ ] Railway API service configured
- [ ] Production migrations run
- [ ] Vercel CLI installed (`brew install vercel-cli`)
- [ ] Vercel project created and deployed
- [ ] Vercel environment variables set
- [ ] Both services deploy successfully

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

**Symptom:** Cargo can't find workspace

**Solution:** Ensure Root Directory is set to `applications/thiccc` (not `applications/thiccc/api_server`)

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
