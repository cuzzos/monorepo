# Shared Core (Rust/Crux)

This directory contains the platform-agnostic business logic for the Thiccc app.

**Built with Rust Edition 2024** - Using the latest stable Rust features and improvements.

## Architecture

Built using [Crux](https://github.com/redbadger/crux), this core implements:

- **Model**: The app's state (counter value)
- **Event**: Actions that can modify state (Increment)
- **Update**: Pure function that handles events and updates model
- **View**: Pure function that transforms model into view model

## Key Files

- `src/lib.rs`: Main app logic
- `Cargo.toml`: Dependencies and build configuration

## Running Tests

```bash
cargo test
```

## Building

```bash
cargo build --release
```

For iOS:
```bash
cargo build --release --target aarch64-apple-ios
cargo build --release --target x86_64-apple-ios-sim
```

## Adding Features

1. Update `Model` with new state fields
2. Add new `Event` variants for user actions
3. Implement logic in `update()` function
4. Update `ViewModel` to expose state to UI
5. Implement rendering in `view()` function
6. Write tests!

The beauty of this architecture is that all business logic is tested in Rust, and the UI shells (iOS, Android, Web) are thin rendering layers.

