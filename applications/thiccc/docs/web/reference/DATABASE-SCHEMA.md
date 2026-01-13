# Database Schema

**Database:** PostgreSQL 16  
**Migration tool:** sqlx  
**Character set:** UTF-8

---

## Schema Overview

```
users (internal UUID + clerk_user_id)
  ↓
workouts
  ↓
workout_exercises → exercise_definitions (optional reference)
  ↓
exercise_sets

users → user_body_measurements → measurement_definitions

exercise_definitions (exercise library)
measurement_definitions (measurement types reference)
user_performance_records (view computed from exercise_sets)

trainer_client_relationships (Phase 8) - links users
planned_workouts (Phase 9)
workout_templates (Phase 9)
```

**Key Design Decision:**
- Internal `UUID` for `user_id` (stable, vendor-agnostic)
- External `clerk_user_id` stored in `users` table (auth provider reference)
- **Exercise library** (`exercise_definitions`) for consistent exercise metadata
- Exercises can reference library or be custom (free-text)

---

## Tables

### users

Stores internal user records with reference to external auth provider.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    roles TEXT[] DEFAULT ARRAY['user'],
    default_measurement_unit TEXT NOT NULL DEFAULT 'lbs' CHECK (default_measurement_unit IN ('lbs', 'kg')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

CREATE INDEX idx_users_clerk_id ON users(clerk_user_id);
CREATE INDEX idx_users_email ON users(email);
```

**Rationale:**
- **Internal UUID (`id`)**: Stable primary key, never changes, used as foreign key throughout schema
- **External reference (`clerk_user_id`)**: Auth provider's user ID, can be migrated
- **Roles array**: Supports multiple roles per user (e.g., `['user', 'trainer', 'admin']`)
- **Email**: Cached for queries, synced from Clerk on login
- **default_measurement_unit**: User's preferred unit for new sets ('lbs' or 'kg')
  - Frontend can pre-fill this value when creating sets
  - User can override on per-set basis if needed
- **Last login tracking**: For analytics and admin dashboard

**Phase:** 2 (Auth setup)

---

### workouts

Stores workout sessions.

```sql
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    notes TEXT,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workouts_user_id ON workouts(user_id);
CREATE INDEX idx_workouts_started_at ON workouts(started_at DESC);
CREATE INDEX idx_workouts_user_started ON workouts(user_id, started_at DESC);
```

**Rationale:**
- **Foreign key to users**: `user_id` references internal UUID, not Clerk ID
- **Cascade delete**: If user deleted, all workouts deleted (GDPR compliance)
- **Composite index**: Optimized for "get user's recent workouts" query
- **started_at and completed_at separate**: Workout might not be finished
- **Timestamps**: Track creation and modifications for sync/audit

---

### exercise_definitions

Stores exercise library with metadata (type, muscle groups, instructions).

```sql
CREATE TABLE exercise_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    exercise_type TEXT NOT NULL CHECK (exercise_type IN (
        'barbell', 'dumbbell', 'machine', 'cable',
        'bodyweight', 'resistance_band', 'kettlebell', 
        'cardio', 'other'
    )),
    tracking_type TEXT NOT NULL CHECK (tracking_type IN (
        'weight_reps',       -- Traditional strength: weight × reps
        'duration',          -- Time-based: plank, wall sit
        'distance',          -- Distance only: swimming laps
        'distance_duration', -- Distance + time: running, rowing
        'reps_only'          -- Bodyweight reps without weight: jumping jacks
    )),
    primary_muscle_group TEXT,
    secondary_muscle_groups TEXT[],
    difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    instructions TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exercise_definitions_name ON exercise_definitions(name);
CREATE INDEX idx_exercise_definitions_type ON exercise_definitions(exercise_type);
CREATE INDEX idx_exercise_definitions_tracking ON exercise_definitions(tracking_type);
CREATE INDEX idx_exercise_definitions_muscle ON exercise_definitions(primary_muscle_group);
```

**Rationale:**
- **Shared exercise library**: Consistent naming, autocomplete, analytics
- **exercise_type**: Categorizes equipment (barbell, dumbbell, bodyweight, cardio, etc.)
- **tracking_type**: Defines how performance is measured for this exercise
  - `weight_reps`: Traditional strength training (bench press, squats)
  - `duration`: Time-based holds (plank, wall sit)
  - `distance`: Distance only (swimming laps)
  - `distance_duration`: Both distance and time for pace calculation (running, rowing)
  - `reps_only`: Bodyweight movements without weight (jumping jacks, burpees)
- **Muscle groups**: For building balanced workout programs
- **Difficulty**: Helps beginners find appropriate exercises
- **Instructions**: Can display technique tips in UI
- **Unique name constraint**: Prevents duplicates

**Seed Data Examples:**
```sql
INSERT INTO exercise_definitions (name, exercise_type, tracking_type, primary_muscle_group, secondary_muscle_groups) VALUES
-- Strength
('Bench Press', 'barbell', 'weight_reps', 'chest', ARRAY['shoulders', 'triceps']),
('Pull-ups', 'bodyweight', 'weight_reps', 'back', ARRAY['biceps']),
('Leg Press', 'machine', 'weight_reps', 'legs', ARRAY['glutes']),
('Bicep Curls', 'dumbbell', 'weight_reps', 'biceps', ARRAY[]),
-- Duration-based
('Plank', 'bodyweight', 'duration', 'core', ARRAY[]),
('Wall Sit', 'bodyweight', 'duration', 'legs', ARRAY[]),
('Dead Hang', 'bodyweight', 'duration', 'back', ARRAY['forearms']),
-- Cardio
('Running', 'cardio', 'distance_duration', 'legs', ARRAY['cardio']),
('Rowing', 'cardio', 'distance_duration', 'full_body', ARRAY['cardio']),
('Swimming', 'cardio', 'distance', 'full_body', ARRAY['cardio']),
-- Reps only
('Jumping Jacks', 'bodyweight', 'reps_only', 'full_body', ARRAY[]),
('Burpees', 'bodyweight', 'reps_only', 'full_body', ARRAY[]);
```

**Phase:** 3 (Core API)

---

### workout_exercises

Stores exercises within a workout (references exercise library or custom).

```sql
CREATE TABLE workout_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_definition_id UUID REFERENCES exercise_definitions(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workout_exercises_workout_id ON workout_exercises(workout_id);
CREATE INDEX idx_workout_exercises_workout_order ON workout_exercises(workout_id, order_index);
CREATE INDEX idx_workout_exercises_definition_id ON workout_exercises(exercise_definition_id);
```

**Rationale:**
- **exercise_definition_id**: Optional reference to exercise library
  - If set: Exercise selected from library (consistent naming, metadata available)
  - If NULL: Custom exercise (user typed free-text name)
- **name**: Cached for quick display (denormalized from exercise_definitions.name)
  - Always populated (either from library or user input)
  - Allows fast queries without JOINing exercise_definitions every time
- **ON DELETE SET NULL**: If exercise definition deleted from library, workout history preserved
- **order_index**: Maintains exercise order in workout
- **Composite index**: Optimized for "get workout's exercises in order"

**Usage Patterns:**
- **From library**: `exercise_definition_id` set, `name` copied from library
- **Custom exercise**: `exercise_definition_id = NULL`, `name` is free-text

---

### exercise_sets

Stores individual sets within an exercise.

```sql
CREATE TABLE exercise_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id UUID NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
    
    -- Weight-based fields
    weight REAL,
    additional_weight REAL DEFAULT 0,
    measurement_unit TEXT CHECK (measurement_unit IN ('lbs', 'kg')),
    is_bodyweight BOOLEAN NOT NULL DEFAULT false,
    
    -- Rep-based field
    reps INTEGER,
    
    -- Duration-based field
    duration_seconds INTEGER,
    
    -- Distance-based fields
    distance REAL,
    distance_unit TEXT CHECK (distance_unit IN ('meters', 'km', 'miles', 'yards', 'laps')),
    
    -- Common fields
    rpe INTEGER,  -- Rate of Perceived Exertion (1-10)
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints based on tracking type
    CONSTRAINT check_weight_reps_fields CHECK (
        (weight IS NOT NULL AND measurement_unit IS NOT NULL AND reps IS NOT NULL) OR
        (weight IS NULL)
    ),
    CONSTRAINT check_additional_weight CHECK (
        (is_bodyweight = false AND additional_weight = 0) OR
        (is_bodyweight = true)
    ),
    CONSTRAINT check_distance_unit CHECK (
        (distance IS NOT NULL AND distance_unit IS NOT NULL) OR
        (distance IS NULL AND distance_unit IS NULL)
    ),
    CONSTRAINT check_at_least_one_metric CHECK (
        weight IS NOT NULL OR 
        reps IS NOT NULL OR 
        duration_seconds IS NOT NULL OR 
        distance IS NOT NULL
    )
);

CREATE INDEX idx_exercise_sets_exercise_id ON exercise_sets(exercise_id);
CREATE INDEX idx_exercise_sets_completed_at ON exercise_sets(completed_at DESC);
CREATE INDEX idx_exercise_sets_bodyweight ON exercise_sets(exercise_id, is_bodyweight);
```

**Rationale:**
- **Flexible schema**: Different tracking types populate different fields
- **exercise_id**: References `workout_exercises` (the specific exercise instance in a workout)

**Weight-based fields (tracking_type = 'weight_reps'):**
- **weight**: User's bodyweight (for bodyweight exercises) OR total weight moved (for loaded exercises)
- **additional_weight**: Added resistance or assistance for bodyweight exercises
  - Positive: Added weight (e.g., 25 lbs on dip belt)
  - Zero: Pure bodyweight
  - Negative: Assistance (e.g., -50 lbs from assisted pull-up machine)
- **measurement_unit**: The unit for `weight` and `additional_weight` ('lbs' or 'kg')
- **is_bodyweight**: Boolean flag (`true` for bodyweight exercises, `false` for loaded)
- **reps**: Number of repetitions

**Duration-based fields (tracking_type = 'duration'):**
- **duration_seconds**: Total time in seconds (e.g., 90 for 1:30 plank)

**Distance-based fields (tracking_type = 'distance' or 'distance_duration'):**
- **distance**: Distance value (e.g., 5.0 for 5km run)
- **distance_unit**: Unit of distance ('meters', 'km', 'miles', 'yards', 'laps')

**Reps-only fields (tracking_type = 'reps_only'):**
- **reps**: Number of repetitions (e.g., 50 jumping jacks)

**Common fields:**
- **rpe**: Rate of Perceived Exertion 1-10 (optional)
- **completed_at**: Timestamp when set was completed
- **Constraints**: Ensure data integrity based on which fields are populated

**Field Usage by Tracking Type:**

| Tracking Type | weight | reps | duration_seconds | distance |
|--------------|--------|------|------------------|----------|
| `weight_reps` | ✅ Required | ✅ Required | ❌ | ❌ |
| `duration` | ❌ | ❌ | ✅ Required | ❌ |
| `distance` | ❌ | ❌ | ❌ | ✅ Required |
| `distance_duration` | ❌ | ❌ | ✅ Required | ✅ Required |
| `reps_only` | ❌ | ✅ Required | ❌ | ❌ |

**Examples:**

*Traditional strength (Bench Press):*
```sql
weight = 225.0, reps = 5, measurement_unit = 'lbs', is_bodyweight = false
-- Volume: 225 × 5 = 1125 lbs
```

*Bodyweight with added weight (Weighted Dips):*
```sql
weight = 185.0, additional_weight = 25.0, reps = 8, measurement_unit = 'lbs', is_bodyweight = true
-- Effective weight: 210 lbs, Volume: 210 × 8 = 1680 lbs
```

*Duration-based (Plank):*
```sql
duration_seconds = 90
-- 1 minute 30 seconds
```

*Distance only (Swimming):*
```sql
distance = 500, distance_unit = 'meters'
-- 500 meter swim
```

*Distance + Duration (5K Run):*
```sql
distance = 5.0, distance_unit = 'km', duration_seconds = 1500
-- 5km in 25:00, pace = 5:00/km
```

*Reps only (Jumping Jacks):*
```sql
reps = 50
-- 50 jumping jacks
```

---

### measurement_definitions

Reference table for all body measurement types and their metadata.

```sql
CREATE TABLE measurement_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measurement_type TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN (
        'weight', 'length', 'circumference', 'composition', 'other'
    )),
    valid_units TEXT[] NOT NULL,
    default_unit TEXT NOT NULL,
    icon TEXT,
    display_order INTEGER,
    is_active BOOLEAN DEFAULT true,
    supports_body_part BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT check_default_unit_in_valid CHECK (default_unit = ANY(valid_units))
);

