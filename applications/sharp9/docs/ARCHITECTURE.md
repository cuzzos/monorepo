# Sharp9 Architecture - Elm-Inspired Functional Design

This document defines the architectural patterns for Sharp9, following an Elm-inspired approach with a pure functional core and impure shell for side effects.

## Core Philosophy

**Pure functional core, impure shell.** Business logic lives in pure functions operating on immutable data structures. Side effects (audio engine, file I/O, timers) are isolated in protocol-based services.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                          UI Layer                           │
│  (SwiftUI views - read state, send messages)                │
│  - Minimal logic (only coordinate→time geometry)            │
│  - IMPORTS: SwiftUI only                                    │
│  - NEVER: AVFoundation, Domain internals, direct mutation   │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ observes state
                              │ sends Msg
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       AppGlue Layer                         │
│  Core (Store) - owns Model + runs Commands                  │
│  - @Observable @MainActor final class                       │
│  - Calls update(), executes Commands via EffectRunner       │
│  - IMPORTS: Domain, Engine, SwiftUI                         │
└─────────────────────────────────────────────────────────────┘
          │                           │
          │ update()                  │ run(Command)
          ▼                           ▼
┌──────────────────────┐    ┌──────────────────────┐
│   Domain Layer       │    │   Engine Layer       │
│ (Pure functions)     │    │ (Impure services)    │
│                      │    │                      │
│ • Model (structs)    │    │ • AudioEngine        │
│ • Msg (enum)         │    │   protocol           │
│ • Command (enum)     │    │ • DefaultAudio-      │
│ • update() function  │    │   Engine (class)     │
│ • Selectors          │    │ • WaveformPeak-      │
│ • Formatting         │    │   Computer           │
│                      │    │                      │
│ IMPORTS: Foundation  │    │ IMPORTS:             │
│ NEVER: SwiftUI,      │    │   AVFoundation,      │
│        AVFoundation, │    │   Accelerate         │
│        UIKit         │    │ NEVER: SwiftUI       │
└──────────────────────┘    └──────────────────────┘
```

---

## Layer 1: Domain (Pure Functional Core)

### What Lives Here

**Pure data structures and pure functions only.**

- ✅ `struct` models (immutable state)
- ✅ `enum` messages (user intents + system events)
- ✅ `enum` commands (side effect descriptions)
- ✅ Pure `update()` function: `(Model, Msg) -> (Model, [Command])`
- ✅ Pure selectors: `(Model) -> DerivedValue`
- ✅ Pure formatters: `(Value) -> String`

**NEVER:**
- ❌ Classes (except for organizing static functions)
- ❌ Side effects (network, file I/O, timers, audio)
- ❌ SwiftUI imports
- ❌ AVFoundation imports
- ❌ Mutable state
- ❌ Async functions (use Commands instead)

### File Structure

```
Domain/
├── Models/
│   ├── PlayerModel.swift        # Main app state (struct)
│   ├── Mode.swift               # enum: marker, setA, loop, setB
│   ├── Marker.swift             # struct: id, timeSec
│   ├── LoopPoints.swift         # struct: aSec, bSec, enabled
│   ├── Transport.swift          # struct: isPlaying, currentTimeSec, speed, pitch
│   ├── TrackMeta.swift          # struct: name, durationSec
│   ├── Viewport.swift           # struct: startSec, endSec
│   └── ToastState.swift         # struct: message, expiresAt
├── Messages/
│   ├── Msg.swift                # All user/system events (enum)
│   └── Command.swift            # Side effect descriptions (enum)
└── Logic/
    ├── Update.swift             # Pure update function
    ├── Selectors.swift          # Computed state queries
    └── Formatting.swift         # Value formatters
```

### Model Pattern (Pure State)

```swift
// Domain/Models/PlayerModel.swift
struct PlayerModel: Sendable {
    var track: TrackMeta?
    var transport: Transport
    var loop: LoopPoints
    var mode: Mode
    var markers: [Marker]
    var viewport: Viewport
    var isLoading: Bool
    var toast: ToastState?
    
    // Default constructor
    init(
        track: TrackMeta? = nil,
        transport: Transport = Transport(),
        loop: LoopPoints = LoopPoints(),
        mode: Mode = .loop,
        markers: [Marker] = [],
        viewport: Viewport = Viewport(startSec: 0, endSec: 0),
        isLoading: Bool = false,
        toast: ToastState? = nil
    ) {
        self.track = track
        self.transport = transport
        self.loop = loop
        self.mode = mode
        self.markers = markers
        self.viewport = viewport
        self.isLoading = isLoading
        self.toast = toast
    }
}

