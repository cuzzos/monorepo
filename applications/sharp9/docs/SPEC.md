You are implementing an iOS 18+ (minimum) Swift 6.2+ app called "sharp9" – a BandLab-style audio slow/pitch/loop transcription tool.

PROJECT CONTEXT:
- App name: "sharp9" (lowercase, no space)
- Code/folders: Sharp9 (PascalCase for Swift)
- UI title display: "sharp9" (lowercase, no space)
- Inspiration: AudioStretch (BandLab)
- Target: iOS 18+ minimum, Swift 6.2+
- Location: applications/sharp9/app/iOS/Sharp9/

DOCUMENTATION STRUCTURE:
- **This file (SPEC.md)**: Technical implementation details, architecture, file structure
- **DESIGN_SPEC.md**: Visual design, colors, layout, UX behaviors
- **Swift standards**: .cursor/rules/swift-ios.mdc (enforced automatically)

IMPORTANT CONSTRAINTS
- Follow the design spec exactly for UI layout/strings/interactions.
- Strictly adhere to the provided Swift 6 / iOS 18+ standards:
  - Use Observation framework: @Observable + @Bindable (NO ObservableObject / @Published / @StateObject / @ObservedObject).
  - Use async/await (NO completion handlers, NO DispatchQueue.*).
  - Avoid UIKit unless absolutely required for file picking; prefer SwiftUI-native file importer first.
  - No force unwraps, no try! except truly unrecoverable.
  - Use modern SwiftUI APIs (foregroundStyle, clipShape(.rect(cornerRadius:)), etc).
  - One type per file.

CRITICAL: Business logic must be cleanly separated from UI.
- Domain layer must not import SwiftUI / AVFoundation / UIKit.
- Engine layer must not import SwiftUI.
- UI layer must not import AVFoundation.
- AppGlue wires everything. UI has minimal logic (only tap location -> time mapping is allowed).
- Engine must be behind protocols so it can later be replaced by Rust/Crux.

========================
1) Create files & folders
========================
Create exactly these folders/files inside applications/sharp9/app/iOS/Sharp9/:

/Sharp9/
  /Domain/
    /Models/
      Mode.swift
      Marker.swift
      LoopPoints.swift
      Transport.swift
      TrackMeta.swift
      Viewport.swift
      ToastState.swift
      State.swift
    /Actions/
      Action.swift
      Effect.swift
    /Logic/
      Reducer.swift
      Selectors.swift
      Formatting.swift

  /Engine/
    AudioEngine.swift           // Protocol
    DefaultAudioEngine.swift    // AVFoundation implementation
    WaveformPeaks.swift
    WaveformPeakComputer.swift

  /AppGlue/
    Core.swift
    EffectRunner.swift
    Dependencies.swift

  /UI/
    ContentView.swift           // Main screen that composes all components
    /Components/
      TopNavBar.swift
      TrackRow.swift
      KeyboardStrip.swift
      WaveformView.swift
      OverviewWaveformView.swift
      ModeBar.swift
      TransportBar.swift
      ToastOverlay.swift

Notes:
- Domain: NO SwiftUI, NO AVFoundation, NO UIKit.
- Engine: may use AVFoundation, Accelerate. NO SwiftUI.
- AppGlue: may import Domain + Engine + SwiftUI.
- UI: SwiftUI only.

=====================================
2) Domain model (pure business logic)
=====================================
Implement each type in its own file (one type per file).

Models:
- Mode: enum { marker, setA, loop, setB }
- Marker: struct { id: UUID; timeSec: Double } (Sendable)
- LoopPoints: struct { aSec: Double?; bSec: Double?; enabled: Bool } (Sendable)
- Transport: struct { isPlaying: Bool; currentTimeSec: Double; speed: Double; pitchSemitones: Double } (Sendable)
- TrackMeta: struct { name: String; durationSec: Double } (Sendable)
- Viewport: struct { startSec: Double; endSec: Double } (Sendable)
- ToastState: struct { message: String; expiresAt: Date } (Sendable)
- State: struct {
    track: TrackMeta?
    transport: Transport
    loop: LoopPoints
    mode: Mode
    markers: [Marker]
    viewport: Viewport
    isLoading: Bool
    toast: ToastState?
  } (Sendable)

Actions:
- Action: enum
  - onAppear
  - importPicked(url: URL)                  // Domain can reference Foundation URL
  - importSucceeded(track: TrackMeta)
  - importFailed(message: String)
  - setMode(Mode)
  - tapWaveform(timeSec: Double)
  - dragScrub(timeSec: Double)
  - togglePlay
  - tick(currentTimeSec: Double)
  - speedDelta(Double)                      // buttons (+/-)
  - pitchDelta(Double)
  - addMarker(timeSec: Double)
  - deleteMarker(id: UUID)
  - toggleLoopEnabled(Bool)
  - setA(timeSec: Double)
  - setB(timeSec: Double)
  - clearToastIfExpired(now: Date)

