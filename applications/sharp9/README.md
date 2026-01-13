# Sharp9 iOS App

Native iOS application built with Swift 6 and SwiftUI, targeting iOS 18.0+.

## Quick Start

```bash
# Install dependencies (first time only)
brew install mint
mint bootstrap

# Generate Xcode project and build
make build

# Run in simulator
make run-sim

# Open in Xcode
make open
```

## Requirements

- **Xcode**: Latest version with iOS 18 SDK
- **iOS Deployment Target**: iOS 18.0+
- **Swift**: Swift 6.2+
- **Mint**: For managing Swift tool dependencies

## Development

### Common Commands

```bash
make help          # Show all available commands
make build         # Generate Xcode project from project.yml
make xcode-build   # Build the app without opening Xcode
make run-sim       # Build and run in simulator with logs
make test          # Run tests
make clean         # Clean build artifacts
```

### Simulator Selection

Change the target simulator:

```bash
make run-sim SIMULATOR='iPhone 16'
make test SIMULATOR='iPhone SE'
```

Default simulator: **iPhone 16 Pro**

### Viewing Logs

```bash
make logs          # Stream app logs (filtered)
make logs-all      # Stream all system logs (verbose)
```

## Project Structure

```
sharp9/
├── app/
│   └── iOS/
│       ├── project.yml        # XcodeGen project definition
│       ├── Sharp9/            # Swift source files
│       └── Sharp9.xcodeproj/  # Generated (don't commit)
├── Makefile                   # Build automation
├── Mintfile                   # Swift tool dependencies
└── README.md                  # This file
```

## Architecture

Sharp9 is a native iOS app following modern Swift and SwiftUI best practices:

- **Swift 6.2+** with strict concurrency
- **SwiftUI** for declarative UI
- **@Observable** for state management (no Combine)
- **NavigationStack** for navigation (no NavigationView)
- **Modern APIs** - iOS 18+ only, no backward compatibility

See `.cursor/rules/swift-ios.mdc` for complete coding standards.

## Troubleshooting

### XcodeGen not found

```bash
brew install mint
mint bootstrap
```

### Simulator not available

```bash
make list-sims    # List available simulators
open /Applications/Xcode.app  # Install more simulators
```

### Build errors

```bash
make clean        # Clean build artifacts
make build        # Regenerate project
```

Check detailed logs:
```bash
cat xcodebuild.log
```

## Monorepo Context

This project is part of the Goonlytics monorepo. See the root `MONOREPO.md` for:
- Shared Cursor AI rules
- Monorepo best practices
- How context files are shared across projects

## Resources

- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)


