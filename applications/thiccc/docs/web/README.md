# Thiccc Web Documentation - Index

> **TLDR:** Central navigation hub for thiccc web app documentation. Contains links to all phase guides (0-10), reference docs (API, database, feature flags), Dagger toolchains, and quick commands for developers and AI agents. Start here to find everything.

## Table of Contents
- [Getting Started](#-getting-started)
- [Phase Documentation](#-phase-documentation)
- [Reference Documentation](#-reference-documentation)
- [AI Agent Guides](#-ai-agent-guides)
- [Dagger Devtools](#-dagger-devtools)
- [Quick Commands](#-quick-commands)
- [Project Structure](#-project-structure)
- [External Links](#-external-links)
- [FAQ](#-faq)
- [Deployment URLs](#-deployment-urls)
- [Progress Tracking](#-progress-tracking)
- [Contributing](#-contributing)
- [Support](#-support)

---

Welcome to the thiccc web application documentation. This index helps you find what you need.

---

## 📖 Getting Started

**New to the project? Start here:**

1. **[00-OVERVIEW.md](00-OVERVIEW.md)** - Project overview, tech stack, architecture
2. **[01-PHASE-1-SETUP.md](01-PHASE-1-SETUP.md)** - Development environment setup
3. **[/docs/dagger/QUICKSTART.md](/docs/dagger/QUICKSTART.md)** - Install Dagger CLI

---

## 🏗️ Phase Documentation

Build the web app in phases:

| Phase | Document | Description | Status |
|-------|----------|-------------|--------|
| 0 | [00-OVERVIEW.md](00-OVERVIEW.md) | Architecture & tech stack | ✅ |
| 1 | [01-PHASE-1-SETUP.md](01-PHASE-1-SETUP.md) | Dev environment, Dagger, accounts | ⬜ |
| 2 | [02-PHASE-2-AUTH.md](02-PHASE-2-AUTH.md) | Clerk authentication | ⬜ |
| 3 | [03-PHASE-3-CORE-API.md](03-PHASE-3-CORE-API.md) | Database & API foundation | ⬜ |
| 4 | [04-PHASE-4-ADMIN-DEBUG.md](04-PHASE-4-ADMIN-DEBUG.md) | Admin dashboard & debug panel | ⬜ |
| 5 | [05-PHASE-5-WORKOUTS.md](05-PHASE-5-WORKOUTS.md) | Workout CRUD operations | ⬜ |
| 6-10 | [06-10-REMAINING-PHASES.md](06-10-REMAINING-PHASES.md) | Tracking, analytics, trainer, planning, polish | ⬜ |

**Legend:** ✅ Complete | ⏳ In Progress | ⬜ Not Started

---

## 📚 Reference Documentation

Technical specifications:

- **[reference/API-SPEC.md](reference/API-SPEC.md)** - Complete API endpoint reference
- **[reference/DATABASE-SCHEMA.md](reference/DATABASE-SCHEMA.md)** - Database tables and migrations
- **[reference/FEATURE-FLAGS.md](reference/FEATURE-FLAGS.md)** - Feature flag system (debug panel, admin features)

---

## 🤖 AI Agent Guides

Documentation for AI agents building features:

- **[/docs/dagger/AI-AGENT-GUIDE.md](/docs/dagger/AI-AGENT-GUIDE.md)** - How AI agents use Dagger
- **[/docs/dagger/TOOLCHAINS.md](/docs/dagger/TOOLCHAINS.md)** - Available Dagger commands

---

## 🛠️ Dagger Devtools

Containerized development tools:

- **[/docs/dagger/QUICKSTART.md](/docs/dagger/QUICKSTART.md)** - Install and setup Dagger
- **[/docs/dagger/TOOLCHAINS.md](/docs/dagger/TOOLCHAINS.md)** - All available toolchains

---

## 🎯 Quick Commands

### For Developers

```bash
# Start backend
dagger call rust-serve --source=applications/thiccc/api_server --port=8000

# Start frontend
dagger call node-dev --source=applications/thiccc/web_frontend --port=3000

# Run tests
dagger call rust-test --source=applications/thiccc/api_server
dagger call node-test --source=applications/thiccc/web_frontend
```

### For AI Agents

When user says "Start working on Phase X":

1. Read: `applications/thiccc/docs/web/0X-PHASE-X-[NAME].md`
2. Read all files in "Required Context" section
3. Follow tasks sequentially
4. Use Dagger commands for validation
5. Stop at human checkpoints

---

## 📁 Project Structure

```
applications/thiccc/
├── shared/              # Rust core (business logic)
├── shared_types/        # Type generation (Rust → TypeScript)
├── ios/                 # iOS app
├── web_frontend/        # Web client (Next.js + TypeScript)
└── api_server/          # Shared API (Rust API, serves iOS + Web)
└── docs/
    └── web/             # This documentation
        ├── 00-OVERVIEW.md
        ├── 01-PHASE-1-SETUP.md
        ├── ...
        └── reference/
```

---

## 🔗 External Links

- **Clerk:** https://clerk.com (authentication)
- **Railway:** https://railway.app (backend hosting)
- **Vercel:** https://vercel.com (frontend hosting)
- **Next.js:** https://nextjs.org
- **Axum:** https://docs.rs/axum
- **Dagger:** https://dagger.io

---

## ❓ FAQ

### When should I use Dagger vs local tools?

**Always use Dagger.** AI agents and developers should use Dagger commands for consistency.

### Where is the Rust business logic?

In `applications/thiccc/shared/`. The web backend imports this as a dependency.

### How do TypeScript types get generated?

From `shared_types/` which reads Rust structs and generates TypeScript automatically.

### Can I test the API without the frontend?

Yes! Use `curl`, `httpie`, or tools like Postman:
```bash
curl -H "Authorization: Bearer $JWT" http://localhost:8000/api/me
```

### How do I deploy?

Just push to `main` branch:
- Vercel auto-deploys frontend
- Railway auto-deploys backend

### How do I access the debug panel?

Press `Cmd+Shift+D` (requires admin role).

---

## 🚀 Deployment URLs

**Development:**
- Frontend: http://localhost:3000
- Backend: http://localhost:8000

**Production:**
- Frontend: https://thiccc.app (Vercel)
- Backend: https://api.thiccc.app (Railway)

---

## 📊 Progress Tracking

Use this space to track overall progress:

- [ ] Phase 1: Setup
- [ ] Phase 2: Auth
- [ ] Phase 3: Core API
- [ ] Phase 4: Admin + Debug
- [ ] Phase 5: Workouts
- [ ] Phase 6: Tracking
- [ ] Phase 7: Analytics
- [ ] Phase 8: Trainer
- [ ] Phase 9: Planning
- [ ] Phase 10: Polish

**Target:** 13 weeks to production MVP

---

## 📝 Contributing

When adding new features:

1. Create new phase document (if major feature)
2. Update API-SPEC.md with new endpoints
3. Update DATABASE-SCHEMA.md if schema changes
4. Update this index if adding new docs

---

## 🆘 Support

**Questions?**
- Check phase documentation
- Check reference documentation
- Check Dagger guides
- Ask human for clarification

**Issues?**
- Check "Common Issues" section in phase docs
- Check Dagger troubleshooting
- Use debug panel (if admin)