CREATE INDEX idx_measurement_definitions_category ON measurement_definitions(category);
CREATE INDEX idx_measurement_definitions_active ON measurement_definitions(is_active);
```

**Rationale:**
- **Normalized reference data**: Centralizes measurement metadata
- **No schema migrations for new types**: Just insert new rows
- **Rich metadata for UI**: Display names, descriptions, icons, ordering
- **Flexible validation**: `valid_units` array defines allowed units per type
- **Soft deletes**: `is_active` allows deprecating types without losing history
- **Supports body part tracking**: `supports_body_part` indicates if left/right makes sense

**Seed Data:**
```sql
INSERT INTO measurement_definitions 
(measurement_type, display_name, category, valid_units, default_unit, supports_body_part, display_order) 
VALUES
('bodyweight', 'Body Weight', 'weight', ARRAY['lbs', 'kg'], 'lbs', false, 1),
('height', 'Height', 'length', ARRAY['inches', 'cm', 'm'], 'inches', false, 2),
('body_fat_percentage', 'Body Fat %', 'composition', ARRAY['percentage'], 'percentage', false, 3),
('muscle_mass_percentage', 'Muscle Mass %', 'composition', ARRAY['percentage'], 'percentage', false, 4),
('bicep_circumference', 'Bicep Size', 'circumference', ARRAY['inches', 'cm'], 'inches', true, 5),
('chest_circumference', 'Chest Size', 'circumference', ARRAY['inches', 'cm'], 'inches', false, 6),
('waist_circumference', 'Waist Size', 'circumference', ARRAY['inches', 'cm'], 'inches', false, 7),
('hip_circumference', 'Hip Size', 'circumference', ARRAY['inches', 'cm'], 'inches', false, 8),
('thigh_circumference', 'Thigh Size', 'circumference', ARRAY['inches', 'cm'], 'inches', true, 9),
('calf_circumference', 'Calf Size', 'circumference', ARRAY['inches', 'cm'], 'inches', true, 10),
('neck_circumference', 'Neck Size', 'circumference', ARRAY['inches', 'cm'], 'inches', false, 11),
('forearm_circumference', 'Forearm Size', 'circumference', ARRAY['inches', 'cm'], 'inches', true, 12),
('shoulder_circumference', 'Shoulder Size', 'circumference', ARRAY['inches', 'cm'], 'inches', false, 13);
```

**Phase:** 3 (Core API)

---

### user_body_measurements

Stores user's physical body measurements over time.

```sql
CREATE TABLE user_body_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    measurement_definition_id UUID NOT NULL REFERENCES measurement_definitions(id),
    measurement_value REAL NOT NULL,
    measurement_unit TEXT NOT NULL,
    body_part TEXT CHECK (body_part IN ('left', 'right', 'both', NULL)),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN (
        'manual', 'workout', 'scale', 'tape_measure', 
        'calipers', 'fitness_tracker', 'import'
    )),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_body_measurements_user_id ON user_body_measurements(user_id);
