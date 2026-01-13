# Feature Flags System

Feature flags allow selective feature access based on user roles or other criteria.

## Overview

Feature flags enable:
- Admin-only features in production
- Beta testing new features
- Gradual rollouts
- A/B testing (future)

## Implementation

### Frontend Hook

`web_frontend/lib/feature-flags.ts`:

```typescript
import { useUser } from '@clerk/nextjs';

export function useFeatureFlag(flag: string): boolean {
  const { user } = useUser();
  
  if (!user) return false;
  
  const roles = (user.publicMetadata?.roles as string[]) || [];
  const betaTester = user.publicMetadata?.betaTester as boolean;
  
  const flags: Record<string, boolean> = {
    // Admin-only features
    'debug-panel': roles.includes('admin'),
    'admin-dashboard': roles.includes('admin'),
    'system-stats': roles.includes('admin'),
    
    // Trainer features
    'trainer-dashboard': roles.includes('admin') || roles.includes('trainer'),
    'client-management': roles.includes('admin') || roles.includes('trainer'),
    
    // Beta features
    'analytics-v2': betaTester === true,
    'workout-templates': betaTester === true,
    
    // Always on
    'basic-workouts': true,
  };
  
  return flags[flag] ?? false;
}
```

### Usage in Components

```typescript
import { useFeatureFlag } from '@/lib/feature-flags';

export function DebugPanel() {
  const showDebug = useFeatureFlag('debug-panel');
  
  if (!showDebug) return null;
  
  return <div>Debug panel content...</div>;
}
```

### Usage in Routes

```typescript
// app/(admin)/layout.tsx
import { useFeatureFlag } from '@/lib/feature-flags';
import { redirect } from 'next/navigation';

export default function AdminLayout({ children }) {
  const isAdmin = useFeatureFlag('admin-dashboard');
  
  if (!isAdmin) {
    redirect('/dashboard');
  }
  
  return <div>{children}</div>;
}
```

## Available Flags

### Admin Flags

| Flag | Description | Required Role |
|------|-------------|---------------|
| `debug-panel` | Debug panel (Cmd+Shift+D) | admin |
| `admin-dashboard` | Admin dashboard access | admin |
| `system-stats` | System statistics | admin |

### Trainer Flags

| Flag | Description | Required Role |
|------|-------------|---------------|
| `trainer-dashboard` | Trainer dashboard | admin, trainer |
| `client-management` | Manage clients | admin, trainer |

### Beta Flags

| Flag | Description | Enabled By |
|------|-------------|-----------|
| `analytics-v2` | New analytics dashboard | betaTester: true |
| `workout-templates` | Workout templates | betaTester: true |

### Always On

| Flag | Description |
|------|-------------|
| `basic-workouts` | Core workout features |

## Setting User Metadata

### Via Clerk Dashboard (Human)

1. Go to Clerk dashboard
2. Users → Select user
3. Metadata → Public metadata
4. Set JSON:
```json
{
  "roles": ["admin"],
  "betaTester": true
}
```

**Note:** `roles` is an array. A user can have multiple roles:
- Admin only: `["admin"]`
- Trainer only: `["trainer"]`
- Both admin and trainer: `["admin", "trainer"]`
- Regular user: `["user"]` or `[]`

### Via Backend (Programmatic)

Future: Admins can change user roles via admin dashboard.

```rust
// Backend endpoint: POST /api/admin/users/:id/roles
async fn update_user_roles(
    user_id: String,
    new_roles: Vec<String>,
) -> Result<(), Error> {
    // Update via Clerk Management API
    clerk_client.update_user_metadata(user_id, json!({
        "roles": new_roles
    })).await?;
    
    Ok(())
}
```

## Security

### Frontend Checks (UX Only)

Frontend feature flags are **NOT security**. They only hide UI.

A malicious user could:
- Modify client code
- Call protected API endpoints directly

**Never rely on frontend flags for security.**

### Backend Enforcement

**Always check permissions in backend:**

```rust
// api_server/src/middleware/admin.rs
pub async fn require_admin(
    Extension(user): Extension<User>,
) -> Result<(), ApiError> {
    if !user.roles.contains(&"admin".to_string()) {
        return Err(ApiError::Forbidden);
    }
    Ok(())
}
```

Apply middleware to protected routes:
```rust
Router::new()
    .route("/api/admin/users", get(list_users))
    .layer(middleware::from_fn(require_admin))
```

## Debug Panel Feature Flag

### Keyboard Shortcut

`web_frontend/components/DebugPanel.tsx`:

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useFeatureFlag } from '@/lib/feature-flags';

