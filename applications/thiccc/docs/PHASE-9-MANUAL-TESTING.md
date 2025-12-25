# Phase 9 Manual Testing Guide

**Prerequisites:** GRDB dependency must be added to Xcode project first.

## Step 1: Add GRDB Dependency (Required First)

Before building, you MUST add GRDB to the Xcode project:

### Via Xcode GUI (2 minutes):

1. **Open project:**
   ```bash
   cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc
   open app/ios/Thiccc.xcodeproj
   ```

2. **Add Package:**
   - Select "Thiccc" project in navigator
   - Select "Thiccc" target
   - Go to "General" tab → "Frameworks, Libraries, and Embedded Content"
   - Click "+" → "Add Package Dependency..."
   - Enter: `https://github.com/groue/GRDB.swift.git`
   - Version: "Up to Next Major Version" → `6.0.0`
   - Click "Add Package"
   - Check "Thiccc" target
   - Click "Add Package"

3. **Verify:**
   - You should see "GRDB" under "Package Dependencies"
   - Build project: ⌘B

---

## Step 2: Build & Run in Simulator

### Build the App:

```bash
cd /Users/eganm/personal/cuzzo_monorepo/applications/thiccc
make build
```

Expected output:
- ✅ No compilation errors
- ✅ Database files compile successfully
- ⚠️  Possible warnings about unused variables (okay for now)

### Run in Simulator:

1. **Launch simulator:**
   ```bash
   open -a Simulator
   ```

2. **Run app from Xcode:**
   - Select iPhone 15 Pro (or any iOS 18+ device)
   - Press ⌘R (Run)

3. **Check console for database logs:**
   ```
   🚀 [DatabaseManager] Setting up database...
   📍 [Database] Path: /Users/.../Application Support/thiccc.sqlite
   ✅ [Database] Tables created successfully
   ✅ [Database] Initialized successfully
   ✅ [ThicccApp] Database initialized successfully
   ```

---

## Step 3: Test Workflow - Complete a Workout

### Test Case 1: Save Workout to Database

1. **Start a workout:**
   - Tap "Start Workout"
   - Name it: "Database Test Workout"

2. **Add exercises:**
   - Tap "Add Exercise"
   - Select "Bench Press"
   - Add 3 sets with different weights

3. **Complete sets:**
   - Fill in weight/reps for each set
   - Mark all sets complete (✓)

4. **Finish workout:**
   - Tap "Finish Workout"
   - **Watch console for database logs:**
     ```
     💾 [DatabaseCapability] Save workout requested
     📄 [DatabaseCapability] JSON length: 2456 bytes
     🔄 [DatabaseCapability] Save attempt 1 of 2
     ✅ [DatabaseCapability] Inserted workout with 1 exercises
     ✅ [DatabaseCapability] Workout saved successfully (attempt 1)
     ```

5. **Verify success:**
   - No error alerts shown
   - Workout completes normally

---

## Step 4: Test Persistence - "App Restart"

### Test Case 2: Verify Data Survives App Restart

1. **Stop the app:**
   - Press ⌘. (stop) in Xcode
   - Or force quit from simulator (swipe up)

2. **Restart the app:**
   - Press ⌘R (run) again

3. **Check History:**
   - Navigate to "History" tab
   - **Expected:** "Database Test Workout" appears in list
   - **Watch console:**
     ```
     📖 [DatabaseCapability] Load all workouts requested
     ✅ [DatabaseCapability] Loaded 1 workouts
     ```

4. **View workout details:**
   - Tap on "Database Test Workout"
   - **Expected:** All exercises and sets are visible
   - **Watch console:**
     ```
     📖 [DatabaseCapability] Load workout by ID: <uuid>
     ✅ [DatabaseCapability] Loaded workout: <uuid>
     ```

---

## Step 5: Test Sample Data (DEBUG Build Only)

### Test Case 3: Verify Sample Workouts Load

If building in DEBUG mode, sample workouts should be automatically inserted:

1. **On first launch, check console:**
   ```
   📝 [Database] Inserting sample workout data...
   ✅ [Database] Sample data inserted (2 workouts, 2 exercises each)
   ```

2. **Navigate to History:**
   - Should see:
     - "Morning Run" (1 day ago)
     - "Evening Strength" (2 days ago)

3. **Tap on "Evening Strength":**
   - Should show:
     - Bench Press: 3 sets (135×12, 160×8, 175×5)
     - Pull Up: 3 sets (12, 8, 7 reps)

---

## Step 6: Test Delete Workout

### Test Case 4: Verify CASCADE DELETE

1. **Go to History**

2. **Swipe left on workout** (or long press for context menu)
   - Tap "Delete"

3. **Watch console:**
   ```
   🗑️  [DatabaseCapability] Delete workout: <uuid>
   ✅ [DatabaseCapability] Workout deleted: <uuid>
   ```

