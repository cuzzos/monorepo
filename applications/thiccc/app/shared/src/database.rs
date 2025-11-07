// Database layer for SQLite operations
use rusqlite::{Connection, Result, params};
use serde_json;
use crate::models::{Workout, Exercise, ExerciseSet};

pub struct Database {
    conn: Connection,
}

impl Database {
    pub fn new(path: &str) -> Result<Self> {
        let conn = Connection::open(path)?;
        let mut db = Database { conn };
        db.init_schema()?;
        Ok(db)
    }
    
    fn init_schema(&mut self) -> Result<()> {
        // Enable foreign keys
        self.conn.execute("PRAGMA foreign_keys = ON", [])?;
        
        // Create workouts table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS workouts (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                startTimestamp INTEGER NOT NULL,
                note TEXT,
                duration INTEGER,
                endTimestamp INTEGER
            )
            "#,
            [],
        )?;
        
        // Create exercises table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS exercises (
                id TEXT PRIMARY KEY,
                workoutId TEXT NOT NULL,
                supersetId INTEGER,
                name TEXT NOT NULL,
                pinnedNotes TEXT,
                notes TEXT,
                duration INTEGER,
                type TEXT NOT NULL,
                weightUnit TEXT,
                defaultWarmUpTime INTEGER,
                defaultRestTime INTEGER,
                bodyPart TEXT,
                FOREIGN KEY(workoutId) REFERENCES workouts(id) ON DELETE CASCADE
            )
            "#,
            [],
        )?;
        
        // Create index on exercises.workoutId
        self.conn.execute(
            "CREATE INDEX IF NOT EXISTS exercises_workoutId ON exercises(workoutId)",
            [],
        )?;
        
        // Create exerciseSets table
        self.conn.execute(
            r#"
            CREATE TABLE IF NOT EXISTS exerciseSets (
                id TEXT PRIMARY KEY,
                exerciseId TEXT NOT NULL,
                workoutId TEXT NOT NULL,
                setIndex INTEGER NOT NULL,
                type TEXT NOT NULL,
                weightUnit TEXT,
                suggest TEXT,
                actual TEXT,
                FOREIGN KEY(exerciseId) REFERENCES exercises(id) ON DELETE CASCADE
            )
            "#,
            [],
        )?;
        
        Ok(())
    }
    
    // Workout operations
    pub fn save_workout(&mut self, workout: &Workout) -> Result<()> {
        let tx = self.conn.transaction()?;
        
        // Save workout
        tx.execute(
            "INSERT OR REPLACE INTO workouts (id, name, startTimestamp, note, duration, endTimestamp) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                workout.id.to_string(),
                workout.name,
                workout.start_timestamp.timestamp(),
                workout.note,
                workout.duration,
                workout.end_timestamp.map(|dt| dt.timestamp())
            ],
        )?;
        
        // Save exercises
        for exercise in &workout.exercises {
            let pinned_notes_json = serde_json::to_string(&exercise.pinned_notes).unwrap_or_default();
            let notes_json = serde_json::to_string(&exercise.notes).unwrap_or_default();
            let body_part_json = exercise.body_part.as_ref()
                .and_then(|bp| serde_json::to_string(bp).ok());
            
            tx.execute(
                "INSERT OR REPLACE INTO exercises (id, workoutId, supersetId, name, pinnedNotes, notes, duration, type, weightUnit, defaultWarmUpTime, defaultRestTime, bodyPart) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)",
                params![
                    exercise.id.to_string(),
                    exercise.workout_id.to_string(),
                    exercise.superset_id,
                    exercise.name,
                    pinned_notes_json,
                    notes_json,
                    exercise.duration,
                    serde_json::to_string(&exercise.exercise_type).unwrap_or_default(),
                    exercise.weight_unit.as_ref().map(|wu| serde_json::to_string(wu).unwrap_or_default()),
                    exercise.default_warm_up_time,
                    exercise.default_rest_time,
                    body_part_json
                ],
            )?;
            
            // Save sets
            for set in &exercise.sets {
                let suggest_json = serde_json::to_string(&set.suggest).unwrap_or_default();
                let actual_json = serde_json::to_string(&set.actual).unwrap_or_default();
                
                tx.execute(
                    "INSERT OR REPLACE INTO exerciseSets (id, exerciseId, workoutId, setIndex, type, weightUnit, suggest, actual) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
                    params![
                        set.id.to_string(),
                        set.exercise_id.to_string(),
                        set.workout_id.to_string(),
                        set.set_index,
                        serde_json::to_string(&set.set_type).unwrap_or_default(),
                        set.weight_unit.as_ref().map(|wu| serde_json::to_string(wu).unwrap_or_default()),
                        suggest_json,
                        actual_json
                    ],
                )?;
            }
        }
        
        tx.commit()?;
        Ok(())
    }
    
    pub fn load_workouts(&self) -> Result<Vec<Workout>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, name, startTimestamp, note, duration, endTimestamp FROM workouts ORDER BY startTimestamp DESC"
        )?;
        
        let workout_iter = stmt.query_map([], |row| {
            let id_str: String = row.get(0)?;
            let id = uuid::Uuid::parse_str(&id_str).map_err(|_| rusqlite::Error::InvalidColumnType(0, "uuid".to_string(), rusqlite::types::Type::Text))?;
            let start_ts: i64 = row.get(2)?;
            let end_ts: Option<i64> = row.get(5)?;
            
            Ok(Workout {
                id,
                name: row.get(1)?,
                start_timestamp: chrono::DateTime::from_timestamp(start_ts, 0)
                    .unwrap_or_default()
                    .with_timezone(&chrono::Utc),
                note: row.get(3)?,
                duration: row.get(4)?,
                end_timestamp: end_ts.and_then(|ts| chrono::DateTime::from_timestamp(ts, 0))
                    .map(|dt| dt.with_timezone(&chrono::Utc)),
                exercises: Vec::new(),
            })
        })?;
        
        let mut workouts = Vec::new();
        for workout_result in workout_iter {
            let mut workout = workout_result?;
            workout.exercises = self.load_exercises_for_workout(&workout.id)?;
            workouts.push(workout);
        }
        
        Ok(workouts)
    }
    
    pub fn load_workout(&self, workout_id: &uuid::Uuid) -> Result<Option<Workout>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, name, startTimestamp, note, duration, endTimestamp FROM workouts WHERE id = ?1"
        )?;
        
        let workout_id_str = workout_id.to_string();
        let mut workout_iter = stmt.query_map(params![workout_id_str], |row| {
            let id_str: String = row.get(0)?;
            let id = uuid::Uuid::parse_str(&id_str).map_err(|_| rusqlite::Error::InvalidColumnType(0, "uuid".to_string(), rusqlite::types::Type::Text))?;
            let start_ts: i64 = row.get(2)?;
            let end_ts: Option<i64> = row.get(5)?;
            
            Ok(Workout {
                id,
                name: row.get(1)?,
                start_timestamp: chrono::DateTime::from_timestamp(start_ts, 0)
                    .unwrap_or_default()
                    .with_timezone(&chrono::Utc),
                note: row.get(3)?,
                duration: row.get(4)?,
                end_timestamp: end_ts.and_then(|ts| chrono::DateTime::from_timestamp(ts, 0))
                    .map(|dt| dt.with_timezone(&chrono::Utc)),
                exercises: Vec::new(),
            })
        })?;
        
        if let Some(workout_result) = workout_iter.next() {
            let mut workout = workout_result?;
            workout.exercises = self.load_exercises_for_workout(&workout.id)?;
            Ok(Some(workout))
        } else {
            Ok(None)
        }
    }
    
    fn load_exercises_for_workout(&self, workout_id: &uuid::Uuid) -> Result<Vec<Exercise>> {
        use crate::models::ExerciseType;
        
        let mut stmt = self.conn.prepare(
            "SELECT id, workoutId, supersetId, name, pinnedNotes, notes, duration, type, weightUnit, defaultWarmUpTime, defaultRestTime, bodyPart FROM exercises WHERE workoutId = ?1 ORDER BY id"
        )?;
        
        let workout_id_str = workout_id.to_string();
        let exercise_iter = stmt.query_map(params![workout_id_str], |row| {
            let id_str: String = row.get(0)?;
            let id = uuid::Uuid::parse_str(&id_str).map_err(|_| rusqlite::Error::InvalidColumnType(0, "uuid".to_string(), rusqlite::types::Type::Text))?;
            let workout_id_str: String = row.get(1)?;
            let workout_id = uuid::Uuid::parse_str(&workout_id_str).map_err(|_| rusqlite::Error::InvalidColumnType(1, "uuid".to_string(), rusqlite::types::Type::Text))?;
            
            let pinned_notes_json: String = row.get(4).unwrap_or_default();
            let notes_json: String = row.get(5).unwrap_or_default();
            let type_str: String = row.get(7)?;
            let weight_unit_str: Option<String> = row.get(8)?;
            let body_part_json: Option<String> = row.get(11)?;
            
            Ok(Exercise {
                id,
                superset_id: row.get(2)?,
                workout_id,
                name: row.get(3)?,
                pinned_notes: serde_json::from_str(&pinned_notes_json).unwrap_or_default(),
                notes: serde_json::from_str(&notes_json).unwrap_or_default(),
                duration: row.get(6)?,
                exercise_type: serde_json::from_str(&type_str).unwrap_or(ExerciseType::Unknown),
                weight_unit: weight_unit_str.and_then(|wu| serde_json::from_str(&wu).ok()),
                default_warm_up_time: row.get(9)?,
                default_rest_time: row.get(10)?,
                sets: Vec::new(),
                body_part: body_part_json.and_then(|bp| serde_json::from_str(&bp).ok()),
            })
        })?;
        
        let mut exercises = Vec::new();
        for exercise_result in exercise_iter {
            let mut exercise = exercise_result?;
            exercise.sets = self.load_sets_for_exercise(&exercise.id)?;
            exercises.push(exercise);
        }
        
        Ok(exercises)
    }
    
    fn load_sets_for_exercise(&self, exercise_id: &uuid::Uuid) -> Result<Vec<ExerciseSet>> {
        use crate::models::SetType;
        
        let mut stmt = self.conn.prepare(
            "SELECT id, exerciseId, workoutId, setIndex, type, weightUnit, suggest, actual FROM exerciseSets WHERE exerciseId = ?1 ORDER BY setIndex"
        )?;
        
        let exercise_id_str = exercise_id.to_string();
        let set_iter = stmt.query_map(params![exercise_id_str], |row| {
            let id_str: String = row.get(0)?;
            let id = uuid::Uuid::parse_str(&id_str).map_err(|_| rusqlite::Error::InvalidColumnType(0, "uuid".to_string(), rusqlite::types::Type::Text))?;
            let exercise_id_str: String = row.get(1)?;
            let exercise_id = uuid::Uuid::parse_str(&exercise_id_str).map_err(|_| rusqlite::Error::InvalidColumnType(1, "uuid".to_string(), rusqlite::types::Type::Text))?;
            let workout_id_str: String = row.get(2)?;
            let workout_id = uuid::Uuid::parse_str(&workout_id_str).map_err(|_| rusqlite::Error::InvalidColumnType(2, "uuid".to_string(), rusqlite::types::Type::Text))?;
            
            let type_str: String = row.get(4)?;
            let weight_unit_str: Option<String> = row.get(5)?;
            let suggest_json: String = row.get(6).unwrap_or_default();
            let actual_json: String = row.get(7).unwrap_or_default();
            
            Ok(ExerciseSet {
                id,
                set_type: serde_json::from_str(&type_str).unwrap_or(SetType::Working),
                weight_unit: weight_unit_str.and_then(|wu| serde_json::from_str(&wu).ok()),
                suggest: serde_json::from_str(&suggest_json).unwrap_or_default(),
                actual: serde_json::from_str(&actual_json).unwrap_or_default(),
                is_completed: false, // This is computed, not stored
                exercise_id,
                workout_id,
                set_index: row.get(3)?,
            })
        })?;
        
        let mut sets = Vec::new();
        for set_result in set_iter {
            sets.push(set_result?);
        }
        
        Ok(sets)
    }
}

