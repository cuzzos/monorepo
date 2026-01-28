//! Effect types for the Thiccc application.
//!
//! This module defines the capabilities the Rust core can request from
//! the platform shell (iOS/Android).

use crux_core::{macros::effect, render::RenderOperation};

use crate::operations::{DatabaseOperation, StorageOperation, TimerOperation};

// =============================================================================
// MARK: - Effects
// =============================================================================

/// Effects the Core will request from the Shell.
///
/// Each variant represents a different capability that the platform shell
/// must implement. The shell receives these effects, performs the platform
/// operation, and sends the result back via `handle_response`.
///
/// The `#[effect(typegen)]` macro generates:
/// - `From<Request<Op>>` implementations for each operation type
/// - TypeGen registration for Swift/Kotlin code generation
#[effect(typegen)]
pub enum Effect {
    /// Request a UI re-render
    Render(RenderOperation),
    /// Database operations (save/load workouts to GRDB)
    Database(DatabaseOperation),
    /// File storage operations (current workout persistence)
    Storage(StorageOperation),
    /// Timer operations (workout duration tracking)
    Timer(TimerOperation),
}