- Effect: enum (commands AppGlue performs)
  - engineLoad(url: URL)
  - enginePlay
  - enginePause
  - engineSeek(timeSec: Double)
  - engineSetRate(Double)
  - engineSetPitchSemitones(Double)
  - engineSetLoop(aSec: Double?, bSec: Double?, enabled: Bool)
  - computePeaks                               // optional hook; actual work in Engine

Logic:
- Reducer.reduce(state:inout, action:) -> [Effect]
  Implement exact rules (put all business rules here, not in UI):
  - importPicked: isLoading = true; clear track? (keep nil), stop playing, reset loop/markers/viewport/time
  - importSucceeded: set track; isLoading=false; reset markers; reset loop; set time=0; set default viewport
  - importFailed: isLoading=false; toast “Unable to open file”
  - tapWaveform:
    - mode setA -> setA(timeSec)
    - mode setB -> setB(timeSec)
    - mode marker -> addMarker(timeSec)
    - mode loop -> seek(timeSec)
  - dragScrub always seeks and updates time
  - setA/setB:
    - if both exist and a > b => swap
    - emit engineSetLoop with current loop state
  - toggleLoopEnabled(true):
    - if missing A or B => keep enabled false + toast “Set A and B”
    - else enabled true + emit engineSetLoop
  - togglePlay:
    - if playing -> pause effect
    - else -> play effect (looping handled by engine using current loop state)
  - speedDelta:
    - step 0.05 from buttons (Domain receives +/-0.05)
    - clamp [0.25, 2.0]
    - set toast “Speed {value}”
    - emit engineSetRate
  - pitchDelta:
    - step 1.0 from buttons
    - clamp [-12, 12]
    - toast “Pitch {value}”
    - emit engineSetPitchSemitones
  - tick updates currentTimeSec
  - clearToastIfExpired clears toast if now > expiresAt

- Formatting:
  - formatTime(seconds) -> "MM:SS.xx" using modern formatting (no String(format:)).
  - formatSpeed -> "1.00 x"
  - formatPitch -> "0.00 st"
  - toast strings exactly: "Speed {value}", "Pitch {value}"

- Selectors:
  - selectionRange(state) -> (a,b)? normalized
  - canLoop(state) -> Bool
  - etc.

=====================================
3) Engine layer (replaceable later)
=====================================
Protocol first:

AudioEngine.swift:
- protocol AudioEngine: AnyObject, Sendable (if needed use @unchecked Sendable carefully)
  - var onTimeUpdate: (@Sendable (Double) -> Void)? { get set }
  - func load(url: URL) async throws -> TrackMeta
  - func play()
  - func pause()
  - func seek(to timeSec: Double)
  - func setRate(_ rate: Double)
  - func setPitchSemitones(_ semitones: Double)
  - func setLoop(aSec: Double?, bSec: Double?, enabled: Bool)
  - func currentTimeSec() -> Double

DefaultAudioEngine.swift:
- Implement AudioEngine protocol using Apple's AVAudioEngine + AVAudioPlayerNode + AVAudioUnitTimePitch
- Use AVAudioUnitTimePitch.rate for speed and pitch in cents (semitones * 100).
- Looping:
  - if enabled && A/B set -> schedule segment A->B repeatedly
  - prefer seamless scheduling (schedule next segment before completion if possible)
- Time updates:
  - NO DispatchQueue; use a Task-based loop:
    - Start a Task when playing; periodically read currentTimeSec and call onTimeUpdate
    - use Task.sleep(for: .milliseconds(33)) (NOT nanoseconds)
  - Cancel Task on pause/stop/load

WaveformPeaks.swift:
- struct WaveformPeaks: Sendable { min: [Float]; max: [Float]; buckets: Int; durationSec: Double }
WaveformPeakComputer.swift:
- type responsible for computing peaks from AVAudioFile or PCM buffer.
- Must be async-friendly:
  - func computePeaks(url: URL, targetBuckets: Int) async throws -> WaveformPeaks
- Avoid blocking main actor; do heavy work off-main via Task.detached if needed.

=====================================
4) AppGlue (Observation + async effect runner)
=====================================
Core.swift:
- @Observable
  @MainActor
  final class Core {
    var state: State
    private let runner: EffectRunner

    init(deps: Dependencies)
    func send(_ action: Action)
  }
Rules:
- Core is the single observable object for the feature.
- Views receive core and use @Bindable var core.
- Core calls reducer, updates state, then passes effects to runner.

Dependencies.swift:
- struct Dependencies {
    let engine: AudioEngine
    let peakComputer: WaveformPeakComputer
    let now: @Sendable () -> Date
  }