4. **Verify:**
   - Workout disappears from history
   - Restart app → workout still gone (persistent delete)

---

## Step 7: Test Error Handling (Optional Advanced Test)

### Test Case 5: Simulate Database Failure

This test requires code modification to simulate failures:

1. **Modify DatabaseCapability.swift temporarily:**
   ```swift
   // In saveWorkoutToDatabase(), add at top:
   if ProcessInfo.processInfo.environment["SIMULATE_DB_FAILURE"] == "true" {
       throw DatabaseError(message: "Simulated failure")
   }
   ```

2. **Set environment variable in Xcode:**
   - Edit Scheme → Run → Arguments → Environment Variables
   - Add: `SIMULATE_DB_FAILURE = true`

3. **Complete a workout:**
   - **Watch console for retry logic:**
     ```
     🔄 [DatabaseCapability] Save attempt 1 of 2
     ❌ [DatabaseCapability] Save failed (attempt 1): Simulated failure
     ⏳ [DatabaseCapability] Waiting 0.5s before retry...
     🔄 [DatabaseCapability] Save attempt 2 of 2
     ❌ [DatabaseCapability] Save failed (attempt 2): Simulated failure
     ⚠️  [DatabaseCapability] All attempts failed, creating backup...
     💾 [DatabaseCapability] Backup saved: workout-backup-2025-12-25T...json
     ⏰ [DatabaseCapability] Scheduling background retry in 5 seconds...
     ```

4. **Check backup directory:**
   ```bash
   ls -la ~/Library/Application\ Support/com.thiccc.app/workout-backups/
   ```
   - Should see `workout-backup-*.json` file

5. **Remove environment variable and restart:**
   - Backup should automatically be processed
   - File should be deleted after successful save

---

## Step 8: Inspect Database (Optional)

### View SQLite Database Directly:

```bash
# Find database path from console logs or:
DB_PATH=~/Library/Containers/com.thiccc.app/Data/Library/Application\ Support/thiccc.sqlite

# Open in sqlite3:
sqlite3 "$DB_PATH"

# Run queries:
sqlite> .tables
# Expected: exercises  exerciseSets  workouts

sqlite> SELECT id, name, datetime(startTimestamp, 'unixepoch') as date FROM workouts;
# Expected: List of all workouts

sqlite> SELECT COUNT(*) FROM exercises;
# Expected: Total exercise count

sqlite> .quit
```

---

## Expected Results Summary

| Test | Expected Result | Status |
|------|----------------|--------|
| 1. Save workout | ✅ Console shows "Workout saved successfully" | |
| 2. Load history | ✅ History shows saved workouts | |
| 3. Load details | ✅ Full workout details display | |
| 4. Persistence | ✅ Data survives app restart | |
| 5. Sample data | ✅ 2 sample workouts in DEBUG | |
| 6. Delete | ✅ Workout removed, survives restart | |
| 7. Error handling | ✅ Retry → Backup → Recovery | |

---

## Troubleshooting

### Build Errors:

**Error:** `No such module 'GRDB'`
- **Fix:** Add GRDB package dependency (Step 1)

**Error:** Database files not found
- **Fix:** Ensure all files are added to Xcode target
  - Schema.swift ✓
  - DatabaseManager.swift ✓
  - DatabaseCapability.swift ✓

### Runtime Errors:

**Error:** "Table workouts does not exist"
- **Check:** Migration ran successfully
- **Fix:** Delete app from simulator and reinstall

**Error:** "Failed to serialize workout"
- **Check:** JSON structure matches Rust types
- **Fix:** Verify snake_case conversion

### Database Not Created:

**Check console for:**
```
❌ [DatabaseManager] Setup failed: <error>
```

**Common causes:**
- Permissions issue (Application Support directory)
- Migration syntax error
- GRDB not linked properly

**Fix:**
```bash
# Reset simulator:
xcrun simctl erase all

# Rebuild:
make clean
make build
```

---

## Success Criteria

Phase 9 is complete when ALL of the following pass:

- ✅ App builds without errors
- ✅ Database initializes on launch
- ✅ Workout saves successfully
- ✅ Workout appears in history after restart
- ✅ Workout details load correctly
- ✅ Delete removes workout permanently
- ✅ Sample data visible in DEBUG builds
- ✅ All unit tests pass
- ✅ Rust core tests pass

---

## Next Steps After Phase 9

Once Phase 9 is verified:

1. **Update 00-OVERVIEW.md:**
   - Mark Phase 9 as "✅ Complete"
   - Unblock Phase 7 (History Views)

2. **Consider Phase 7:**
   - History list now functional (backed by real data)
   - History detail view can load from database

3. **Consider Phase 10:**
   - Stats calculations (use database queries)
   - Analytics on workout history