CREATE INDEX idx_body_measurements_user_type_date ON user_body_measurements(user_id, measurement_definition_id, recorded_at DESC);
CREATE INDEX idx_body_measurements_definition ON user_body_measurements(measurement_definition_id);
```

**Rationale:**
- **Normalized design**: References `measurement_definitions` for metadata
- **Time-series data**: Track changes over time with `recorded_at`
- **Flexible unit tracking**: User can change units over time
- **Source tracking**: Know if data is self-reported vs device-measured
- **Body part support**: Track left/right for circumferences (e.g., bicep imbalances)
- **Validation at app level**: Check `measurement_unit` is in `measurement_definitions.valid_units`

**Phase:** 3 (Core API)

---

### user_performance_records (View)

Computed view showing user's personal records from workout data.

```sql
CREATE VIEW user_performance_records AS
SELECT 
    we.user_id,
    LOWER(REPLACE(we.name, ' ', '_')) as exercise_name,
    we.name as exercise_display_name,
    ed.exercise_type,
    ed.tracking_type,
    ed.primary_muscle_group,
    
    -- Weight/Reps metrics (tracking_type = 'weight_reps')
    es.weight as pr_weight,
    es.additional_weight as pr_additional_weight,
    es.measurement_unit,
    es.reps as pr_reps,
    es.is_bodyweight,
    CASE 
        WHEN ed.tracking_type = 'weight_reps' AND es.is_bodyweight = false AND es.reps BETWEEN 1 AND 10
        THEN es.weight * (1 + es.reps / 30.0)
        ELSE NULL
    END as estimated_1rm,
    CASE
        WHEN ed.tracking_type = 'weight_reps' AND es.is_bodyweight = true
        THEN es.weight + es.additional_weight
        WHEN ed.tracking_type = 'weight_reps'
        THEN es.weight
        ELSE NULL
    END as effective_weight,
    
    -- Duration metrics (tracking_type = 'duration')
    es.duration_seconds as pr_duration_seconds,
    
    -- Distance metrics (tracking_type = 'distance' or 'distance_duration')
    es.distance as pr_distance,
    es.distance_unit as pr_distance_unit,
    
    -- Pace calculation (tracking_type = 'distance_duration')
    CASE
        WHEN ed.tracking_type = 'distance_duration' AND es.duration_seconds > 0
        THEN es.distance / (es.duration_seconds / 3600.0)  -- per hour
        ELSE NULL
    END as pace_per_hour,
    
    es.completed_at as pr_date,
    w.id as workout_id,
    w.name as workout_name
