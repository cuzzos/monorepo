# Database Query Optimization - N+1 Query Fix

## Problem

The original implementation used a nested loop approach that created an N+1 query pattern:

### Before Optimization

For loading workout history:
1. Query all workouts (1 query)
2. For each workout, query its exercises (N queries)
3. For each exercise, query its sets (M queries per workout)

**Example with 10 workouts × 5 exercises × 3 sets each:**
- 1 query for workouts
- 10 queries for exercises (1 per workout)
- 50 queries for sets (1 per exercise)
- **Total: 61 queries**

## Solution

Replaced nested queries with bulk queries + in-memory assembly:

### After Optimization

1. Query all workouts (1 query)
2. Query all exercises for ALL workouts using `IN (...)` clause (1 query)
3. Query all sets for ALL exercises using `IN (...)` clause (1 query)
4. Assemble the hierarchy in memory using lookup maps

**Same dataset (10 workouts × 5 exercises × 3 sets):**
- 1 query for workouts
- 1 query for all exercises
- 1 query for all sets
- **Total: 3 queries**

## Performance Improvement

| Dataset Size | Before (Queries) | After (Queries) | Improvement |
|--------------|------------------|-----------------|-------------|
| 10 workouts, 5 exercises, 3 sets | 61 | 3 | **95% reduction** |
| 50 workouts, 8 exercises, 5 sets | 451 | 3 | **99.3% reduction** |
| 100 workouts, 10 exercises, 4 sets | 1,101 | 3 | **99.7% reduction** |

## Implementation Details

### Changed Functions

1. **`handleLoadAllWorkouts()`** (lines 376-495)
   - Changed from nested loops to bulk queries
   - Uses `StatementArguments` for safe parameter binding
   - Builds lookup maps: `setsByExercise` and `exercisesByWorkout`

2. **`handleLoadWorkoutById()`** (lines 497-613)
   - Same optimization for single workout loading
   - From 1 + N + M queries → 3 queries
   - Example: 1 workout with 5 exercises and 3 sets each
     - Before: 1 + 5 + 15 = **21 queries**
     - After: **3 queries**

### Key Techniques

1. **Bulk Loading**: Use `IN (...)` clauses with arrays of IDs
   ```sql
   WHERE workoutId IN (?, ?, ?, ...)
   ```

2. **Lookup Maps**: Build dictionaries for O(1) assembly
   ```swift
   var setsByExercise: [String: [[String: Any]]] = [:]
   var exercisesByWorkout: [String: [[String: Any]]] = [:]
   ```

3. **Safe Parameter Binding**: Use `StatementArguments`
   ```swift
   arguments: StatementArguments(workoutIds)
   ```

## Testing

All existing tests pass without modification:
- ✅ Save workout to database
- ✅ Load all workouts returns all saved workouts
- ✅ Load workout by ID returns full workout details
- ✅ Load workout with pinned notes and exercise notes
- ✅ Load workout with body part information
- ✅ Delete removes workout and cascades to exercises and sets
- ✅ All 11 database tests pass

## Benefits

1. **Scalability**: Performance no longer degrades with large workout histories
2. **Database Load**: Drastically reduced query count
3. **Latency**: Fewer round-trips to database
4. **Maintainability**: Same code structure, just better query patterns
5. **Backward Compatible**: No API or schema changes required

## Future Considerations

For extremely large datasets (1000+ workouts), consider:
1. Pagination with LIMIT/OFFSET
2. Lazy loading of older workouts
3. Caching frequently accessed workouts
4. Database indexes on foreign keys (already exist via FOREIGN KEY constraints)