EffectRunner.swift:
- @MainActor final class that executes Effect via dependencies:
  - engineLoad: await engine.load(url); on success core.send(.importSucceeded(track)); on failure core.send(.importFailed(...))
  - enginePlay/Pause/Seek/SetRate/SetPitch/SetLoop: call engine methods
  - computePeaks: await peakComputer.computePeaks(...) and store results in AppGlue-owned cache that UI can read
IMPORTANT:
- Domain state should not store big arrays. Store peaks in AppGlue (e.g., an actor cache or a simple @MainActor property) and pass to views as plain values.

Also wire engine.onTimeUpdate:
- when engine emits time updates, call core.send(.tick(currentTimeSec:))
- ensure callback hops to @MainActor safely (Task { @MainActor in core.send(...) })

=====================================
5) UI (SwiftUI, minimal logic)
=====================================
ContentView.swift (main screen):
- Accept core via environment or initializer; do NOT use ObservableObject patterns.
- Example:
  struct ContentView: View {
    @Bindable var core: Core
    @Environment(\.dismiss) private var dismiss
  }
- Compose components in the exact order per design spec:
  TopNavBar, TrackRow, KeyboardStrip, WaveformView, OverviewWaveformView, ModeBar, TransportBar, ToastOverlay
- Empty state: show “Import File” button.
- Use SwiftUI-native file picker first:
  - .fileImporter(isPresented:, allowedContentTypes:) targeting audio types.
  - If something requires UIKit, isolate in a small wrapper; do not leak UIKit into Domain/Engine/UI broadly.

Components:
- TopNavBar: X button calls dismiss(); title “sharp 9”; menu placeholders.
- TrackRow: shows “+” and track name; export/settings icons (no behavior required v1).
- KeyboardStrip: static keyboard drawing (no DSP needed v1).
- WaveformView:
  - Draw waveform with Canvas using peaks provided from AppGlue.
  - Draw selection overlay between A/B, playhead, markers.
  - Gestures:
    - For simple taps, use Button when possible; BUT for tap location you may use a gesture that provides location.
    - Convert x->timeSec using duration + viewport; then core.send(.tapWaveform(timeSec:)).
    - Drag updates core.send(.dragScrub(timeSec:)) continuously.
- OverviewWaveformView: mini waveform + playhead + selection + marker ticks; tap seeks.
- ModeBar: 4 segments (marker, A, loop, B) using Buttons; highlight selected segment.
- TransportBar:
  - Speed controls: Buttons send .speedDelta(-0.05/+0.05)
  - Play/pause: .togglePlay
  - Prev: seek to A if set else 0
  - Next: seek to B if set else track end
  - Pitch controls: Buttons send .pitchDelta(-1/+1)
- ToastOverlay: shows state.toast.message centered above waveform; dismiss after expiry via periodic .clearToastIfExpired(now:)

Strings EXACT:
- App title: "sharp9" (lowercase, no space)
- "Import File"
- "SPEED" / "PITCH"
- units "x" / "st"
- toast: "Speed {value}" / "Pitch {value}"
- missing loop points toast: "Set A and B"
- error toast: "Unable to open file"

Styling:
- Use foregroundStyle, clipShape(.rect(cornerRadius:)), modern APIs only.
- No hard-coded font sizes; use Dynamic Type styles.

=====================================
6) Deliverable (v1 acceptance)
=====================================
The app builds and runs on iOS 18+ with:

Core Features:
- Import audio files using SwiftUI file importer
- Waveform visualization with zoom/pan (optional v1)
- Scrub/seek via tap and drag gestures
- Set A/B loop points with visual selection overlay
- Loop playback A→B with seamless scheduling
- Speed control (0.25x–2.0x) with audible changes
- Pitch control (-12 to +12 semitones) with audible changes
- Add/delete markers with visible purple lines
- Toasts for speed/pitch feedback and errors

UI Requirements:
- Dark theme matching DESIGN_SPEC.md colors
- All strings exactly as specified (see section 5)
- Keyboard strip (static visualization, no interaction v1)
- Overview waveform strip
- Mode bar (marker, A, loop, B segments)
- Transport bar with play/pause, speed, pitch controls
- Proper iOS 18+ SwiftUI patterns (see Swift standards)

Architecture Requirements:
- Clean separation: Domain (pure logic) → Engine (protocols) → AppGlue → UI
- Domain layer has NO SwiftUI/AVFoundation imports
- Engine behind protocols (ready for future Rust/Crux replacement)
- UI has minimal logic (only coordinate→time mapping)
- Observation framework (@Observable, NOT ObservableObject)
- Strict Swift 6 concurrency (async/await, @MainActor)

Stop after v1. No extra features, no export functionality yet.
