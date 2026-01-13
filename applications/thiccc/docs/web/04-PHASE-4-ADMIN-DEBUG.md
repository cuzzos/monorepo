# Phase 4: Admin Dashboard & Debug Panel

## 🤖 AI Agent Instructions

**When starting this phase:**
1. Read all files in "Required Context" section below
2. Understand we're building admin-only features with feature flags
3. Follow tasks sequentially
4. Validate each step before proceeding
5. Stop at human checkpoints (marked with 🚨)

---

## 📚 Required Context

Auto-read these files before starting:

### Previous phases
- `@applications/thiccc/docs/web/03-PHASE-3-CORE-API.md` - Core API

### iOS debug reference
- `@applications/thiccc/docs/DATABASE-VERIFICATION-DEBUG-TAB.md` - iOS debug panel pattern

### Backend patterns
- `@applications/thiccc/api_server/src/routes/users.rs` - Users endpoint

---

## 🎯 Feature Overview

**What we're building:** Admin dashboard and debug panel (feature flag enabled)

**Why:** 
- Admins need to manage users and view system health
- Debug panel helps troubleshoot issues in production
- Feature flags allow selective access even in deployed app

**Success criteria:**
- ✅ Feature flag system works (admin role check)
- ✅ Admin dashboard shows user list
- ✅ Debug panel accessible with Cmd+Shift+D (admin only)
- ✅ Debug panel shows API logs, state, database queries
- ✅ `/admin/*` routes protected by role check
- ✅ Backend has admin-only endpoints
- ✅ All tests passing

---

## 🔨 Tasks

### Task 1: Add Role to User Metadata (Estimated: 15 mins)

**Goal:** Store user roles in Clerk

**🚨 Human action required:** User must set own role to "admin" in Clerk dashboard

Steps for human:
1. Go to Clerk dashboard
2. Users → Select your user
3. Metadata → Public metadata
4. Add: `{ "roles": ["admin"] }`
5. Save

---

### Task 2: Create Feature Flag System (Estimated: 25 mins)

**Goal:** Check feature access based on user role

Create `web_frontend/lib/feature-flags.ts`:
- `useFeatureFlag(flag: string)` hook
- Checks user metadata for roles (array)
- Returns boolean

Flags:
- `debug-panel` - Admin only
- `admin-dashboard` - Admin only

---

### Task 3: Create Debug Panel Component (Estimated: 45 mins)

**Goal:** Floating debug panel (admin only, works in prod)

Create `web_frontend/components/DebugPanel.tsx`:

Features:
- Keyboard shortcut: Cmd+Shift+D to toggle
- Tabs: API Logs, State Inspector, Database, Auth
- API Logs: Show all fetch requests/responses
- State Inspector: React Query cache, Clerk session
- Database: Quick SQL queries (admin only)
- Auth: View JWT token, user metadata

Only renders if `useFeatureFlag('debug-panel')` returns true.

---

### Task 4: Add API Request Logging (Estimated: 20 mins)

**Goal:** Track all API calls for debug panel

Create context to capture all fetch requests.

Store in memory (last 50 requests).

Display in debug panel.

---

### Task 5: Create Admin Layout (Estimated: 20 mins)

**Goal:** Separate layout for admin pages

Create `web_frontend/app/(admin)/layout.tsx`:
- Checks admin role
- Redirects non-admins
- Admin navigation sidebar

---

### Task 6: Create Admin Dashboard Page (Estimated: 30 mins)

**Goal:** Show system overview

Create `web_frontend/app/(admin)/admin/page.tsx`:
- User count
- Workout count
- Recent activity
- System health

---

### Task 7: Create Admin Users Page (Estimated: 40 mins)

**Goal:** List all users, view details

Create `web_frontend/app/(admin)/admin/users/page.tsx`:
- Table of all users
- Search/filter
- View user workouts
- Ability to change roles (via Clerk)

Backend endpoint: `GET /api/admin/users`

---

### Task 8: Add Admin Role Middleware to Backend (Estimated: 20 mins)

**Goal:** Protect admin endpoints

Create `api_server/src/middleware/admin.rs`:
- Extract role from JWT
- Return 403 if not admin

Apply to all `/api/admin/*` routes.

---

## ✅ Phase Completion Checklist

- [ ] Feature flag system works
- [ ] Debug panel accessible (Cmd+Shift+D)
- [ ] Debug panel shows API logs
- [ ] Debug panel shows React Query state
- [ ] Admin dashboard accessible
- [ ] Admin users page works
- [ ] Backend admin endpoints protected
- [ ] Non-admins get 403 on admin routes
- [ ] All tests passing
- [ ] Debug panel works in production (Railway/Vercel)

---

## 🚨 Common Issues

### Issue: Debug panel not showing

**Symptom:** Cmd+Shift+D does nothing

**Solution:** 
1. Check user has `roles: ["admin"]` in Clerk metadata
2. Check console for feature flag errors
3. Verify `useFeatureFlag('debug-panel')` returns true

### Issue: Admin routes accessible by non-admins

**Symptom:** Non-admin users can view admin pages

**Solution:** 
1. Check admin middleware is applied to routes
2. Verify JWT includes roles in claims
3. Check Clerk public metadata is synced

---

## 🔗 Dependencies

**Requires:**
- Phase 3: Core API (needs user endpoints)

**Blocks:**
- Phase 5: Workouts (admin can test features)

---

## Next Phase

Once complete, proceed to:
**Phase 5: Workouts CRUD** (`05-PHASE-5-WORKOUTS.md`)

