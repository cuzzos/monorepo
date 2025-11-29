//! Plate calculator event handlers.
//!
//! Handles plate calculation for barbell loading.

use crux_core::{render::render, Command};

use super::super::{Effect, Event, Model};

/// Handle plate calculator events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        Event::CalculatePlates {
            target_weight,
            bar_weight,
            use_percentage,
        } => {
            // Validate inputs before calculation
            if target_weight <= 0.0 {
                model.error_message = Some("Target weight must be greater than 0".to_string());
                model.plate_calculation = None;
            } else if bar_weight <= 0.0 {
                model.error_message = Some("Bar weight must be greater than 0".to_string());
                model.plate_calculation = None;
            } else if let Some(percentage) = use_percentage {
                if percentage < 0.0 || percentage > 100.0 {
                    model.error_message = Some(format!(
                        "Percentage must be between 0 and 100 (got {})",
                        percentage
                    ));
                    model.plate_calculation = None;
                } else {
                    // All validations passed, perform calculation
                    super::super::Thiccc::perform_plate_calculation(
                        model,
                        target_weight,
                        bar_weight,
                        Some(percentage),
                    );
                }
            } else {
                // No percentage, perform calculation directly
                super::super::Thiccc::perform_plate_calculation(model, target_weight, bar_weight, None);
            }
            render()
        }

        Event::ClearPlateCalculation => {
            model.plate_calculation = None;
            render()
        }

        Event::ShowPlateCalculator => {
            model.showing_plate_calculator = true;
            render()
        }

        Event::DismissPlateCalculator => {
            model.showing_plate_calculator = false;
            model.plate_calculation = None;
            render()
        }

        _ => unreachable!("plate_calculator module received wrong event type"),
    }
}

