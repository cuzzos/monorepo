# Thiccc - Workout Tracking App

iOS workout tracker with **Rust business logic** + **SwiftUI UI**.

## ⚡ Get Started (2 steps)

```bash
./setup-mac.sh          # Run once (installs everything)
open app/ios/thiccc/Thiccc.xcodeproj && # ⌘R to run
```

**First time?** → [docs/QUICKSTART.md](./docs/QUICKSTART.md) has details

## What Is This?

**Architecture:** Rust (business logic) + Swift (UI only)

- ✅ All workout logic in Rust (portable, testable)
- ✅ SwiftUI for iOS interface
- ✅ Automatic Rust↔Swift bridge (UniFFI)
- ✅ SQLite database
- ✅ iOS 18.0+

**Features:** Workout tracking, exercise sets, timer, history, plate calculator

## Project Structure

```
thiccc/
├── setup-mac.sh              # Run this first!
├── docs/                     # All documentation here
├── app/
│   ├── shared/               # Rust (business logic)
│   └── ios/                  # Swift (UI)
```

## Daily Development

**Edit Rust:** Use devcontainer (Linux) or Mac
```bash
cd app/shared
cargo test          # Run tests
cargo check         # Check compilation
```

**Build iOS:** Just hit ⌘R in Xcode (auto-rebuilds Rust if changed)

## Need Help?

| Issue | Solution |
|-------|----------|
| "No such module 'SharedCore'" | Hit ⌘B in Xcode (first build) |
| Build errors | Run `./setup-mac.sh` again |
| How does it work? | See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) |
| Deploy to TestFlight | See [docs/DEPLOYMENT-INDEX.md](./docs/DEPLOYMENT-INDEX.md) |

## Learn More

- **[docs/QUICKSTART.md](./docs/QUICKSTART.md)** - Setup instructions
- **[docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - How it works (architecture, testing, etc.)
- **[docs/DEPLOYMENT-INDEX.md](./docs/DEPLOYMENT-INDEX.md)** - Deploy to TestFlight

## Stack

**Rust:** Crux, UniFFI, rusqlite, serde  
**Swift:** iOS 18+, SwiftUI, UniFFI-generated bindings
