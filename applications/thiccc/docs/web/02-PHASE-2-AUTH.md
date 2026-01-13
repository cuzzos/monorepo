# Phase 2: Authentication with Clerk

## 🤖 AI Agent Instructions

**When starting this phase:**
1. Read all files in "Required Context" section below
2. Understand we're implementing user signup, login, and JWT validation
3. Follow tasks sequentially
4. Validate each step before proceeding
5. Stop at human checkpoints (marked with 🚨)

**When stuck:**
- Check "Common Issues" section at bottom
- Ask human for clarification

---

## 📚 Required Context

Auto-read these files before starting:

### Previous phase
- `@applications/thiccc/docs/web/01-PHASE-1-SETUP.md` - Dev environment setup

### Clerk documentation
- Search web: "Clerk Next.js quickstart"
- Search web: "Clerk JWT validation Rust"

### Project files
- `@applications/thiccc/web_frontend/app/layout.tsx` - App layout
- `@applications/thiccc/api_server/src/main.rs` - Backend entry point

---

## 🎯 Feature Overview

**What we're building:** Complete authentication flow with Clerk

**Why:** Users need accounts to store workouts. Clerk handles signup, login, password reset, and JWT tokens.

**Success criteria:**
- ✅ Users can sign up with email/password
- ✅ Users can log in
- ✅ Protected routes require authentication
- ✅ Backend validates JWT tokens
- ✅ User profile page works
- ✅ Sign out works

---

## 🔨 Tasks

### Task 1: Install Clerk SDK in Frontend (Estimated: 10 mins)

**Goal:** Add Clerk React components to Next.js

**Implementation:**

Update `web_frontend/app/layout.tsx` to wrap app in ClerkProvider.

Add sign-in and sign-up pages.

**Validation:**
```bash
dagger call node-typecheck --source=applications/thiccc/web_frontend
dagger call node-build --source=applications/thiccc/web_frontend
```

---

### Task 2: Create Auth Pages (Estimated: 20 mins)

**Goal:** Add sign-up and sign-in pages

Create:
- `app/(auth)/sign-up/[[...sign-up]]/page.tsx`
- `app/(auth)/sign-in/[[...sign-in]]/page.tsx`

---

### Task 3: Protect Routes with Middleware (Estimated: 15 mins)

**Goal:** Require authentication for dashboard routes

Create `middleware.ts` to check auth status.

---

### Task 4: Add JWT Validation to Backend (Estimated: 30 mins)

**Goal:** Rust API validates Clerk JWT tokens

Create `api_server/src/middleware/auth.rs`.

Use `jsonwebtoken` crate to validate JWTs.

---

### Task 5: Create Protected Dashboard Page (Estimated: 20 mins)

**Goal:** User sees dashboard after login

Create `app/(dashboard)/dashboard/page.tsx`.

---

### Task 6: Add User Profile Dropdown (Estimated: 15 mins)

**Goal:** User can sign out and view profile

Add `UserButton` component from Clerk.

---

## ✅ Phase Completion Checklist

- [ ] Clerk SDK installed
- [ ] Sign-up page works
- [ ] Sign-in page works
- [ ] Protected routes redirect to sign-in
- [ ] Backend validates JWTs
- [ ] Dashboard shows after login
- [ ] User can sign out
- [ ] All tests passing

---

## 🚨 Common Issues

### Issue: Clerk middleware not working

**Symptom:** Protected routes accessible without login

**Solution:** Check `middleware.ts` config and matcher patterns.

### Issue: JWT validation fails

**Symptom:** Backend returns 401 Unauthorized

**Solution:** Verify CLERK_JWKS_URL is correct in `.env.local`.

---

## 🔗 Dependencies

**Requires:**
- Phase 1: Setup (Clerk account, API keys)

**Blocks:**
- Phase 3: Core API (needs auth middleware)

---

## Next Phase

Once complete, proceed to:
**Phase 3: Core API & Database** (`03-PHASE-3-CORE-API.md`)

