# Database Verification via Debug Tab

**Quick Reference:** Use the Debug tab in the iOS app to visually verify database initialization and status.

---

## 🎯 How to Verify Database is Working

### Step 1: Launch App in Simulator

```bash
cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc
make run-sim SIMULATOR='iPhone 17'
```

### Step 2: Navigate to Debug Tab

1. Open the app in simulator
2. Tap the **"Debug" tab** at the bottom of the screen
3. Look for the **"Database Status"** section

---

## ✅ What You Should See (Success)

### Database Status Section Should Show:

```
✓ Database Initialized

📁 Path: /Users/.../Application Support/thiccc.sqlite
📄 Size: 24 KB (or similar)

┌────────────────────────┐
│ 2         3        9    │
│ Workouts  Exercises Sets│
└────────────────────────┘

ℹ️ Sample data loaded (DEBUG build)
```

**Key Indicators:**
- ✅ Green checkmark with "Database Initialized"
- ✅ Database path shown
- ✅ File size shown (not 0)
- ✅ Workout/Exercise/Set counts > 0 (if DEBUG build with sample data)
- ✅ "Sample data loaded" message (DEBUG only)

---

## ❌ What You'll See (Failure)

### If Database Failed to Initialize:

```
⚠️ Database not initialized

[Refresh Stats button]
```

**Key Indicators:**
- ❌ Yellow warning triangle
- ❌ "Database not initialized" message
- ❌ No stats shown

**What to do:** Check Xcode console for error messages starting with `❌ [DatabaseManager]` or `❌ [Database]`

---

## 🧪 Interactive Database Tests

The Debug tab provides several buttons to test database operations:

### Database Actions Section:

1. **"Refresh Stats"** - Reloads database statistics
   - Use after completing a workout to verify it saved
   - Updates workout/exercise/set counts in real-time

2. **"Load History"** - Triggers database query
   - Loads all workouts from database
   - Updates "History Items" count in "Current State" section
   - Check result message at bottom

3. **"Show Database Path"** - Prints path to console
   - Useful for inspecting database with external tools
   - Path is also shown in the Database Status section

4. **"Query Database Directly"** - Raw SQL query
   - Bypasses Rust core, queries database directly
   - Prints results to Xcode console
   - Format: `Query: 2W, 3E, 9S` (Workouts, Exercises, Sets)

---

## 📊 Understanding the Stats

### Workout Count
- **What it means:** Number of completed workouts in database
- **Fresh install (DEBUG):** Should be 2 (sample data)
- **Fresh install (RELEASE):** Should be 0
- **After completing workout:** Should increment by 1

### Exercise Count
- **What it means:** Total exercises across all workouts
- **Sample data:** Should be 2-3
- **After completing workout:** Should match number of exercises you added

### Set Count
- **What it means:** Total sets across all exercises
- **Sample data:** Should be 6-9
- **After completing workout:** Should match total sets performed

### Has Sample Data (DEBUG only)
- **What it means:** Sample workouts were auto-inserted on first launch
- **Only in DEBUG builds:** Sample data helps with testing
- **RELEASE builds:** Will always be false (no sample data)

---

## 🔄 Testing the Complete Flow

### End-to-End Verification:

1. **Check initial state:**
   - Open Debug tab
   - Note current workout count (e.g., 2 with sample data)

2. **Complete a workout:**
   - Go to Workout tab
   - Tap "Start Workout"
   - Tap "Add Exercise" → Add "Bench Press"
   - Tap "+ Add Set" → Fill in 135 lbs, 10 reps
   - Check the set (mark complete)
   - Tap "Finish Workout"

3. **Verify database save:**
   - Go back to Debug tab
   - Tap "Refresh Stats"
   - **Expected:** Workout count increased by 1
   - **Expected:** Exercise count increased by 1  
   - **Expected:** Set count increased by 1

4. **Verify persistence:**
   - Force quit app (⌘. in Xcode or swipe up in simulator)
   - Relaunch app
   - Go to Debug tab
   - **Expected:** Stats match what you saw before (data persisted!)

5. **Verify history:**
   - Go to History tab
   - **Expected:** Your workout appears in the list
   - Tap on your workout
   - **Expected:** All details load correctly

---

## 🐛 Troubleshooting

### Database Status Shows "Not Initialized"

**Possible causes:**
1. DatabaseManager.shared.setup() failed in ThicccApp.init
2. GRDB not properly linked (build issue)
3. Permissions issue creating database file

