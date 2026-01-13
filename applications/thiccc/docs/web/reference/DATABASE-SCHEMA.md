# Database Schema

> **TLDR:** PostgreSQL 16 database schema for thiccc. Supports 8 workout formats (traditional, EMOM, AMRAP, For Time, Tabata, Interval, Circuit, Hyrox). Fully normalized design (no JSONB) for iOS/SQLite compatibility. Slim core tables with optional 1:1 relationships for format-specific data. Includes users, workouts, exercises, sets, body measurements, trainer relationships, templates, and planned workouts. Uses UUIDs, `TIMESTAMPTZ`, internal user IDs with Clerk integration.

## Table of Contents
- [Schema Overview](#schema-overview)
- [Workout Format Types Supported](#workout-format-types-supported)
- [Tables](#tables)
  - [users](#users)
  - [workout_format_definitions](#workout_format_definitions)
  - [workouts](#workouts)
  - [workout_timings](#workout_timings)
  - [workout_completions](#workout_completions)
  - [workout_sections](#workout_sections)
  - [workout_exercises](#workout_exercises)
  - [exercise_sets](#exercise_sets)
  - [exercise_definitions](#exercise_definitions)
  - [user_body_measurements](#user_body_measurements)
  - [measurement_definitions](#measurement_definitions)
  - [user_performance_records](#user_performance_records)
  - [trainer_client_relationships](#trainer_client_relationships)
  - [workout_templates](#workout_templates)
  - [planned_workouts](#planned_workouts)
- [Workout Format Examples](#workout-format-examples)
- [Migrations](#migrations)
- [Data Types](#data-types)
- [Query Examples](#query-examples)
- [Schema Evolution Strategy](#schema-evolution-strategy)
- [Benefits of This Design](#benefits-of-this-design)
- [Next Steps](#next-steps)

---

**Database:** PostgreSQL 16  
**Migration tool:** sqlx  
**Character set:** UTF-8

---

## Schema Overview

```
users (internal UUID + clerk_user_id)
  ↓
workout_format_definitions (reference data: traditional, EMOM, AMRAP, etc.)
  ↓
workouts (slim table: core fields only)
  ├─ workout_timings (optional 1:1: format-specific timing)
  ├─ workout_completions (optional 1:1: format-specific results)
  └─ workout_sections (optional: for circuits, EMOMs, supersets)
  ↓
workout_exercises → exercise_definitions (optional reference)
  ↓
        exercise_sets (with round_number support)

users → user_body_measurements → measurement_definitions

exercise_definitions (exercise library)
measurement_definitions (measurement types reference)
user_performance_records (view computed from exercise_sets)

trainer_client_relationships (Phase 8) - links users
planned_workouts (Phase 9)
workout_templates (Phase 9)
  └─ workout_template_timings (optional 1:1: default timing)
```

**Key Design Decisions:**
- Internal `UUID` for `user_id` (stable, vendor-agnostic)
- External `clerk_user_id` stored in `users` table (auth provider reference)
- **Exercise library** (`exercise_definitions`) for consistent exercise metadata
- **Slim core tables** with optional 1:1 relationships for format-specific data
- **No JSONB** - fully normalized, iOS-compatible (SQLite)
- **Reference data** (`workout_format_definitions`) for format selection UX
- **Optional sectioning** via `workout_sections` for circuits, EMOMs, supersets
- **Round tracking** via `round_number` on sets for circuits and AMRAP

---

## Workout Format Types Supported

| Format | Description | Timing Structure | Scoring |
|--------|-------------|------------------|---------|
| `traditional` | Standard strength training | Per-exercise rest times | Weight × Reps (volume) |
| `emom` | Every Minute On the Minute | Fixed interval (e.g., 60s) | Rounds completed |
| `amrap` | As Many Rounds/Reps As Possible | Time cap (e.g., 10 min) | Rounds + reps completed |
| `for_time` | Complete work as fast as possible | Time cap (optional) | Time to complete |
| `tabata` | 20s work / 10s rest × 8 rounds | 20s work, 10s rest | Rounds completed |
| `interval` | Custom work/rest intervals | Configurable | Rounds completed |
| `circuit` | Round-robin through exercises | Rest between rounds | Rounds completed |
| `hyrox` | Structured race format | Segments (run + exercise) | Total time |

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
- **Last login tracking**: For analytics and admin dashboard

**Phase:** 2 (Auth setup)

---

### workout_format_definitions

Reference table for workout format types and their metadata.

```sql
CREATE TABLE workout_format_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    format_key TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('strength', 'cardio', 'hybrid', 'sport')),
    
    -- Default timing values (null if not applicable to this format)
    default_time_cap_seconds INTEGER,
    default_interval_seconds INTEGER,
    default_work_seconds INTEGER,
    default_rest_seconds INTEGER,
    default_rounds INTEGER,
    
    -- Format characteristics (for UI filtering/selection)
    is_timed BOOLEAN NOT NULL DEFAULT false,        -- Has time cap or intervals
    is_scored BOOLEAN NOT NULL DEFAULT false,       -- Tracks competitive score
    requires_rounds BOOLEAN NOT NULL DEFAULT false, -- Exercises done in rounds
    
    -- Display metadata
    icon_name TEXT,
    display_order INTEGER,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_format_defs_category ON workout_format_definitions(category);
CREATE INDEX idx_format_defs_active ON workout_format_definitions(is_active);
```

**Seed Data:**
```sql
INSERT INTO workout_format_definitions 
(format_key, display_name, description, category, default_rounds, is_timed, is_scored, requires_rounds, display_order) 
VALUES
('traditional', 'Traditional', 'Standard strength training with rest between sets', 'strength', NULL, false, false, false, 1),
('emom', 'EMOM', 'Every Minute On the Minute - complete work within each minute', 'cardio', 10, true, true, true, 2),
('amrap', 'AMRAP', 'As Many Rounds As Possible in a time limit', 'hybrid', NULL, true, true, true, 3),
('for_time', 'For Time', 'Complete prescribed work as fast as possible', 'hybrid', NULL, true, true, false, 4),
('tabata', 'Tabata', '20 seconds work, 10 seconds rest, 8 rounds', 'cardio', 8, true, false, true, 5),
('circuit', 'Circuit', 'Multiple exercises done in sequence for rounds', 'strength', 3, false, false, true, 6),
('interval', 'Interval', 'Custom work/rest intervals', 'cardio', NULL, true, false, true, 7),
('hyrox', 'Hyrox', 'Structured race format (8x 1km run + 8 exercises)', 'sport', NULL, true, true, false, 8);
```

**Rationale:**
- **Reference data**: Static workout format types with metadata
- **Default values**: Pre-populate UI forms when user selects format
- **Format characteristics**: UI can filter/display formats appropriately
- **No schema migrations**: Add new formats by inserting rows
- **iOS compatible**: No JSONB, pure relational design

**Phase:** 3 (Core API)

---

### workouts

Stores core workout session data (slim table, format-specific data in child tables).

```sql
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_format_id UUID NOT NULL REFERENCES workout_format_definitions(id),
    
    name TEXT NOT NULL,
    notes TEXT,
    
    -- Timestamps
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,       -- Actual workout duration (excluding pauses)
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workouts_user_id ON workouts(user_id);
CREATE INDEX idx_workouts_started_at ON workouts(started_at DESC);
CREATE INDEX idx_workouts_user_started ON workouts(user_id, started_at DESC);
CREATE INDEX idx_workouts_format_id ON workouts(workout_format_id);
CREATE INDEX idx_workouts_user_format ON workouts(user_id, workout_format_id);
```

**Rationale:**
- **Slim table**: Core fields only (8 columns total)
- **Format-agnostic**: No format-specific nullable columns
- **1:1 relationships**: Timing and scoring data in separate tables
- **Clean separation**: Core workout data vs format configuration vs scoring

**Phase:** 3 (Core API)

---

### workout_timings

Stores format-specific timing configuration (optional, 1:1 with workouts).

```sql
CREATE TABLE workout_timings (
    workout_id UUID PRIMARY KEY REFERENCES workouts(id) ON DELETE CASCADE,
    
    -- Timing fields (nullable, populated based on format)
    time_cap_seconds INTEGER,             -- AMRAP, For Time, Interval
    interval_seconds INTEGER,             -- EMOM
    work_seconds INTEGER,                 -- Tabata, Interval
    rest_seconds INTEGER,                 -- Tabata, Interval
    rounds INTEGER,                       -- EMOM, Tabata, Circuit, Interval
    rest_between_rounds_seconds INTEGER,  -- Circuit, Interval
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workout_timings_rounds ON workout_timings(rounds);
CREATE INDEX idx_workout_timings_time_cap ON workout_timings(time_cap_seconds);
```

**When to create:**
- Traditional workouts: **Don't create** (no timing config needed)
- EMOM/AMRAP/Circuit: **Create** with relevant fields populated

**Examples:**

*EMOM (10 minutes, 60-second intervals):*
```sql
INSERT INTO workout_timings (workout_id, interval_seconds, rounds)
VALUES (<workout_uuid>, 60, 10);
```

*AMRAP (10 minutes):*
```sql
INSERT INTO workout_timings (workout_id, time_cap_seconds)
VALUES (<workout_uuid>, 600);
```

*Tabata:*
```sql
INSERT INTO workout_timings (workout_id, work_seconds, rest_seconds, rounds)
VALUES (<workout_uuid>, 20, 10, 8);
```

*Circuit (3 rounds, 2-minute rest):*
```sql
INSERT INTO workout_timings (workout_id, rounds, rest_between_rounds_seconds)
VALUES (<workout_uuid>, 3, 120);
```

**Phase:** 3 (Core API)

---

### workout_completions

Stores format-specific completion results (optional, 1:1 with workouts).

```sql
CREATE TABLE workout_completions (
    workout_id UUID PRIMARY KEY REFERENCES workouts(id) ON DELETE CASCADE,
    
    -- Completion fields (nullable, populated based on format)
    rounds_completed INTEGER,        -- AMRAP, EMOM
    additional_reps INTEGER,         -- AMRAP (partial round)
    time_to_complete_seconds INTEGER,  -- For Time, Hyrox
    is_scaled BOOLEAN,               -- For Time, AMRAP (Rx vs Scaled)
    notes TEXT,                      -- Additional completion context
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workout_completions_time ON workout_completions(time_to_complete_seconds);
CREATE INDEX idx_workout_completions_rounds ON workout_completions(rounds_completed);
CREATE INDEX idx_workout_completions_scaled ON workout_completions(is_scaled);
```

**When to create:**
- Traditional workouts: **Don't create** (volume is implicit)
- AMRAP/For Time/EMOM: **Create** after workout completion

**Examples:**

*AMRAP completion (5 rounds + 12 reps, Rx):*
```sql
INSERT INTO workout_completions (workout_id, rounds_completed, additional_reps, is_scaled)
VALUES (<workout_uuid>, 5, 12, false);
```

*For Time completion (8:07, Rx):*
```sql
INSERT INTO workout_completions (workout_id, time_to_complete_seconds, is_scaled, notes)
VALUES (<workout_uuid>, 487, false, 'Rx weight (95lbs)');
```

*EMOM completion:*
```sql
INSERT INTO workout_completions (workout_id, rounds_completed)
VALUES (<workout_uuid>, 10);
```

**Phase:** 3 (Core API)

---

### workout_sections (Optional Grouping)

Logical grouping of exercises for circuits, supersets, EMOM blocks, or Hyrox segments.

```sql
CREATE TABLE workout_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    name TEXT,  -- e.g., "Circuit A", "EMOM Block", "Superset 1", "Run 1"
    section_type TEXT NOT NULL CHECK (section_type IN (
        'standard',   -- Regular exercise grouping
        'circuit',    -- Circuit training
        'superset',   -- Superset (2-3 exercises back-to-back)
        'emom',       -- EMOM block
        'interval',   -- Interval block
        'segment'     -- Hyrox segment or timed section
    )),
    order_index INTEGER NOT NULL,
    
    -- Section-specific timing (overrides workout-level timing if present)
    -- Nullable - only populated if section has custom timing
    time_cap_seconds INTEGER,
    interval_seconds INTEGER,
    work_seconds INTEGER,
    rest_seconds INTEGER,
    rounds INTEGER,
    rest_between_rounds_seconds INTEGER,
    
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sections_workout_id ON workout_sections(workout_id);
CREATE INDEX idx_sections_workout_order ON workout_sections(workout_id, order_index);
CREATE INDEX idx_sections_type ON workout_sections(section_type);
```

**Rationale:**
- **Optional**: Traditional workouts don't need sections
- **Flexible grouping**: Supports circuits, supersets, EMOM blocks, Hyrox segments
- **Section-level timing**: Sections can override workout-level timing
  - Example: Workout has EMOM format, but one section is "For Time"
- **order_index**: Maintains section order (Strength → Circuit → Finisher)
- **iOS compatible**: No JSONB, pure relational design

**Examples:**

*Workout without sections:*
- Traditional strength training (5 exercises, no grouping needed)

*Workout with sections:*
- Section 1 (standard): Warm-up exercises
- Section 2 (circuit): 4 exercises, 3 rounds, 2-min rest between rounds
- Section 3 (emom): Cardio finisher, 5 minutes

*Hyrox with sections:*
- Section 1 (segment): 1km Run
- Section 2 (segment): 1000m SkiErg
- Section 3 (segment): 1km Run
- Section 4 (segment): 50m Sled Push
- ... (16 total sections)

**Phase:** 5 (Workouts CRUD) - Optional, can be added later if needed

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
    section_id UUID REFERENCES workout_sections(id) ON DELETE SET NULL,
    exercise_definition_id UUID REFERENCES exercise_definitions(id) ON DELETE SET NULL,
    
    name TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    notes TEXT,
    
    -- Prescribed work (for AMRAP, For Time, etc.)
    -- Nullable - only populated for formats that prescribe work
    prescribed_reps INTEGER,           -- AMRAP: reps per round, For Time: total reps
    prescribed_duration_seconds INTEGER,  -- Timed holds (planks in AMRAP/For Time)
    prescribed_distance REAL,          -- Distance-based (Hyrox runs)
    prescribed_distance_unit TEXT,     -- 'meters', 'km', 'miles'
    prescribed_weight REAL,            -- Prescribed weight (competition format)
    prescribed_weight_unit TEXT,       -- 'lbs', 'kg'
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workout_exercises_workout_id ON workout_exercises(workout_id);
CREATE INDEX idx_workout_exercises_workout_order ON workout_exercises(workout_id, order_index);
CREATE INDEX idx_workout_exercises_section_id ON workout_exercises(section_id);
CREATE INDEX idx_workout_exercises_definition_id ON workout_exercises(exercise_definition_id);
```

**Prescribed Work by Format:**

| Format | Prescribed Fields Used | Example |
|--------|----------------------|---------|
| `traditional` | None | Free-form sets |
| `emom` | `prescribed_reps` | 10 burpees per minute |
| `amrap` | `prescribed_reps` | 10 pullups per round |
| `for_time` | `prescribed_reps` | 100 pullups total |
| `tabata` | None (work time is format-level) | Max reps in 20s |
| `circuit` | None or `prescribed_reps` | 15 reps per round |
| `hyrox` | `prescribed_distance`, `prescribed_distance_unit` | 1km run, 1000m SkiErg |

**Examples:**

*AMRAP (Cindy):*
```sql
-- Exercise 1: Pull-ups
prescribed_reps = 5  -- Do 5 pullups each round

-- Exercise 2: Push-ups
prescribed_reps = 10  -- Do 10 pushups each round

-- Exercise 3: Air Squats
prescribed_reps = 15  -- Do 15 squats each round
```

*For Time (Fran 21-15-9):*
```sql
-- Round 1: 21 reps
-- Exercise 1: Thrusters
prescribed_reps = 21

-- Exercise 2: Pull-ups
prescribed_reps = 21

-- Round 2: 15 reps (create new workout_exercise records)
-- Exercise 3: Thrusters
prescribed_reps = 15

-- Exercise 4: Pull-ups
prescribed_reps = 15

-- Round 3: 9 reps
-- Exercise 5: Thrusters
prescribed_reps = 9

-- Exercise 6: Pull-ups
prescribed_reps = 9
```

*Hyrox:*
```sql
-- Section 1, Exercise 1: Run
prescribed_distance = 1.0
prescribed_distance_unit = 'km'

-- Section 2, Exercise 1: SkiErg
prescribed_distance = 1000.0
prescribed_distance_unit = 'meters'
```

**Rationale:**
- **section_id**: Optional grouping (circuits, supersets, EMOMs)
  - `NULL` for traditional workouts (no sections)
  - Set for workouts with logical grouping
- **exercise_definition_id**: Optional reference to exercise library
- **Prescribed work**: Flat columns for different prescription types
  - Reps: AMRAP, For Time, circuits
  - Duration: Timed holds in scored workouts
  - Distance: Hyrox, running workouts
  - Weight: Competition standards (Rx weight)
- **iOS compatible**: No JSONB, pure relational design

**Phase:** 5 (Workouts CRUD)

---

### exercise_sets

Stores individual sets within an exercise.

```sql
CREATE TABLE exercise_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id UUID NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
    
    -- Round tracking (for circuits, AMRAP, etc.)
    round_number INTEGER DEFAULT 1,
    set_number INTEGER,  -- Set number within this round/exercise
    
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
    rpe INTEGER CHECK (rpe BETWEEN 1 AND 10),  -- Rate of Perceived Exertion (1-10)
    
    -- Timing metadata (for intervals, EMOM, etc.)
    started_at_offset_seconds INTEGER,  -- Offset from workout start (for EMOM timing)
    rest_after_seconds INTEGER,         -- Actual rest time taken after this set
    
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
CREATE INDEX idx_exercise_sets_round ON exercise_sets(exercise_id, round_number);
```

**Rationale:**
- **round_number**: Tracks which round of a circuit/AMRAP
  - Traditional: Always `1` (single round per exercise)
  - Circuit: `1, 2, 3` (three rounds)
  - AMRAP: Increments with each completed round
- **set_number**: Set number within a round
  - Traditional: `1, 2, 3, 4` for 4 sets of bench press
  - Circuit: `1` (usually one set per round)
- **timing_metadata**: Captures EMOM timing, rest periods, etc.

**Examples:**

*Traditional Strength (Bench Press, 3 sets):*
```sql
round_number = 1, set_number = 1, weight = 225, reps = 5
round_number = 1, set_number = 2, weight = 225, reps = 5
round_number = 1, set_number = 3, weight = 225, reps = 4
```

*Circuit (3 rounds, 3 exercises):*
```sql
-- Exercise 1 (Squats)
round_number = 1, set_number = 1, weight = 185, reps = 10
round_number = 2, set_number = 1, weight = 185, reps = 10
round_number = 3, set_number = 1, weight = 185, reps = 8

-- Exercise 2 (Push-ups)
round_number = 1, set_number = 1, reps = 20
round_number = 2, set_number = 1, reps = 18
round_number = 3, set_number = 1, reps = 15
```

*AMRAP 10 minutes (as many rounds as possible):*
```sql
-- Round 1
round_number = 1, set_number = 1, reps = 10, timing_metadata = {"started_at_offset_seconds": 0}
round_number = 1, set_number = 1, reps = 10, timing_metadata = {"started_at_offset_seconds": 15}

-- Round 2
round_number = 2, set_number = 1, reps = 10, timing_metadata = {"started_at_offset_seconds": 90}
round_number = 2, set_number = 1, reps = 10, timing_metadata = {"started_at_offset_seconds": 105}

-- ... continues until time cap
```

**Phase:** 5 (Workouts CRUD)

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
('waist_circumference', 'Waist Size', 'circumference', ARRAY['inches', 'cm'], 'inches', false, 7);
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

**Phase:** 3 (Core API)

---

### user_performance_records (View)

Computed view showing user's personal records from workout data.

```sql
CREATE VIEW user_performance_records AS
SELECT 
    w.user_id,
    LOWER(REPLACE(we.name, ' ', '_')) as exercise_name,
    we.name as exercise_display_name,
    ed.exercise_type,
    ed.tracking_type,
    ed.primary_muscle_group,
    
    -- Weight/Reps metrics
    es.weight as pr_weight,
    es.measurement_unit,
    es.reps as pr_reps,
    CASE 
        WHEN ed.tracking_type = 'weight_reps' AND es.is_bodyweight = false AND es.reps BETWEEN 1 AND 10
        THEN es.weight * (1 + es.reps / 30.0)
        ELSE NULL
    END as estimated_1rm,
    
    -- Duration metrics
    es.duration_seconds as pr_duration_seconds,
    
    -- Distance metrics
    es.distance as pr_distance,
    es.distance_unit as pr_distance_unit,
    
    es.completed_at as pr_date,
    w.id as workout_id,
    w.name as workout_name
FROM exercise_sets es
JOIN workout_exercises we ON es.exercise_id = we.id
JOIN workouts w ON we.workout_id = w.id
LEFT JOIN exercise_definitions ed ON we.exercise_definition_id = ed.id
WHERE ed.tracking_type IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY w.user_id, LOWER(we.name)
    ORDER BY 
        CASE ed.tracking_type
            WHEN 'weight_reps' THEN es.weight * (1 + COALESCE(es.reps, 0) / 30.0)
            WHEN 'duration' THEN es.duration_seconds
            WHEN 'distance' THEN es.distance
            WHEN 'reps_only' THEN es.reps
            ELSE 0
        END DESC NULLS LAST
) = 1;
```

**Phase:** 5 (After workouts are implemented)

---

### trainer_client_relationships (Phase 8)

Stores trainer → client connections.

```sql
CREATE TABLE trainer_client_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(trainer_id, client_id)
);

CREATE INDEX idx_trainer_clients ON trainer_client_relationships(trainer_id, status);
CREATE INDEX idx_client_trainers ON trainer_client_relationships(client_id, status);
```

**Phase:** 8 (Trainer features)

---

### planned_workouts (Phase 9)

Stores future scheduled workouts.

```sql
CREATE TABLE planned_workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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

**Phase:** 9 (Workout planning)

---

### workout_templates (Phase 9)

Stores reusable workout templates.

```sql
CREATE TABLE workout_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    workout_format_id UUID NOT NULL REFERENCES workout_format_definitions(id),
    
    name TEXT NOT NULL,
    description TEXT,
    
    -- Sharing
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    is_official BOOLEAN NOT NULL DEFAULT FALSE,  -- Official Hyrox, Murph, etc.
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_templates_user ON workout_templates(user_id);
CREATE INDEX idx_templates_format ON workout_templates(workout_format_id);
CREATE INDEX idx_templates_public ON workout_templates(is_public) WHERE is_public = TRUE;
CREATE INDEX idx_templates_official ON workout_templates(is_official) WHERE is_official = TRUE;
```

**Seed Data (Famous Workouts):**
```sql
-- Murph (Memorial Day Challenge)
INSERT INTO workout_templates (user_id, workout_format_id, name, description, is_official)
VALUES (NULL, <for_time_uuid>, 'Murph', '1 mile run, 100 pullups, 200 pushups, 300 squats, 1 mile run', true);

-- Fran (Classic CrossFit)
INSERT INTO workout_templates (user_id, workout_format_id, name, description, is_official)
VALUES (NULL, <for_time_uuid>, 'Fran', '21-15-9 Thrusters (95/65) and Pull-ups', true);

-- Cindy (20-minute AMRAP)
WITH cindy_template AS (
    INSERT INTO workout_templates (user_id, workout_format_id, name, description, is_official)
    VALUES (NULL, <amrap_uuid>, 'Cindy', '5 Pull-ups, 10 Push-ups, 15 Air Squats', true)
    RETURNING id
)
INSERT INTO workout_template_timings (template_id, time_cap_seconds)
SELECT id, 1200 FROM cindy_template;
```

**Rationale:**
- **Slim table**: Core template fields only
- **user_id**: Can be NULL for official templates (Murph, Fran, etc.)
- **workout_format_id**: References workout format definition
- **is_official**: Built-in famous workouts (Murph, Fran, Cindy, Hyrox)
- **Timing in separate table**: Same pattern as workouts

**Phase:** 9 (Workout planning/templates)

---

### workout_template_timings (Phase 9)

Stores default timing configuration for templates (optional, 1:1 with templates).

```sql
CREATE TABLE workout_template_timings (
    template_id UUID PRIMARY KEY REFERENCES workout_templates(id) ON DELETE CASCADE,
    
    -- Same fields as workout_timings
    time_cap_seconds INTEGER,
    interval_seconds INTEGER,
    work_seconds INTEGER,
    rest_seconds INTEGER,
    rounds INTEGER,
    rest_between_rounds_seconds INTEGER,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Rationale:**
- **Optional**: Only create if template has default timing
- **1:1 relationship**: Each template has at most one timing config
- **Consistent structure**: Mirrors `workout_timings` table

**Phase:** 9 (Workout planning/templates)

---

## Workout Format Examples

### Traditional Strength Training

```sql
-- Workout record
workout_format_id = <traditional_format_uuid>
name = "Push Day"
notes = "Heavy chest focus"
-- All timing/scoring fields: NULL

-- Exercises added independently
-- Sets tracked with round_number = 1 (single round per exercise)
```

**UI Flow:**
1. User selects "Traditional" format
2. No timing configuration needed
3. Add exercises freely
4. Track sets independently per exercise

---

### EMOM (Every Minute On the Minute)

```sql
-- Workout record
workout_format_id = <emom_format_uuid>
name = "EMOM 10"
interval_seconds = 60
rounds = 10
rounds_completed = 10  -- After completion
score_notes = "All rounds completed Rx"

-- Exercises done each minute
-- Sets tracked with timing_metadata for precision
```

**UI Flow:**
1. User selects "EMOM" format
2. Configure: interval (60s), total rounds (10)
3. Add exercises to be done each minute
4. Track which rounds were completed

**Example:**
- Minute 1: 10 Burpees
- Minute 2: 15 Kettlebell Swings
- Repeat for 10 minutes (5 full cycles)

---

### AMRAP (As Many Rounds As Possible)

```sql
-- Workout record
workout_format_id = <amrap_format_uuid>
name = "Cindy"
time_cap_seconds = 600  -- 10 minutes
rounds_completed = 5
additional_reps = 12  -- Into 6th round
is_scaled = false

-- Exercises have prescribed_work: {"reps": 10}
-- Sets increment round_number: 1, 2, 3, 4, 5
```

**UI Flow:**
1. User selects "AMRAP" format
2. Configure: time cap (10 minutes)
3. Add exercises with prescribed reps per round
4. Track: How many complete rounds + partial round reps

**Example (Cindy):**
- 5 Pull-ups (prescribed: 5 reps per round)
- 10 Push-ups (prescribed: 10 reps per round)
- 15 Air Squats (prescribed: 15 reps per round)
- Complete as many rounds as possible in 10 minutes

---

### For Time

```sql
-- Workout record
workout_format_id = <for_time_format_uuid>
name = "Fran"
time_cap_seconds = 300  -- 5 min cap (optional)
time_to_complete_seconds = 243  -- 4:03
is_scaled = false
score_notes = "Rx weight (95lbs)"

-- Exercises have prescribed_work: {"total_reps": 21}
-- Then {"total_reps": 15}, then {"total_reps": 9}
```

**UI Flow:**
1. User selects "For Time" format
2. Configure: optional time cap
3. Add exercises with total reps to complete
4. Track: Time to complete all work

**Example (Fran - 21-15-9):**
- 21 Thrusters
- 21 Pull-ups
- 15 Thrusters
- 15 Pull-ups
- 9 Thrusters
- 9 Pull-ups
- Timer stops when all reps complete

---

### Tabata

```sql
-- Workout record
workout_format_id = <tabata_format_uuid>
name = "Tabata Burpees"
work_seconds = 20
rest_seconds = 10
rounds = 8

-- Each exercise gets 8 rounds
-- Sets have round_number 1-8
-- duration_seconds tracks each 20-second work interval
```

**UI Flow:**
1. User selects "Tabata" format
2. Defaults: 20s work, 10s rest, 8 rounds (can customize)
3. Add exercises
4. Each exercise done for all 8 intervals

**Example:**
- 20s: Max effort burpees
- 10s: Rest
- Repeat 8 times (4 minutes total)

---

### Circuit

```sql
-- Workout record
workout_format_id = <circuit_format_uuid>
name = "Full Body Circuit"
rounds = 3
rest_between_rounds_seconds = 120

-- Exercises done in sequence
-- After completing all exercises = 1 round
-- Sets tracked with round_number: 1, 2, 3
```

**UI Flow:**
1. User selects "Circuit" format
2. Configure: number of rounds (3), rest between rounds (2 min)
3. Add exercises in order
4. Complete all exercises = 1 round, then rest

**Example:**
- Round 1: Squats → Push-ups → Rows → Plank
- Rest 2 minutes
- Round 2: Squats → Push-ups → Rows → Plank
- Rest 2 minutes
- Round 3: Squats → Push-ups → Rows → Plank

---

### Interval Training

```sql
-- Workout record
workout_format_id = <interval_format_uuid>
name = "Sprint Intervals"
work_seconds = 45
rest_seconds = 15
rounds = 10
rest_between_rounds_seconds = 60  -- After all exercises

-- Custom work/rest intervals
-- Can combine with circuit structure
```

**UI Flow:**
1. User selects "Interval" format
2. Configure: work time, rest time, rounds, rest between cycles
3. Add exercises
4. Each exercise done for specified work/rest/rounds

---

### Hyrox

```sql
-- Workout record (simplified - actual Hyrox uses sections)
workout_format_id = <hyrox_format_uuid>
name = "Hyrox Doubles"
time_to_complete_seconds = 5400  -- 1:30:00
score_notes = "Division: Pro Men"

-- Use workout_sections for 16 segments:
-- Section 1: 1km Run
-- Section 2: 1000m SkiErg
-- Section 3: 1km Run
-- Section 4: 50m Sled Push
-- ... etc
```

**UI Flow:**
1. User selects "Hyrox" format
2. Template pre-populates 8 runs + 8 exercises
3. Track time for entire event
4. Optional: track split times per section

---

## Migrations

Migrations are stored in `api_server/migrations/` and applied via sqlx.

### Migration naming convention:
```
001_initial_schema.sql
002_add_workout_formats.sql
003_add_sections.sql
004_add_trainer_relationships.sql
005_add_planned_workouts.sql
```

### Running migrations:
```bash
cd applications/thiccc/api_server
sqlx migrate run
```

### Creating new migration:
```bash
sqlx migrate add add_new_feature
```

---

## Data Types

| Type | PostgreSQL | Rust | TypeScript |
|------|-----------|------|------------|
| ID | UUID | `Uuid` | `string` |
| User ID | UUID | `Uuid` | `string` |
| Name/Notes | TEXT | `String` | `string` |
| Weight | REAL | `f32` | `number` |
| Reps/RPE | INTEGER | `i32` | `number` |
| JSONB | JSONB | `serde_json::Value` | `object` |
| Timestamp | TIMESTAMPTZ | `DateTime<Utc>` | `Date` or `string` (ISO 8601) |
| Date | DATE | `NaiveDate` | `string` (YYYY-MM-DD) |
| Boolean | BOOLEAN | `bool` | `boolean` |

---

## Query Examples

### Get user's workouts by format

```sql
-- Get all AMRAP workouts with timing and completion
SELECT 
    w.*,
    wfd.display_name as format_name,
    wt.time_cap_seconds,
    wc.rounds_completed,
    wc.additional_reps,
    wc.is_scaled
FROM workouts w
JOIN workout_format_definitions wfd ON w.workout_format_id = wfd.id
LEFT JOIN workout_timings wt ON wt.workout_id = w.id
LEFT JOIN workout_completions wc ON wc.workout_id = w.id
WHERE w.user_id = $1 AND wfd.format_key = 'amrap'
ORDER BY w.started_at DESC;

-- Get EMOM workouts with timing details
SELECT 
    w.name, 
    w.started_at,
    wt.interval_seconds,
    wt.rounds,
    wc.rounds_completed,
    wfd.display_name as format_name
FROM workouts w
JOIN workout_format_definitions wfd ON w.workout_format_id = wfd.id
LEFT JOIN workout_timings wt ON wt.workout_id = w.id
LEFT JOIN workout_completions wc ON wc.workout_id = w.id
WHERE w.user_id = $1 AND wfd.format_key = 'emom';

-- Get workouts by format category (all cardio formats)
SELECT w.*, wfd.display_name, wfd.category
FROM workouts w
JOIN workout_format_definitions wfd ON w.workout_format_id = wfd.id
WHERE w.user_id = $1 AND wfd.category = 'cardio'
ORDER BY w.started_at DESC;

-- Get traditional workouts (no timing/scoring needed)
SELECT w.*, wfd.display_name
FROM workouts w
JOIN workout_format_definitions wfd ON w.workout_format_id = wfd.id
WHERE w.user_id = $1 AND wfd.format_key = 'traditional'
ORDER BY w.started_at DESC;
```

### Get circuit workout with all rounds

```sql
-- Get circuit workout with exercises and sets grouped by round
SELECT 
    w.name as workout_name,
    we.name as exercise_name,
    es.round_number,
    es.weight,
    es.reps,
    es.completed_at
FROM workouts w
JOIN workout_exercises we ON we.workout_id = w.id
JOIN exercise_sets es ON es.exercise_id = we.id
WHERE w.id = $1
ORDER BY es.round_number, we.order_index, es.set_number;
```

### Get complete workout with format, timing, and scoring

```sql
-- Get full workout details (all data)
SELECT 
    w.*,
    wfd.format_key,
    wfd.display_name as format_name,
    wfd.category,
    wt.*,
    wc.*
FROM workouts w
JOIN workout_format_definitions wfd ON w.workout_format_id = wfd.id
LEFT JOIN workout_timings wt ON wt.workout_id = w.id
LEFT JOIN workout_completions wc ON wc.workout_id = w.id
WHERE w.id = $1;

-- Get For Time workout with completion time
SELECT 
    w.name,
    w.started_at,
    w.completed_at,
    wfd.display_name as format_name,
    wt.time_cap_seconds,
    wc.time_to_complete_seconds,
    wc.is_scaled,
    wc.notes as completion_notes
FROM workouts w
JOIN workout_format_definitions wfd ON w.workout_format_id = wfd.id
LEFT JOIN workout_timings wt ON wt.workout_id = w.id
LEFT JOIN workout_completions wc ON wc.workout_id = w.id
WHERE w.id = $1;

-- Get workout formats available for selection (UI)
SELECT 
    id,
    format_key,
    display_name,
    description,
    category,
    is_timed,
    is_scored,
    default_rounds,
    default_interval_seconds
FROM workout_format_definitions
WHERE is_active = true
ORDER BY display_order;

-- Get leaderboard for a specific AMRAP workout (by rounds completed)
SELECT 
    u.email,
    w.name,
    w.started_at,
    wc.rounds_completed,
    wc.additional_reps,
    wc.is_scaled
FROM workouts w
JOIN users u ON w.user_id = u.id
JOIN workout_format_definitions wfd ON w.workout_format_id = wfd.id
JOIN workout_completions wc ON wc.workout_id = w.id
WHERE wfd.format_key = 'amrap' 
  AND w.name = 'Cindy'
  AND wc.is_scaled = false
ORDER BY wc.rounds_completed DESC, wc.additional_reps DESC
LIMIT 10;
```

---

## Schema Evolution Strategy

### Phase 3 (Core API):
- Create base tables: users, workouts, exercises, sets
- **Include** workout_format and timing_config from start
- **Omit** workout_sections (add later if needed)

### Phase 5 (Workouts CRUD):
- Add workout_sections if circuits/EMOMs needed
- Test with traditional, AMRAP, For Time formats

### Phase 9 (Templates):
- Add workout_templates with same format support
- Seed official templates (Murph, Fran, Cindy, etc.)

---

## Benefits of This Design

- ✅ **iOS Compatible**: No JSONB - works on both PostgreSQL AND SQLite!
- ✅ **Slim Core Tables**: `workouts` table has only 8 columns (minimal bloat)
- ✅ **Optional Complexity**: Simple workouts don't create timing/scoring records
- ✅ **1:1 Relationships**: Format-specific data isolated in child tables
- ✅ **Type-Safe Queries**: Direct column access, no JSON parsing needed
- ✅ **Forward Compatible**: Add new formats via reference data + new columns
- ✅ **UX-Friendly**: Reference table enables format selection UI with metadata
- ✅ **Round Tracking**: Circuit/AMRAP support built-in via `round_number`
- ✅ **Sectioning**: Optional `workout_sections` for complex structures (Hyrox, hybrid)
- ✅ **No Over-Engineering**: Traditional workouts = 1 INSERT into `workouts` only
- ✅ **Easy Validation**: Frontend knows which fields required per format
- ✅ **Indexable**: Can efficiently filter/sort on timing and scoring fields
- ✅ **Clean Separation**: Core data vs timing config vs scoring results

---

## Next Steps

1. **Phase 3**: Create migration `001_initial_schema.sql` with:
   - `users` table
   - `workout_format_definitions` table (with seed data)
   - `workouts` table (with FK to format definitions)
   - `exercise_definitions` table
   - `workout_exercises` table
   - `exercise_sets` table
   - `measurement_definitions` table
   - `user_body_measurements` table

2. **Phase 5**: Test with multiple workout formats
   - Build traditional strength training first
   - Add AMRAP support (test `round_number` and scoring fields)
   - Add circuit format (test multi-round tracking)
   - Optionally add `workout_sections` table if needed

3. **Phase 9**: Add templates system
   - Add `workout_templates` table
   - Seed famous workouts (Murph, Fran, Cindy, Helen)
   - Add `planned_workouts` table

4. **Future format additions**:
   - Add new row to `workout_format_definitions`
   - If new timing concept needed: Add nullable column to `workouts` (migration)
   - Update docs with new format examples