FROM exercise_sets es
JOIN workout_exercises we ON es.exercise_id = we.id
JOIN workouts w ON we.workout_id = w.id
LEFT JOIN exercise_definitions ed ON we.exercise_definition_id = ed.id
WHERE ed.tracking_type IS NOT NULL
-- Only show personal records (best for each exercise)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY we.user_id, LOWER(we.name)
    ORDER BY 
        CASE ed.tracking_type
            WHEN 'weight_reps' THEN 
                CASE 
                    WHEN es.is_bodyweight = false THEN es.weight * (1 + es.reps / 30.0)
                    ELSE (es.weight + es.additional_weight) * es.reps
                END
            WHEN 'duration' THEN es.duration_seconds
            WHEN 'distance' THEN es.distance
            WHEN 'distance_duration' THEN es.distance  -- Could also sort by pace
            WHEN 'reps_only' THEN es.reps
            ELSE 0
        END DESC NULLS LAST
) = 1;
```

**Rationale:**
- **Zero manual entry**: PRs automatically computed from workout data
- **Single source of truth**: Reflects actual logged sets
- **Handles all tracking types**: 
  - `weight_reps`: Best 1RM estimate or volume
  - `duration`: Longest time
  - `distance`: Furthest distance
  - `distance_duration`: Fastest pace or furthest distance
  - `reps_only`: Most reps
- **Always current**: Updates automatically when new PRs are set
- **Rich context**: Includes workout info, exercise metadata, tracking type

**Usage Examples:**
```sql
-- Get all user PRs
SELECT * FROM user_performance_records WHERE user_id = $1;

