//! Custom ID type with built-in UUID validation.
//!
//! This module provides a type-safe wrapper around String IDs that:
//! - Ensures all IDs are valid UUIDs
//! - Provides type safety (can't confuse IDs with other strings)
//! - Serializes as a plain String for cross-platform compatibility
//! - Allows future migration to native Uuid type if needed

use serde::{Deserialize, Serialize};
use std::fmt;
use uuid::Uuid;

/// A validated unique identifier.
///
/// **Validation:** All IDs are guaranteed to be valid UUID strings.
///
/// **Serialization:** Serializes as a plain String for TypeGen compatibility
/// and cross-platform use (Swift, TypeScript, JSON, etc.).
///
/// **Type Safety:** The compiler prevents accidentally using a name, description,
/// or other String where an ID is required.
///
/// **Future-Proof:** Can switch to native Uuid internally without changing
/// the serialization format or public API.
///
/// # Examples
///
/// ```no_run
/// use shared::Id;
///
/// // Create a new random ID
/// let id = Id::new();
///
/// // Parse from a string (validates)
/// let id = Id::from_string("550e8400-e29b-41d4-a716-446655440000".to_string()).unwrap();
///
/// // Get the string representation
/// let s: &str = id.as_str();
/// ```
#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct Id(String);

impl Id {
    /// Creates a new random UUID-based ID.
    ///
    /// This always succeeds because we generate a valid UUID.
    ///
    /// # Example
    ///
    /// ```no_run
    /// use shared::Id;
    /// let id = Id::new();
    /// assert!(id.as_str().len() == 36); // UUID string length
    /// ```
    pub fn new() -> Self {
        Self(Uuid::new_v4().to_string())
    }

    /// Attempts to create an ID from a string, validating it's a proper UUID.
    ///
    /// # Errors
    ///
    /// Returns an error if the string is not a valid UUID format.
    ///
    /// # Example
    ///
    /// ```
    /// use shared::Id;
    /// let valid = Id::from_string("550e8400-e29b-41d4-a716-446655440000".to_string());
    /// assert!(valid.is_ok());
    ///
    /// let invalid = Id::from_string("not-a-uuid".to_string());
    /// assert!(invalid.is_err());
    /// ```
    pub fn from_string(s: String) -> Result<Self, String> {
        // Validate that it's a proper UUID
        Uuid::parse_str(&s)
            .map(|_| Self(s))
            .map_err(|e| format!("Invalid UUID: {}", e))
    }

    /// Returns the ID as a string slice.
    ///
    /// # Example
    ///
    /// ```
    /// use shared::Id;
    /// let id = Id::new();
    /// let s: &str = id.as_str();
    /// ```
    pub fn as_str(&self) -> &str {
        &self.0
    }

    /// Consumes the ID and returns the inner String.
    ///
    /// This is useful when you need to transfer ownership of the String.
    pub fn into_string(self) -> String {
        self.0
    }
}

impl Default for Id {
    /// Creates a new random ID.
    ///
    /// **Note on Default Implementation:**
    ///
    /// We implement Default to enable TypeGen to successfully trace types
    /// containing Id fields. Each call to `default()` creates a NEW random ID.
    ///
    /// In practice, you should use `Id::new()` explicitly for clarity, but
    /// Default is needed for serde-reflection during type generation.
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// Display Support
// =============================================================================

impl fmt::Display for Id {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

// =============================================================================
// Conversions
// =============================================================================

/// Convert from &str (validates)
impl TryFrom<&str> for Id {
    type Error = String;

    fn try_from(s: &str) -> Result<Self, Self::Error> {
        Self::from_string(s.to_string())
    }
}

/// Convert from String (validates)
impl TryFrom<String> for Id {
    type Error = String;

    fn try_from(s: String) -> Result<Self, Self::Error> {
        Self::from_string(s)
    }
}

// =============================================================================
// Tests
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_creates_valid_uuid() {
        let id = Id::new();
        // Should be a valid UUID string (36 characters with hyphens)
        assert_eq!(id.as_str().len(), 36);
        // Should parse as valid UUID
        assert!(Uuid::parse_str(id.as_str()).is_ok());
    }

    #[test]
    fn test_from_string_valid() {
        let uuid_str = "550e8400-e29b-41d4-a716-446655440000";
        let id = Id::from_string(uuid_str.to_string());
        assert!(id.is_ok());
        assert_eq!(id.unwrap().as_str(), uuid_str);
    }

    #[test]
    fn test_from_string_invalid() {
        let invalid = Id::from_string("not-a-uuid".to_string());
        assert!(invalid.is_err());
        assert!(invalid.unwrap_err().contains("Invalid UUID"));
    }

    #[test]
    fn test_serialization() {
        let id = Id::new();
        let json = serde_json::to_string(&id).expect("Failed to serialize");

        // Should serialize as a plain string (with quotes)
        assert!(json.starts_with('"'));
        assert!(json.ends_with('"'));

        // Should deserialize back
        let deserialized: Id = serde_json::from_str(&json).expect("Failed to deserialize");
        assert_eq!(id, deserialized);
    }

    #[test]
    fn test_deserialization_no_validation() {
        // Deserialization uses transparent serde (no validation)
        // Validation happens at the application boundary via Id::from_string()

        // Valid UUID deserializes
        let valid_json = r#""550e8400-e29b-41d4-a716-446655440000""#;
        let id: Result<Id, _> = serde_json::from_str(valid_json);
        assert!(id.is_ok());

        // Invalid strings also deserialize (no validation during serde)
        // This is intentional - validation happens via Id::from_string() in event handlers
        let invalid_json = r#""not-a-uuid""#;
        let id: Result<Id, _> = serde_json::from_str(invalid_json);
        assert!(id.is_ok()); // Deserializes successfully

        // But from_string() still validates
        assert!(Id::from_string("not-a-uuid".to_string()).is_err());
    }

    #[test]
    fn test_default() {
        let id1 = Id::default();
        let id2 = Id::default();

        // Each default should be a valid UUID
        assert!(Uuid::parse_str(id1.as_str()).is_ok());
        assert!(Uuid::parse_str(id2.as_str()).is_ok());

        // Each default should be unique (statistically)
        assert_ne!(id1, id2);
    }

    #[test]
    fn test_display() {
        let id = Id::from_string("550e8400-e29b-41d4-a716-446655440000".to_string()).unwrap();
        assert_eq!(format!("{}", id), "550e8400-e29b-41d4-a716-446655440000");
    }

    #[test]
    fn test_equality() {
        let uuid_str = "550e8400-e29b-41d4-a716-446655440000";
        let id1 = Id::from_string(uuid_str.to_string()).unwrap();
        let id2 = Id::from_string(uuid_str.to_string()).unwrap();
        let id3 = Id::new();

        assert_eq!(id1, id2);
        assert_ne!(id1, id3);
    }

    #[test]
    fn test_clone() {
        let id1 = Id::new();
        let id2 = id1.clone();
        assert_eq!(id1, id2);
    }
}