export function DebugPanel() {
  const [isOpen, setIsOpen] = useState(false);
  const canAccess = useFeatureFlag('debug-panel');
  
  useEffect(() => {
    const handleKeyPress = (e: KeyboardEvent) => {
      // Cmd+Shift+D or Ctrl+Shift+D
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === 'D') {
        e.preventDefault();
        if (canAccess) {
          setIsOpen(prev => !prev);
        }
      }
    };
    
    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [canAccess]);
  
  if (!canAccess || !isOpen) return null;
  
  return (
    <div className="fixed bottom-4 right-4 w-96 h-96 bg-white shadow-xl rounded-lg">
      {/* Debug panel content */}
    </div>
  );
}
```

### Mount in Layout

```typescript
// app/layout.tsx
import { DebugPanel } from '@/components/DebugPanel';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <DebugPanel />
      </body>
    </html>
  );
}
```

**Result:** Admin users can press Cmd+Shift+D anywhere in the app (even in production) to open debug panel.

## Future Enhancements

### Server-Side Flags

**What are they?**

Server-side flags store feature toggle configuration in the database instead of relying only on user roles. This provides much more control over who sees features and when.

**When to use:**
- ✅ Gradual rollouts (10% → 50% → 100% of users)
- ✅ Beta testing (enable for specific users)
- ✅ Emergency kill switches (disable broken features instantly)
- ✅ A/B testing different features
- ✅ Features that need instant toggle without deploy

**Schema:**

```sql
CREATE TABLE feature_flags (
    flag_name TEXT PRIMARY KEY,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    enabled_for_roles TEXT[],
    enabled_for_users TEXT[],
    rollout_percentage INTEGER CHECK (rollout_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_feature_flags_enabled ON feature_flags(enabled);
```

**Field Explanations:**

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `flag_name` | TEXT | Unique identifier | `'workout_analytics'` |
| `enabled` | BOOLEAN | Global on/off | `true` = available, `false` = disabled for everyone |
| `enabled_for_roles` | TEXT[] | Roles that get access | `['admin', 'trainer']` |
| `enabled_for_users` | TEXT[] | Specific users (beta testers) | `['user_abc', 'user_xyz']` |
| `rollout_percentage` | INTEGER | % of users who see it | `10` = 10% of users randomly selected |

**Evaluation Logic:**

```typescript
function isFeatureEnabled(
  flagName: string, 
  user: { id: string; roles: string[] }
): boolean {
  const flag = getFeatureFlag(flagName);
  
  // 1. Check if feature is globally disabled
  if (!flag.enabled) return false;
  
  // 2. Check if user's role has access
  if (flag.enabled_for_roles?.some(role => user.roles.includes(role))) {
    return true;
  }
  
  // 3. Check if specific user has access
  if (flag.enabled_for_users?.includes(user.id)) {
    return true;
  }
  
  // 4. Check rollout percentage
  if (flag.rollout_percentage != null) {
    const hash = hashUserId(user.id); // Consistent hash
    return (hash % 100) < flag.rollout_percentage;
  }
  
  return false;
}
```

**Use Cases:**

**1. Gradual Rollout:**
```sql
-- Start: Enable for 10% of users
INSERT INTO feature_flags (flag_name, enabled, rollout_percentage)
VALUES ('workout_analytics', true, 10);

-- Monitor metrics, watch for errors...

-- Increase to 50%
UPDATE feature_flags 
SET rollout_percentage = 50 
WHERE flag_name = 'workout_analytics';

-- Finally: 100%
UPDATE feature_flags 
SET rollout_percentage = 100 
WHERE flag_name = 'workout_analytics';
```

**2. Beta Testing:**
```sql
-- Enable only for specific beta testers
INSERT INTO feature_flags (flag_name, enabled, enabled_for_users)
VALUES ('ai_workout_planner', true, ARRAY['user_abc', 'user_xyz', 'user_123']);

-- Add more users as they sign up for beta
UPDATE feature_flags 
SET enabled_for_users = array_append(enabled_for_users, 'user_new')
WHERE flag_name = 'ai_workout_planner';
```

**3. Role-Based Access:**
```sql
-- Enable for trainers only
INSERT INTO feature_flags (flag_name, enabled, enabled_for_roles)
VALUES ('client_management', true, ARRAY['trainer', 'admin']);
```

**4. Emergency Kill Switch:**
```sql
-- Bug found in production? Disable instantly without deploy
UPDATE feature_flags 
SET enabled = false 
WHERE flag_name = 'broken_feature';
```

**5. Combination:**
```sql
-- Enable for all admins + 25% of regular users
INSERT INTO feature_flags (
  flag_name, 
  enabled, 
  enabled_for_roles, 
  rollout_percentage
)
VALUES ('new_ui', true, ARRAY['admin'], 25);
```

**Implementation:**

**Backend API:**
```typescript
// GET /api/feature-flags (for current user)
app.get('/api/feature-flags', async (req, res) => {
  const user = req.user; // from auth middleware
  const flags = await db.query('SELECT * FROM feature_flags WHERE enabled = true');
  
  const enabledFlags = flags
    .filter(flag => isFeatureEnabled(flag, user))
    .map(flag => flag.flag_name);
  
  res.json({ flags: enabledFlags });
});
```

**Frontend:**
```typescript
// Fetch on app load
const { data: enabledFlags } = useQuery('featureFlags', fetchFeatureFlags);

// Check in components
if (enabledFlags.includes('workout_analytics')) {
  return <WorkoutAnalytics />;
}
```

**Advantages over Role-Only Flags:**

| Feature | Role-Based | Server-Side Flags |
|---------|------------|-------------------|
| Instant toggle | ❌ Need deploy | ✅ Database update |
| Gradual rollout | ❌ All or nothing | ✅ Percentage-based |
| Beta testing | ❌ Hard to target | ✅ Easy user list |
| A/B testing | ❌ Not possible | ✅ Built-in |
| Emergency disable | ❌ Need deploy | ✅ Instant |
| Overhead | ✅ Zero | ⚠️ DB query per request |

**When NOT to use:**

- ❌ Simple role checks (e.g., admin-only pages) - use `user.roles` directly
- ❌ Permanent features - just deploy them
- ❌ Performance-critical paths - caching required

**Caching Strategy:**

```typescript
// Cache flags for 1 minute to reduce DB load
const flagCache = new Map<string, { flags: FeatureFlag[], expiry: number }>();

async function getFeatureFlags(): Promise<FeatureFlag[]> {
  const cached = flagCache.get('all');
  if (cached && Date.now() < cached.expiry) {
    return cached.flags;
  }
  
  const flags = await db.query('SELECT * FROM feature_flags WHERE enabled = true');
  flagCache.set('all', { flags, expiry: Date.now() + 60000 }); // 1 min
  return flags;
}
```

**Best Practices:**

1. **Seed common flags:**
```sql
INSERT INTO feature_flags (flag_name, enabled, enabled_for_roles) VALUES
('debug_panel', true, ARRAY['admin']),
('admin_dashboard', true, ARRAY['admin']),
('trainer_tools', true, ARRAY['trainer', 'admin']);
```

2. **Use consistent naming:**
- Format: `feature_name` (lowercase, underscores)
- Group: `analytics_*`, `admin_*`, `beta_*`

3. **Document flags:**
```sql
ALTER TABLE feature_flags ADD COLUMN description TEXT;

UPDATE feature_flags 
SET description = 'Advanced workout analytics with charts and trends'
WHERE flag_name = 'workout_analytics';
```

4. **Audit changes:**
```sql
CREATE TABLE feature_flag_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flag_name TEXT NOT NULL,
    changed_by TEXT NOT NULL,
    previous_state JSONB,
    new_state JSONB,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

5. **Clean up old flags:**
```sql
-- Remove flags for fully rolled-out features
DELETE FROM feature_flags WHERE flag_name = 'old_feature';
-- (Then remove the flag checks from code)
```

**Phase:** 4 (Admin Dashboard) - Add UI to manage flags

---

### A/B Testing

Randomly assign users to variants:

```typescript
export function useFeatureVariant(flag: string): 'A' | 'B' {
  const { user } = useUser();
  
  // Hash user ID to consistently assign variant
  const hash = hashCode(user?.id || '');
  return hash % 2 === 0 ? 'A' : 'B';
}
```

### Analytics Integration

Track feature usage:

```typescript
export function useFeatureFlag(flag: string): boolean {
  const enabled = /* ... check flag ... */;
  
  useEffect(() => {
    if (enabled) {
      analytics.track('feature_accessed', { flag });
    }
  }, [enabled, flag]);
  
  return enabled;
}
```

## Testing

### Test with Different Roles

```typescript
// Mock Clerk user in tests
const mockUser = {
  id: 'test_user',
  publicMetadata: {
    roles: ['admin'], // Change this to test different roles
  },
};

// Test component
render(<DebugPanel />, {
  wrapper: ({ children }) => (
    <ClerkProvider user={mockUser}>
      {children}
    </ClerkProvider>
  ),
});
```

### Integration Tests

```typescript
describe('Feature Flags', () => {
  it('shows debug panel for admins', async () => {
    loginAs('admin');
    await page.keyboard.press('Meta+Shift+D');
    expect(await page.locator('[data-testid="debug-panel"]').isVisible()).toBe(true);
  });
  
  it('does not show debug panel for regular users', async () => {
    loginAs('user');
    await page.keyboard.press('Meta+Shift+D');
    expect(await page.locator('[data-testid="debug-panel"]').isVisible()).toBe(false);
  });
});
```

## Summary

**Key points:**
- Feature flags control UI visibility
- Backend enforces actual permissions
- Admin features work in production
- Debug panel accessible via Cmd+Shift+D (admins only)
- Flags stored in Clerk user metadata (public metadata)
- Easy to extend with new flags