-- Get PRs by tracking type
SELECT * FROM user_performance_records 
WHERE user_id = $1 AND tracking_type = 'duration';

-- Get cardio PRs (running, rowing)
SELECT exercise_display_name, pr_distance, pr_distance_unit, 
       pr_duration_seconds, pace_per_hour
FROM user_performance_records 
WHERE user_id = $1 AND tracking_type = 'distance_duration';

-- Recent PRs (last 30 days)
SELECT * FROM user_performance_records 
WHERE user_id = $1 AND pr_date > NOW() - INTERVAL '30 days';
```

**Phase:** 5 (After workouts are implemented)

---

### trainer_client_relationships (Phase 8)

Stores trainer → client connections.

```sql
CREATE TABLE trainer_client_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id TEXT NOT NULL,  -- Clerk user ID
    client_id TEXT NOT NULL,   -- Clerk user ID
    status TEXT NOT NULL DEFAULT 'pending',  -- 'pending' | 'active' | 'inactive'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(trainer_id, client_id)
);

CREATE INDEX idx_trainer_clients ON trainer_client_relationships(trainer_id, status);
CREATE INDEX idx_client_trainers ON trainer_client_relationships(client_id, status);
```

**Rationale:**
- One trainer can have many clients
- One client can have many trainers (gym + personal)
- Status tracks invitation state
- UNIQUE constraint prevents duplicate relationships

---

### planned_workouts (Phase 9)

Stores future scheduled workouts.

```sql
CREATE TABLE planned_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    planned_date DATE NOT NULL,
    workout_template_id UUID REFERENCES workout_templates(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    notes TEXT,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_planned_user_date ON planned_workouts(user_id, planned_date);
CREATE INDEX idx_planned_date ON planned_workouts(planned_date);
```

**Rationale:**
- `planned_date` is DATE (no time, just day)
- Links to optional `workout_template`
- Links to actual `workout` once completed
- User can plan without template (custom workouts)

---

### workout_templates (Phase 9)

Stores reusable workout templates.

```sql
CREATE TABLE workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_templates_user ON workout_templates(user_id);
CREATE INDEX idx_templates_public ON workout_templates(is_public) WHERE is_public = TRUE;
```

**Rationale:**
- Users can save favorite workouts as templates
- `is_public` allows sharing templates (future community feature)
- Template exercises stored in separate table (not shown here)

---

## Migrations

Migrations are stored in `api_server/migrations/` and applied via sqlx.

### Migration naming convention:
```
001_initial_schema.sql
002_add_trainer_relationships.sql
003_add_planned_workouts.sql
```

### Running migrations:
```bash
dagger call db-migrate --source=applications/thiccc/api_server
```

### Creating new migration:
```bash
dagger call db-create-migration --name="add_new_feature"
```

---

## Data Types

| Type | PostgreSQL | Rust | TypeScript |
|------|-----------|------|------------|
| ID | UUID | `Uuid` | `string` |
| User ID | TEXT | `String` | `string` |
| Name/Notes | TEXT | `String` | `string` |
| Weight | REAL | `f32` | `number` |
| Reps/RPE | INTEGER | `i32` | `number` |
| Timestamp | TIMESTAMPTZ | `DateTime<Utc>` | `Date` or `string` (ISO 8601) |
| Date | DATE | `NaiveDate` | `string` (YYYY-MM-DD) |
| Boolean | BOOLEAN | `bool` | `boolean` |

---

## Query Performance

### Common queries and their indexes:

**Get user by Clerk ID:**
```sql
SELECT id, email, roles FROM users WHERE clerk_user_id = $1;
```
Uses: `idx_users_clerk_id`

**Search exercise library:**
```sql
SELECT * FROM exercise_definitions 
WHERE name ILIKE '%bench%' 
ORDER BY name
LIMIT 10;
```
Uses: `idx_exercise_definitions_name`

**Get exercises by type:**
```sql
SELECT * FROM exercise_definitions
WHERE exercise_type = 'bodyweight'
ORDER BY name;
```
Uses: `idx_exercise_definitions_type`

**Get latest bodyweight:**
```sql
SELECT m.measurement_value, m.measurement_unit, m.recorded_at
FROM user_body_measurements m
JOIN measurement_definitions md ON m.measurement_definition_id = md.id
WHERE m.user_id = $1 AND md.measurement_type = 'bodyweight'
ORDER BY m.recorded_at DESC
LIMIT 1;
```
Uses: `idx_body_measurements_user_type_date`

**Get all current measurements (latest for each type):**
```sql
SELECT DISTINCT ON (md.measurement_type)
    md.display_name,
    md.category,
    m.measurement_value,
    m.measurement_unit,
    m.recorded_at
FROM user_body_measurements m
JOIN measurement_definitions md ON m.measurement_definition_id = md.id
WHERE m.user_id = $1 AND md.is_active = true
ORDER BY md.measurement_type, m.recorded_at DESC;
```
Uses: `idx_body_measurements_user_type_date`, `idx_measurement_definitions_active`

**Track measurement over time (for charts):**
```sql
SELECT m.measurement_value, m.measurement_unit, m.recorded_at
FROM user_body_measurements m
JOIN measurement_definitions md ON m.measurement_definition_id = md.id
WHERE m.user_id = $1 
    AND md.measurement_type = 'bodyweight'
    AND m.recorded_at > NOW() - INTERVAL '90 days'
ORDER BY m.recorded_at;
```
Uses: `idx_body_measurements_user_type_date`

**Get user's PRs:**
```sql
SELECT * FROM user_performance_records 
WHERE user_id = $1 
ORDER BY pr_date DESC;
```
Uses: Underlying indexes on `exercise_sets`, `workout_exercises`

**Get user's recent workouts:**
```sql
SELECT * FROM workouts 
WHERE user_id = $1 
ORDER BY started_at DESC 
LIMIT 50;
```
Uses: `idx_workouts_user_started`

**Get workout with exercises and sets (with exercise metadata):**
```sql
SELECT 
    w.*,
    e.*,
    ed.exercise_type,
    ed.primary_muscle_group,
    s.*
FROM workouts w
LEFT JOIN workout_exercises e ON e.workout_id = w.id
LEFT JOIN exercise_definitions ed ON e.exercise_definition_id = ed.id
LEFT JOIN exercise_sets s ON s.exercise_id = e.id
WHERE w.id = $1
ORDER BY e.order_index, s.completed_at;
```
Uses: `idx_workout_exercises_workout_id`, `idx_exercise_sets_exercise_id`, `idx_workout_exercises_definition_id`

**Get trainer's clients:**
```sql
SELECT * FROM trainer_client_relationships
WHERE trainer_id = $1 AND status = 'active';
```
Uses: `idx_trainer_clients`

---

## Constraints

### Foreign Key Cascades

- **users → workouts**: `ON DELETE CASCADE`
  - Deleting user deletes all their workouts (GDPR compliance)
  
- **workouts → workout_exercises**: `ON DELETE CASCADE`
  - Deleting workout deletes all exercises
  
- **workout_exercises → exercise_sets**: `ON DELETE CASCADE`
  - Deleting exercise deletes all sets

- **workout_templates → planned_workouts**: `ON DELETE SET NULL`
  - Deleting template doesn't delete planned workouts (sets template_id to NULL)

### Unique Constraints

- `users(clerk_user_id)` - One Clerk user = one internal user
- `users(email)` - No duplicate emails (though not enforced as PRIMARY KEY for future multi-auth)
- `trainer_client_relationships(trainer_id, client_id)` - No duplicate relationships

---

## Timestamps

All tables have:
- `created_at`: Set once on insert
- `updated_at`: Updated on every modification

Use trigger or application logic to update `updated_at`:

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON workouts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## Backup Strategy (Railway)

Railway automatically:
- Takes daily backups (retained 7 days)
- Point-in-time recovery (within 7 days)

For manual backup:
```bash
dagger call db-backup --output=backup_2025-01-01.sql
```

For restore:
```bash
dagger call db-restore --input=backup_2025-01-01.sql
```

---

## UX Patterns for Exercise Sets

### Bodyweight Exercise Flow

When user is logging a bodyweight exercise (pull-ups, dips, push-ups):

**Step 1: Check for recent bodyweight**
```
Frontend checks:
- User's most recent workout_exercise with is_bodyweight = true
- Or user preference/profile (future: user_measurements table)
```

**Step 2: Pre-fill form**
```
Your weight: [185] lbs  (pre-filled from recent data)

Reps: [ ]
RPE: [ ]

○ Pure bodyweight
○ Add resistance: [ ] lbs
○ Use assistance: [ ] lbs
```

**Step 3: Show effective weight**
```
Effective weight: 185 lbs  (updates as user types)
```

**Step 4: Save to database**
```sql
-- Pure bodyweight
INSERT INTO exercise_sets (exercise_id, weight, additional_weight, measurement_unit, is_bodyweight, reps)
VALUES (..., 185.0, 0, 'lbs', true, 10);

-- With 25lb weight belt
INSERT INTO exercise_sets (exercise_id, weight, additional_weight, measurement_unit, is_bodyweight, reps)
VALUES (..., 185.0, 25.0, 'lbs', true, 8);

-- With 50lb assistance
INSERT INTO exercise_sets (exercise_id, weight, additional_weight, measurement_unit, is_bodyweight, reps)
VALUES (..., 185.0, -50.0, 'lbs', true, 12);
```

### Loaded Exercise Flow

When user is logging a loaded exercise (barbell, dumbbell, machine):

**Form:**
```
Weight: [ ] lbs
Reps: [ ]
RPE: [ ]
```

**Save to database:**
```sql
INSERT INTO exercise_sets (exercise_id, weight, additional_weight, measurement_unit, is_bodyweight, reps)
VALUES (..., 225.0, 0, 'lbs', false, 5);
```

### Benefits of This Approach

- ✅ **User doesn't manually enter bodyweight every set** (pre-filled from recent data)
- ✅ **Single unified form** for all bodyweight variations
- ✅ **Accurate volume calculations** for analytics
- ✅ **Progress tracking** accounts for bodyweight changes
- ✅ **Clean data model** with explicit semantics

---

## Authentication Flow with Users Table

### First-Time User Login

When a user logs in for the first time (via Clerk):

1. **Frontend**: User authenticates with Clerk
2. **Frontend**: Gets JWT with `clerk_user_id` in claims
3. **Backend**: Receives request with JWT
4. **Backend**: Validates JWT with Clerk
5. **Backend**: Checks if user exists:
   ```sql
   SELECT id FROM users WHERE clerk_user_id = $1;
   ```
6. **If user doesn't exist**, create record:
   ```sql
   INSERT INTO users (clerk_user_id, email, roles)
   VALUES ($1, $2, ARRAY['user'])
   RETURNING id;
   ```
7. **Update last login**:
   ```sql
   UPDATE users SET last_login_at = NOW() WHERE clerk_user_id = $1;
   ```
8. **Use internal UUID** (`id`) for all subsequent operations

### Typical Request Flow

```
Client Request → Clerk JWT → Backend
                     ↓
              Extract clerk_user_id
                     ↓
         Lookup internal user_id (UUID)
                     ↓
      Use user_id for all database queries
```

### Benefits of This Approach

1. **Vendor Independence**: Auth provider can change, internal IDs stay stable
2. **Clean Foreign Keys**: All tables reference `users.id` (UUID), not external strings
3. **User Metadata**: Store app-specific data (roles, preferences) in `users` table
4. **Multiple Auth Methods**: Can add social logins, iOS auth, etc. - all map to same internal user
5. **Audit Trail**: Track when Clerk IDs change (rare, but possible)
6. **GDPR Compliance**: Single point of deletion (`DELETE FROM users WHERE id = $1`)

---

## Schema Evolution

When adding new features:
1. Create migration file
2. Test locally with `db-migrate`
3. Test rollback if needed
4. Deploy to Railway (automatic via CI/CD)

**Never:**
- Modify existing migrations
- Delete data in migrations without backups
- Change column types without migration plan