// All nested models are also structs
struct Transport: Sendable {
    var isPlaying: Bool = false
    var currentTimeSec: Double = 0.0
    var speed: Double = 1.0
    var pitchSemitones: Double = 0.0
}

struct LoopPoints: Sendable {
    var aSec: Double? = nil
    var bSec: Double? = nil
    var enabled: Bool = false
}
```

### Message Pattern (Events)

```swift
// Domain/Messages/Msg.swift
enum Msg: Sendable {
    // Lifecycle
    case onAppear
    
    // Import flow
    case importPicked(url: URL)
    case importSucceeded(track: TrackMeta)
    case importFailed(message: String)
    
    // Mode selection
    case setMode(Mode)
    
    // Waveform interaction
    case tapWaveform(timeSec: Double)
    case dragScrub(timeSec: Double)
    
    // Transport controls
    case togglePlay
    case tick(currentTimeSec: Double)
    
    // Speed/pitch
    case speedDelta(Double)
    case pitchDelta(Double)
    
    // Markers
    case addMarker(timeSec: Double)
    case deleteMarker(id: UUID)
    
    // Loop controls
    case toggleLoopEnabled(Bool)
    case setA(timeSec: Double)
    case setB(timeSec: Double)
    
    // Toast
    case clearToastIfExpired(now: Date)
}
```

### Command Pattern (Side Effects)

```swift
// Domain/Messages/Command.swift
enum Command: Sendable {
    // Engine commands
    case engineLoad(url: URL)
    case enginePlay(fromTimeSec: Double)
    case enginePause
    case engineSeek(timeSec: Double)
    case engineSetRate(Double)
    case engineSetPitchSemitones(Double)
    case engineSetLoop(aSec: Double?, bSec: Double?, enabled: Bool)
    
    // Waveform computation
    case computePeaks(url: URL, targetBuckets: Int)
    
    // Timer management
    case startTimeTracking
    case stopTimeTracking
}
```

### Update Function (Pure Logic)

```swift
// Domain/Logic/Update.swift
enum Update {
    /// Pure state transition function
    /// - Parameters:
    ///   - model: Current state (will be mutated)
    ///   - msg: Event to process
    ///   - now: Current time (injected for testability)
    /// - Returns: Array of commands to execute
    static func update(
        model: inout PlayerModel,
        msg: Msg,
        now: @Sendable () -> Date = Date.init
    ) -> [Command] {
        switch msg {
        case .onAppear:
            return []
            
        case .importPicked(let url):
            model.isLoading = true
            model.track = nil
            model.transport.isPlaying = false
            model.transport.currentTimeSec = 0
            model.loop = LoopPoints()
            model.markers = []
            return [
                .enginePause,
                .engineLoad(url: url)
            ]
            
        case .importSucceeded(let track):
            model.track = track
            model.isLoading = false
            model.viewport = Viewport(startSec: 0, endSec: track.durationSec)
            model.transport.currentTimeSec = 0
            return [
                .computePeaks(url: track.url, targetBuckets: 1000)
            ]
            
        case .importFailed(let message):
            model.isLoading = false
            model.toast = ToastState(
                message: message,
                expiresAt: now().addingTimeInterval(3.0)
            )
            return []
            
        case .togglePlay:
            if model.transport.isPlaying {
                model.transport.isPlaying = false
                return [.enginePause, .stopTimeTracking]
            } else {
                model.transport.isPlaying = true
                return [
                    .enginePlay(fromTimeSec: model.transport.currentTimeSec),
                    .startTimeTracking
                ]
            }
            
        case .speedDelta(let delta):
            let newSpeed = (model.transport.speed + delta).clamped(to: 0.25...2.0)
            model.transport.speed = newSpeed
            model.toast = ToastState(
                message: "Speed \(Formatting.formatSpeed(newSpeed))",
                expiresAt: now().addingTimeInterval(1.5)
            )
            return [.engineSetRate(newSpeed)]
            
        case .setA(let timeSec):
            model.loop.aSec = timeSec
            // Auto-swap if needed
            if let a = model.loop.aSec, let b = model.loop.bSec, a > b {
                swap(&model.loop.aSec, &model.loop.bSec)
            }
            return [
                .engineSetLoop(
                    aSec: model.loop.aSec,
                    bSec: model.loop.bSec,
                    enabled: model.loop.enabled
                )
            ]
            
        case .toggleLoopEnabled(let enabled):
            guard model.loop.aSec != nil && model.loop.bSec != nil else {
                model.toast = ToastState(
                    message: "Set A and B",
                    expiresAt: now().addingTimeInterval(2.0)
                )
                return []
            }
            model.loop.enabled = enabled
            return [
                .engineSetLoop(
                    aSec: model.loop.aSec,
                    bSec: model.loop.bSec,
                    enabled: enabled
                )
            ]
            
        case .tick(let currentTimeSec):
            model.transport.currentTimeSec = currentTimeSec
            return []
            
        case .clearToastIfExpired(let now):
            if let toast = model.toast, now >= toast.expiresAt {
                model.toast = nil
            }
            return []
            
        // ... other cases
        default:
            return []
        }
    }
}

