//! Timer event handlers.
//!
//! Handles workout timer, stopwatch, and rest timer events.

use crux_core::{render::render, Command};

use crate::operations::TimerOperation;

use super::super::{Effect, Event, Model};

/// Handle timer events.
pub fn handle_event(event: Event, model: &mut Model) -> Command<Effect, Event> {
    match event {
        Event::TimerTick => {
            if model.timer_running {
                model.workout_timer_seconds += 1;
            }
            render()
        }

        Event::StartTimer => {
            model.timer_running = true;
            Command::request_from_shell(TimerOperation::Start)
                .then_send(|output| Event::TimerResponse { output })
        }

        Event::StopTimer => {
            model.timer_running = false;
            Command::request_from_shell(TimerOperation::Stop)
                .then_send(|output| Event::TimerResponse { output })
        }

        Event::ToggleTimer => {
            model.timer_running = !model.timer_running;
            let operation = if model.timer_running {
                TimerOperation::Start
            } else {
                TimerOperation::Stop
            };
            Command::request_from_shell(operation)
                .then_send(|output| Event::TimerResponse { output })
        }

        Event::ShowStopwatch => {
            model.showing_stopwatch = true;
            render()
        }

        Event::DismissStopwatch => {
            model.showing_stopwatch = false;
            render()
        }

        Event::ShowRestTimer { duration_seconds } => {
            model.showing_rest_timer = Some(duration_seconds);
            render()
        }

        Event::DismissRestTimer => {
            model.showing_rest_timer = None;
            render()
        }

        _ => unreachable!("timer module received wrong event type"),
    }
}

