// /shared/src/lib.rs

//! Thiccc shared core library.
//!
//! This crate contains all the shared business logic for the Thiccc
//! workout tracking application, built using the Crux framework.
//!
//! # Architecture
//!
//! - `app` - The Crux application with events, model, and update logic
//! - `models` - Core data models (Workout, Exercise, ExerciseSet, etc.)
//! - `id` - Type-safe ID wrapper with UUID validation
//! - `operations` - Platform operations for shell communication

pub mod app;
pub mod id;
pub mod models;
pub mod operations;

use std::sync::LazyLock;

pub use crux_core::{bridge::Bridge, Core, Request};

// Re-export all public types
pub use app::*;
pub use id::Id;
pub use models::*;
pub use operations::*;

// TODO hide this plumbing

#[cfg(not(target_family = "wasm"))]
uniffi::include_scaffolding!("shared");

static CORE: LazyLock<Bridge<Thiccc>> = LazyLock::new(|| Bridge::new(Core::new()));

/// Ask the core to process an event
/// # Panics
/// If the core fails to process the event
#[cfg_attr(target_family = "wasm", wasm_bindgen::prelude::wasm_bindgen)]
#[must_use]
pub fn process_event(data: &[u8]) -> Vec<u8> {
    match CORE.process_event(data) {
        Ok(effects) => effects,
        Err(e) => panic!("{e}"),
    }
}

/// Ask the core to handle a response
/// # Panics
/// If the core fails to handle the response
#[cfg_attr(target_family = "wasm", wasm_bindgen::prelude::wasm_bindgen)]
#[must_use]
pub fn handle_response(id: u32, data: &[u8]) -> Vec<u8> {
    match CORE.handle_response(id, data) {
        Ok(effects) => effects,
        Err(e) => panic!("{e}"),
    }
}

/// Ask the core to render the view
/// # Panics
/// If the view cannot be serialized
#[cfg_attr(target_family = "wasm", wasm_bindgen::prelude::wasm_bindgen)]
#[must_use]
pub fn view() -> Vec<u8> {
    match CORE.view() {
        Ok(view) => view,
        Err(e) => panic!("{e}"),
    }
}
