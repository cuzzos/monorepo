use crux_core::render::Render;
use serde::{Deserialize, Serialize};

/// The core Crux app - all business logic lives here
#[derive(Default)]
pub struct App;

/// Events that can be dispatched to update the app state
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
pub enum Event {
    /// Increment the counter
    Increment,
}

/// The app's model/state
#[derive(Default, Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
pub struct Model {
    pub count: i32,
}

/// The view model that gets sent to the shell for rendering
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
pub struct ViewModel {
    pub count: String,
}

impl crux_core::App for App {
    type Event = Event;
    type Model = Model;
    type ViewModel = ViewModel;
    type Capabilities = Render<Event>;

    fn update(&self, event: Self::Event, model: &mut Self::Model, caps: &Self::Capabilities) {
        match event {
            Event::Increment => {
                model.count += 1;
                caps.render();
            }
        }
    }

    fn view(&self, model: &Self::Model) -> Self::ViewModel {
        ViewModel {
            count: model.count.to_string(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crux_core::App as CruxApp;

    #[test]
    fn test_increment() {
        let _app = App::default();
        let mut model = Model::default();

        // Initial count should be 0
        assert_eq!(model.count, 0);

        // Increment the counter manually
        model.count += 1;
        
        // Count should now be 1
        assert_eq!(model.count, 1);
    }

    #[test]
    fn test_view() {
        let app = App::default();
        let model = Model { count: 42 };
        
        let view_model = app.view(&model);
        
        assert_eq!(view_model.count, "42");
    }

    #[test]
    fn test_model_default() {
        let model = Model::default();
        assert_eq!(model.count, 0);
    }
}