**How to debug:**
1. Check Xcode console for errors starting with:
   - `❌ [ThicccApp] Database initialization failed`
   - `❌ [DatabaseManager] Setup failed`
2. Look for the database path in logs
3. Verify GRDB appears in Xcode project under "Frameworks"

### Stats Show All Zeros

**Possible causes:**
1. Database initialized but empty (normal for RELEASE build)
2. Sample data insertion failed (DEBUG builds)
3. Tables created but empty

**How to debug:**
1. Tap "Query Database Directly"
2. Check console output
3. If query succeeds but returns zeros, database is working (just empty)
4. Complete a workout and verify stats update

### "Query Database Directly" Fails

**Possible causes:**
1. Tables don't exist (migration failed)
2. Database file corrupted
3. GRDB connection lost

**How to debug:**
1. Check console for SQL errors
2. Look for migration logs: `✅ [Database] Tables created successfully`
3. Try force quitting and relaunching app

### Stats Don't Update After Completing Workout

**Possible causes:**
1. Workout save to database failed
2. Need to manually refresh stats
3. UI not refreshing

**How to debug:**
1. Tap "Refresh Stats" button
2. Check console for: `💾 [DatabaseCapability] Save workout requested`
3. Look for: `✅ [DatabaseCapability] Workout saved successfully`
4. If you see `❌ [DatabaseCapability] Save failed`, check error message

---

## 📱 Visual Guide

### What Success Looks Like:

```
┌─────────────────────────────────────┐
│ Database Status                      │
├─────────────────────────────────────┤
│ ✓ Database Initialized               │
│                                      │
│ 📁 Path: ~/.../thiccc.sqlite        │
│ 📄 Size: 24 KB                      │
│                                      │
│ ┌──────────────────────────────┐   │
│ │   2          3          9     │   │
│ │ Workouts  Exercises  Sets     │   │
│ └──────────────────────────────┘   │
│                                      │
│ ℹ️ Sample data loaded (DEBUG)       │
│                                      │
│ [Refresh Stats]                      │
└─────────────────────────────────────┘
```

### What Failure Looks Like:

```
┌─────────────────────────────────────┐
│ Database Status                      │
├─────────────────────────────────────┤
│ ⚠️ Database not initialized          │
│                                      │
│ [Refresh Stats]                      │
└─────────────────────────────────────┘
```

---

## 💡 Pro Tips

1. **Keep Debug tab open while testing**
   - See stats update in real-time
   - Quick feedback on database operations

2. **Use "Refresh Stats" liberally**
   - After finishing workout
   - After loading history
   - After any database operation

3. **Compare with History tab**
   - Debug tab shows raw database counts
   - History tab shows formatted list
   - Both should match

4. **Console logs are your friend**
   - Database operations print detailed logs
   - Look for emojis: 🗄️ 💾 📖 🗑️ ✅ ❌
   - Filter Xcode console by "Database" for focused view

5. **Sample data is helpful**
   - DEBUG builds auto-insert 2 sample workouts
   - Useful for testing without manual data entry
   - Verify sample data: Look for "sample-" prefix in IDs

---

## 🎓 Advanced: Direct Database Access

### Using sqlite3 Command Line:

```bash
# Find database path (shown in Debug tab)
DB_PATH=~/Library/Developer/CoreSimulator/Devices/.../Application Support/thiccc.sqlite

# Open in sqlite3
sqlite3 "$DB_PATH"

# Useful queries:
sqlite> .tables
sqlite> SELECT id, name, datetime(startTimestamp, 'unixepoch') FROM workouts;
sqlite> SELECT COUNT(*) FROM exercises;
sqlite> .schema workouts
sqlite> .quit
```

---

## ✅ Success Criteria

Phase 9 is fully verified when:

- [ ] Debug tab shows "Database Initialized" ✓
- [ ] Database path is displayed
- [ ] File size shows > 0
- [ ] Sample data shows 2+ workouts (DEBUG)
- [ ] "Refresh Stats" button works
- [ ] Can complete workout and see count increment
- [ ] App restart preserves data (counts stay same)
- [ ] History tab matches Debug tab counts
- [ ] "Query Database Directly" succeeds

---

**Last Updated:** December 25, 2025  
**Status:** Ready for verification  
**Related Docs:** `PHASE-9-MANUAL-TESTING.md`, `PHASE-9-SUMMARY.md`