// Helper extension
extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
```

### Selectors (Derived State)

```swift
// Domain/Logic/Selectors.swift
enum Selectors {
    /// Returns normalized loop range (always a <= b)
    static func loopRange(_ model: PlayerModel) -> (Double, Double)? {
        guard let a = model.loop.aSec, let b = model.loop.bSec else {
            return nil
        }
        return (min(a, b), max(a, b))
    }
    
    /// Can the user enable looping?
    static func canLoop(_ model: PlayerModel) -> Bool {
        model.loop.aSec != nil && model.loop.bSec != nil
    }
    
    /// Is there a track loaded?
    static func hasTrack(_ model: PlayerModel) -> Bool {
        model.track != nil
    }
    
    /// Progress ratio [0, 1]
    static func progress(_ model: PlayerModel) -> Double {
        guard let track = model.track, track.durationSec > 0 else {
            return 0
        }
        return model.transport.currentTimeSec / track.durationSec
    }
}
```

### Formatting (Pure Transformations)

```swift
// Domain/Logic/Formatting.swift
enum Formatting {
    /// Format time as "MM:SS.xx"
    static func formatTime(_ seconds: Double) -> String {
        let duration = Duration.seconds(seconds)
        return duration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }
    
    /// Format speed as "1.00x"
    static func formatSpeed(_ speed: Double) -> String {
        String(format: "%.2fx", speed)
    }
    
    /// Format pitch as "+3.00st" or "-3.00st"
    static func formatPitch(_ semitones: Double) -> String {
        let sign = semitones >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", semitones))st"
    }
}
```

---

## Layer 2: Engine (Impure Service Shell)

### What Lives Here

**Protocol-based services that perform side effects.**

- ✅ `protocol` definitions (boundaries)
- ✅ `class` implementations (AVFoundation, file I/O, etc.)
- ✅ `async` functions for I/O
- ✅ Callbacks for streaming events (time updates)
- ✅ AVFoundation, Accelerate imports

**NEVER:**
- ❌ SwiftUI imports
- ❌ Business logic (that belongs in Domain)
- ❌ Direct state mutation (return values or call callbacks)

### File Structure

```
Engine/
├── AudioEngine.swift              # Protocol definition
├── DefaultAudioEngine.swift       # AVFoundation implementation
├── WaveformPeaks.swift            # Data structure
└── WaveformPeakComputer.swift     # Async peak computation
```

### AudioEngine Protocol

```swift
// Engine/AudioEngine.swift
import Foundation

/// Protocol boundary between pure domain logic and AVFoundation
protocol AudioEngine: AnyObject, Sendable {
    /// Callback for streaming time updates during playback
    var onTimeUpdate: (@Sendable (Double) -> Void)? { get set }
    
    /// Load audio file and return metadata
    func load(url: URL) async throws -> TrackMeta
    
    /// Start playback from current position
    func play()
    
    /// Pause playback
    func pause()
    
    /// Seek to specific time
    func seek(to timeSec: Double)
    
    /// Set playback rate (speed)
    func setRate(_ rate: Double)
    
    /// Set pitch shift in semitones
    func setPitchSemitones(_ semitones: Double)
    
    /// Configure loop points
    func setLoop(aSec: Double?, bSec: Double?, enabled: Bool)
    
    /// Get current playback time
    func currentTimeSec() -> Double
}
```

---

## Layer 3: AppGlue (Store / Runtime)

### What Lives Here

**The bridge between pure domain logic and impure services.**

- ✅ `Core` class (the "Store" that owns Model + runs Commands)
- ✅ `@Observable @MainActor` for SwiftUI integration
- ✅ `EffectRunner` to execute Commands via services
- ✅ `Dependencies` struct for dependency injection

### File Structure

```
AppGlue/
├── Core.swift              # Observable store
├── EffectRunner.swift      # Command executor
└── Dependencies.swift      # DI container
```

### Core (The Store)

```swift
// AppGlue/Core.swift
import SwiftUI
import Observation

@Observable
@MainActor
final class Core {
    /// The single source of truth
    var model: PlayerModel
    
    private let runner: EffectRunner
    private let deps: Dependencies
    
    init(deps: Dependencies) {
        self.model = PlayerModel()
        self.deps = deps
        self.runner = EffectRunner(deps: deps)
        
        // Wire up engine callbacks
        deps.engine.onTimeUpdate = { [weak self] time in
            Task { @MainActor in
                self?.send(.tick(currentTimeSec: time))
            }
        }
    }
    
