# Adding Features to Thiccc - Developer Guide

**Last Updated:** November 2025 (after Phase 1-3 refactoring)

This guide explains how to add new features to the Thiccc application following the modular architecture established in the refactoring phases.

## 📋 Table of Contents

- [Quick Reference](#quick-reference)
- [Architecture Overview](#architecture-overview)
- [Step-by-Step: Adding a New Feature](#step-by-step-adding-a-new-feature)
- [Examples](#examples)
- [Testing Strategy](#testing-strategy)
- [Common Patterns](#common-patterns)

---

## Quick Reference

### File Structure (After Refactoring)

```
app/shared/src/app/
├── mod.rs                    # Main orchestration (DO NOT add event logic here)
├── events.rs                 # ADD: New event types
├── model.rs                  # ADD: New state fields
├── view_models.rs            # ADD: New ViewModels
├── effects.rs                # ADD: New capability types (rarely needed)
├── update/                   # ADD: New feature module OR extend existing
│   ├── mod.rs                # ADD: Route new events
│   ├── app_lifecycle.rs
│   ├── workout.rs
│   ├── exercise.rs
│   ├── sets.rs
│   ├── timer.rs
│   ├── history.rs
│   ├── import_export.rs
│   ├── plate_calculator.rs
│   └── capabilities.rs
└── tests/                    # ADD: Tests for new feature
    ├── mod.rs
    ├── event_tests.rs        # Test event serialization
    ├── model_tests.rs        # Test model methods
    ├── view_model_tests.rs   # Test ViewModel serialization
    └── integration_tests.rs  # Test update + view cycles
```

---

## Architecture Overview

The Thiccc app follows the **Crux framework pattern**:

1. **Events** (`events.rs`) - User actions & system responses
2. **Model** (`model.rs`) - Core application state
3. **Update** (`update/`) - Business logic organized by feature
4. **ViewModel** (`view_models.rs`) - UI-friendly data
5. **View** (Swift/iOS) - Platform-specific UI rendering

### Data Flow

```
User Action (Swift)
    ↓
Event (serialized)
    ↓
update::handle_event() (routes to feature module)
    ↓
Feature Module (e.g., update/workout.rs)
    ↓
Model mutation + Command<Effect, Event>
    ↓
view() method
    ↓
ViewModel (serialized)
    ↓
Swift UI Update
```

---

## Step-by-Step: Adding a New Feature

### Example: Adding "Workout Templates"

Let's add a feature to save/load workout templates.

### Step 1: Define Events

**File:** `app/events.rs`

Add new event variants:

```rust
pub enum Event {
    // ... existing events ...
    
    // ===== Workout Templates =====
    /// Save current workout as a template
    SaveWorkoutAsTemplate { template_name: String },
    
    /// Load a workout template
    LoadWorkoutTemplate { template_id: String },
    
    /// Delete a workout template
    DeleteWorkoutTemplate { template_id: String },
    
    /// Show template picker view
    ShowTemplatePicker,
    
    /// Dismiss template picker view
    DismissTemplatePicker,
}
```

### Step 2: Update Model

**File:** `app/model.rs`

Add state fields:

```rust
#[derive(Debug)]
pub struct Model {
    // ... existing fields ...
    
    // ===== Template State =====
    /// Available workout templates
    pub workout_templates: Vec<WorkoutTemplate>,
    
    /// Whether template picker is shown
    pub showing_template_picker: bool,
}

impl Default for Model {
    fn default() -> Self {
        Self {
            // ... existing defaults ...
            workout_templates: Vec::new(),
            showing_template_picker: false,
        }
    }
}
```

### Step 3: Create Update Module

**File:** `app/update/templates.rs` (NEW FILE)

```rust
//! Workout template event handlers.
//!
//! Handles saving, loading, and managing workout templates.

use crux_core::{render::render, Command};

use crate::models::{Workout, WorkoutTemplate};
use crate::operations::DatabaseOperation;

use super::super::{Effect, Event, Model};

/// Handle template events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        Event::SaveWorkoutAsTemplate { template_name } => {
            if let Some(workout) = &model.current_workout {
                let template = WorkoutTemplate::from_workout(workout, template_name);
                model.workout_templates.push(template.clone());
                
                // Save to database
                let template_json = serde_json::to_string(&template)
                    .unwrap_or_else(|_| "{}".to_string());
                Command::request_from_shell(DatabaseOperation::SaveTemplate(template_json))
                    .then_send(|result| Event::DatabaseResponse { result })
            } else {
                model.error_message = Some("No active workout to save as template".to_string());
                render()
            }
        }
        
        Event::LoadWorkoutTemplate { template_id } => {
            // Find template and create workout from it
            if let Some(template) = model.workout_templates.iter().find(|t| t.id == template_id) {
                model.current_workout = Some(Workout::from_template(template));
                model.showing_template_picker = false;
                model.error_message = None;
            } else {
                model.error_message = Some("Template not found".to_string());
            }
            render()
        }
        
        Event::DeleteWorkoutTemplate { template_id } => {
            model.workout_templates.retain(|t| t.id != template_id);
            // Delete from database
            Command::request_from_shell(DatabaseOperation::DeleteTemplate(template_id))
                .then_send(|result| Event::DatabaseResponse { result })
        }
        
        Event::ShowTemplatePicker => {
            model.showing_template_picker = true;
            render()
        }
        
        Event::DismissTemplatePicker => {
            model.showing_template_picker = false;
            render()
        }
        
        _ => unreachable!("templates module received wrong event type"),
    }
}
```

### Step 4: Register Module

**File:** `app/update/mod.rs`

Add module declaration and routing:

```rust
// Add module declaration
mod templates;

// Add to handle_event routing
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        // ... existing routes ...
        
        // Workout Templates
        Event::SaveWorkoutAsTemplate { .. }
        | Event::LoadWorkoutTemplate { .. }
        | Event::DeleteWorkoutTemplate { .. }
        | Event::ShowTemplatePicker
        | Event::DismissTemplatePicker => templates::handle_event(event, model),
    }
}
```

### Step 5: Add ViewModels

**File:** `app/view_models.rs`

```rust
/// ViewModel for workout templates list
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct TemplatePickerViewModel {
    /// Available templates
    pub templates: Vec<TemplateItemViewModel>,
    /// Whether picker is shown
    pub is_shown: bool,
}

/// ViewModel for a single template item
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct TemplateItemViewModel {
    /// Template ID
    pub id: String,
    /// Template name
    pub name: String,
    /// Number of exercises
    pub exercise_count: usize,
}
```

Update root `ViewModel` to include templates:

```rust
#[derive(Serialize, Deserialize, Clone, Debug, Default)]
pub struct ViewModel {
    // ... existing fields ...
    pub template_picker: TemplatePickerViewModel,
}
```

### Step 6: Update View Builder

**File:** `app/mod.rs`

Add a method to build the template picker view:

```rust
impl Thiccc {
    // ... existing methods ...
    
    /// Builds the TemplatePickerViewModel from the current Model state.
    fn build_template_picker_view(&self, model: &Model) -> TemplatePickerViewModel {
        let templates = model
            .workout_templates
            .iter()
            .map(|template| TemplateItemViewModel {
                id: template.id.to_string(),
                name: template.name.clone(),
                exercise_count: template.exercises.len(),
            })
            .collect();
        
        TemplatePickerViewModel {
            templates,
            is_shown: model.showing_template_picker,
        }
    }
}
```

Update `view()` method:

```rust
fn view(&self, model: &Self::Model) -> Self::ViewModel {
    ViewModel {
        // ... existing fields ...
        template_picker: self.build_template_picker_view(model),
    }
}
```

### Step 7: Write Tests

**File:** `app/tests/integration_tests.rs`

```rust
#[test]
fn test_save_workout_as_template() {
    let app = Thiccc;
    let mut model = Model::default();
    
    // Start workout and add an exercise
    app.update(Event::StartWorkout, &mut model, &());
    app.update(
        Event::AddExercise {
            name: "Bench Press".to_string(),
            exercise_type: "barbell".to_string(),
            muscle_group: "chest".to_string(),
        },
        &mut model,
        &(),
    );
    
    // Save as template
    app.update(
        Event::SaveWorkoutAsTemplate {
            template_name: "Push Day".to_string(),
        },
        &mut model,
        &(),
    );
    
    // Verify template was saved
    assert_eq!(model.workout_templates.len(), 1);
    assert_eq!(model.workout_templates[0].name, "Push Day");
}

#[test]
fn test_load_workout_template() {
    // ... similar test for loading
}
```

### Step 8: Verify

```bash
cd app/shared

# Check compilation
cargo check

# Run tests
cargo test --lib

# Build for iOS (includes TypeGen)
cargo build
```

---

## Examples

### Small Feature: Add "Workout Rating"

**1. Event** (`events.rs`):
```rust
Event::RateWorkout { rating: i32 },
```

**2. Model** (`model.rs`):
```rust
// In Workout struct (models.rs)
pub rating: Option<i32>,
```

**3. Update** (add to existing `update/workout.rs`):
```rust
Event::RateWorkout { rating } => {
    if let Some(workout) = &mut model.current_workout {
        workout.rating = Some(rating);
    }
    render()
}
```

**4. ViewModel** (`view_models.rs`):
```rust
// In WorkoutViewModel
pub rating: Option<i32>,
```

**5. Update routing** (`update/mod.rs`):
```rust
Event::RateWorkout { .. } => workout::handle_event(event, model),
```

---

## Testing Strategy

### Test Hierarchy

1. **Event Serialization Tests** (`event_tests.rs`)
   - Test that events serialize/deserialize correctly
   - Required for TypeGen compatibility

2. **Model Tests** (`model_tests.rs`)
   - Test model helper methods
   - Test state calculations

3. **ViewModel Tests** (`view_model_tests.rs`)
   - Test ViewModel serialization
   - Test default implementations

4. **Integration Tests** (`integration_tests.rs`)
   - Test full update + view cycle
   - Test event → model → viewModel flow
   - Test error handling

### Test Pattern

```rust
#[test]
fn test_my_feature_flow() {
    let app = Thiccc;
    let mut model = Model::default();
    
    // 1. Trigger event
    app.update(Event::MyFeature { ... }, &mut model, &());
    
    // 2. Verify model state
    assert_eq!(model.my_field, expected_value);
    
    // 3. Verify view state
    let view = app.view(&model);
    assert_eq!(view.my_view_field, expected_view_value);
}
```

---

## Common Patterns

### Pattern 1: Modal Views

```rust
// Event
Event::ShowMyModal, Event::DismissMyModal

// Model
pub showing_my_modal: bool,

// Update
Event::ShowMyModal => {
    model.showing_my_modal = true;
    render()
}
Event::DismissMyModal => {
    model.showing_my_modal = false;
    render()
}

// ViewModel
pub showing_my_modal: bool,
```

### Pattern 2: Async Operations (Database/Network)

```rust
// Event to trigger
Event::LoadData => {
    model.is_loading = true;
    Command::request_from_shell(DatabaseOperation::LoadData)
        .then_send(|result| Event::DatabaseResponse { result })
}

// Event to handle response
Event::DatabaseResponse { result } => {
    model.is_loading = false;
    match result {
        DatabaseResult::DataLoaded { data } => {
            model.my_data = data;
        }
    }
    render()
}
```

### Pattern 3: String ID Validation

```rust
Event::MyEvent { id } => {
    match Id::from_string(id) {
        Ok(validated_id) => {
            // Use validated_id
        }
        Err(e) => {
            model.error_message = Some(format!("Invalid ID: {}", e));
        }
    }
    render()
}
```

### Pattern 4: Capability Requests

```rust
// Trigger operation
Command::request_from_shell(MyOperation::DoSomething)
    .then_send(|result| Event::MyCapabilityResponse { result })

// Multiple operations
Command::all([
    Command::request_from_shell(Operation1),
    Command::request_from_shell(Operation2),
    render(),
])
```

---

## Common Pitfalls

### ❌ Don't: Add business logic in `mod.rs`

```rust
// BAD
fn update(...) -> Command<Effect, Event> {
    match event {
        Event::MyEvent => {
            // 50 lines of logic here
            model.do_something();
            ...
        }
    }
}
```

### ✅ Do: Delegate to feature modules

```rust
// GOOD
fn update(...) -> Command<Effect, Event> {
    update::handle_event(event, model)
}
```

### ❌ Don't: Mix feature concerns

```rust
// BAD - workout.rs handling exercise details
pub fn handle_event(event: Event, model: &mut Model) {
    match event {
        Event::AddExercise { .. } => { /* detailed exercise logic */ }
    }
}
```

### ✅ Do: Keep modules focused

```rust
// GOOD - workout.rs delegates to exercise.rs
// Routing in update/mod.rs handles this
```

### ❌ Don't: Forget to update routing

```rust
// BAD - Added event but forgot to route it
Event::NewFeature { .. } => { /* No handler! */ }
```

### ✅ Do: Always update `update/mod.rs` routing

```rust
// GOOD
Event::NewFeature { .. } => my_feature::handle_event(event, model),
```

---

## Checklist

When adding a new feature:

- [ ] Add event(s) to `events.rs`
- [ ] Add state fields to `model.rs` (and Default impl)
- [ ] Create or update feature module in `update/`
- [ ] Add routing in `update/mod.rs`
- [ ] Add ViewModels to `view_models.rs`
- [ ] Add view builder method in `mod.rs`
- [ ] Update `view()` method to include new ViewModel
- [ ] Write tests in `tests/`
- [ ] Run `cargo test --lib`
- [ ] Run `cargo build` (generates Swift types)
- [ ] Implement Swift UI (if needed)

---

## Need Help?

1. **Check existing patterns**: Look at similar features in `update/`
2. **Read the docs**: `docs/ARCHITECTURE.md`, `docs/SHARED-CRATE-MAP.md`
3. **Check Crux examples**: https://github.com/redbadger/crux/tree/master/examples

**Questions?** Review similar event handlers in the `update/` modules to see the pattern in action!