    /// Send a message to update state and trigger side effects
    func send(_ msg: Msg) {
        let commands = Update.update(
            model: &model,
            msg: msg,
            now: deps.now
        )
        
        for command in commands {
            runner.run(command, core: self)
        }
    }
}
```

### Dependencies

```swift
// AppGlue/Dependencies.swift
import Foundation

struct Dependencies {
    let engine: AudioEngine
    let peakComputer: WaveformPeakComputer
    let now: @Sendable () -> Date
    
    static var live: Dependencies {
        Dependencies(
            engine: DefaultAudioEngine(),
            peakComputer: WaveformPeakComputer(),
            now: Date.init
        )
    }
    
    static var test: Dependencies {
        Dependencies(
            engine: MockAudioEngine(),
            peakComputer: MockPeakComputer(),
            now: { Date(timeIntervalSince1970: 0) }
        )
    }
}
```

---

## Layer 4: UI (SwiftUI Views)

### What Lives Here

**Presentation layer that observes state and sends messages.**

- ✅ SwiftUI views
- ✅ Geometry calculations (coordinate → time mapping)
- ✅ Layout and styling
- ✅ Gesture recognition

**NEVER:**
- ❌ Business logic
- ❌ Direct state mutation
- ❌ AVFoundation imports
- ❌ Side effects (use `core.send(msg)` instead)

### Pattern

```swift
// UI/PlayerView.swift
import SwiftUI

struct PlayerView: View {
    @Bindable var core: Core
    
    var body: some View {
        VStack(spacing: 0) {
            if let track = core.model.track {
                TrackRow(trackName: track.name)
                WaveformView(core: core)
                TransportBar(core: core)
            } else {
                EmptyStateView(core: core)
            }
        }
    }
}

struct TransportBar: View {
    @Bindable var core: Core
    
    var body: some View {
        HStack {
            Button("-") { core.send(.speedDelta(-0.05)) }
            Text(Formatting.formatSpeed(core.model.transport.speed))
            Button("+") { core.send(.speedDelta(0.05)) }
            
            Spacer()
            
            Button(core.model.transport.isPlaying ? "Pause" : "Play") {
                core.send(.togglePlay)
            }
        }
        .padding()
    }
}
```

---

## Key Architectural Rules

### 1. Data Flow (Unidirectional)

```
User Action → UI sends Msg → Core.send() → Update.update() → (new Model, [Command])
                                   ↓                                    ↓
                              Model updated                    EffectRunner.run()
                                   ↓                                    ↓
                              UI re-renders ←─────────────── Engine callbacks
```

### 2. Import Rules

| Layer | May Import | NEVER Import |
|-------|------------|--------------|
| Domain | `Foundation` | `SwiftUI`, `AVFoundation`, `UIKit` |
| Engine | `AVFoundation`, `Accelerate`, `Foundation` | `SwiftUI` |
| AppGlue | `Domain`, `Engine`, `SwiftUI`, `Observation` | Direct AVFoundation usage |
| UI | `SwiftUI`, `AppGlue` | `AVFoundation`, Domain internals |

### 3. Testing Strategy

```swift
// ✅ Test pure update function (easy, fast, reliable)
@Test("Toggle play starts playback when paused")
func testTogglePlay() {
    var model = PlayerModel()
    model.transport.isPlaying = false
    
    let commands = Update.update(model: &model, msg: .togglePlay)
    
    #expect(model.transport.isPlaying == true)
    #expect(commands.contains(.enginePlay(fromTimeSec: 0)))
}

// ✅ Test selectors (pure functions)
@Test("Loop range normalizes A and B")
func testLoopRange() {
    var model = PlayerModel()
    model.loop.aSec = 10.0
    model.loop.bSec = 5.0
    
    let range = Selectors.loopRange(model)
    
    #expect(range?.0 == 5.0)
    #expect(range?.1 == 10.0)
}
```

---

## Benefits of This Architecture

1. **Testability** - Pure `update()` function is trivial to test
2. **Predictability** - All state changes go through `update()`
3. **Separation of Concerns** - Domain/Engine/AppGlue/UI have clear boundaries
4. **Future-Proof** - Can swap AVFoundation for Rust/Crux later

---

## Migration Path (Future: Rust/Crux)

When ready to move to Rust core:

1. **Domain layer** → Rust (already pure functions, easy to port)
2. **Engine protocol** → Keep as Swift boundary
3. **AppGlue** → Minimal changes (just swap engine implementation)
4. **UI** → No changes needed

The architecture is designed for this transition.
