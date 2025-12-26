import Testing
import Foundation
@testable import Sharp9

struct ReducerTests {
    
    // MARK: - Test Helpers
    
    private func makeState(
        track: TrackMeta? = TrackMeta(name: "Test", durationSec: 100),
        transport: Transport = Transport(),
        loop: LoopPoints = LoopPoints(),
        mode: Mode = .loop,
        markers: [Marker] = [],
        isLoading: Bool = false
    ) -> AppState {
        AppState(
            track: track,
            transport: transport,
            loop: loop,
            mode: mode,
            markers: markers,
            viewport: Viewport(startSec: 0, endSec: track?.durationSec ?? 0),
            isLoading: isLoading
        )
    }
    
    private let fixedDate = Date(timeIntervalSince1970: 0)
    private let fixedNow: @Sendable () -> Date = { Date(timeIntervalSince1970: 0) }
    
    // MARK: - togglePlay Tests

    @Test("Toggle play starts playing from current time when paused")
    func testTogglePlay_whenPaused_startsPlaying() {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 30.0)
        )

        let effects = Reducer.reduce(state: &state, action: .togglePlay, now: fixedNow)

        #expect(state.transport.isPlaying)
        #expect(state.transport.currentTimeSec == 30.0) // Unchanged
        #expect(effects == [.enginePlay(fromTimeSec: 30.0)])
    }
    
    @Test("Toggle play starts from zero when paused at zero")
    func testTogglePlay_whenPausedAtZero_startsFromZero() {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 0)
        )

        let effects = Reducer.reduce(state: &state, action: .togglePlay, now: fixedNow)

        #expect(state.transport.isPlaying)
        #expect(effects == [.enginePlay(fromTimeSec: 0)])
    }

    @Test("Toggle play pauses when playing")
    func testTogglePlay_whenPlaying_pauses() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 45.0)
        )

        let effects = Reducer.reduce(state: &state, action: .togglePlay, now: fixedNow)

        #expect(!state.transport.isPlaying)
        #expect(state.transport.currentTimeSec == 45.0) // Unchanged
        #expect(effects == [.enginePause])
    }
    
    // MARK: - dragScrub Tests

    @Test("Drag scrub updates time only when paused")
    func testDragScrub_whenPaused_updatesTimeOnly() {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 0)
        )

        let effects = Reducer.reduce(state: &state, action: .dragScrub(timeSec: 50.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 50.0)
        #expect(effects.isEmpty) // No engine effect when paused
    }

    @Test("Drag scrub restarts from new position when playing")
    func testDragScrub_whenPlaying_restartsFromNewPosition() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 10.0)
        )

        let effects = Reducer.reduce(state: &state, action: .dragScrub(timeSec: 50.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 50.0)
        #expect(effects == [.enginePlay(fromTimeSec: 50.0)])
    }

    @Test("Drag scrub clamps to track duration")
    func testDragScrub_clampsToTrackDuration() {
        var state = makeState(
            track: TrackMeta(name: "Test", durationSec: 100),
            transport: Transport(isPlaying: false, currentTimeSec: 0)
        )

        let effects = Reducer.reduce(state: &state, action: .dragScrub(timeSec: 150.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 100.0) // Clamped to duration
        #expect(effects.isEmpty)
    }

    @Test("Drag scrub clamps to zero")
    func testDragScrub_clampsToZero() {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 50)
        )

        let effects = Reducer.reduce(state: &state, action: .dragScrub(timeSec: -10.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 0) // Clamped to 0
        #expect(effects.isEmpty)
    }

    // MARK: - tick Tests

    @Test("Tick updates current time")
    func testTick_updatesCurrentTime() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 10.0)
        )

        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 15.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 15.0)
        #expect(effects.isEmpty)
    }

    // MARK: - playbackFinished Tests

    @Test("Playback finished sets playing to false")
    func testPlaybackFinished_setsPlayingToFalse() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 100.0)
        )

        let effects = Reducer.reduce(state: &state, action: .playbackFinished, now: fixedNow)

        #expect(!state.transport.isPlaying)
        #expect(state.transport.currentTimeSec == 100.0) // Unchanged
        #expect(effects.isEmpty)
    }

    // MARK: - tapWaveform Tests (in loop mode)

    @Test("Tap waveform in loop mode updates time only when paused")
    func testTapWaveform_loopMode_whenPaused_updatesTimeOnly() {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 0),
            mode: .loop
        )

        let effects = Reducer.reduce(state: &state, action: .tapWaveform(timeSec: 25.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 25.0)
        #expect(effects.isEmpty)
    }

    @Test("Tap waveform in loop mode restarts from tap position when playing")
    func testTapWaveform_loopMode_whenPlaying_restartsFromTapPosition() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 10.0),
            mode: .loop
        )

        let effects = Reducer.reduce(state: &state, action: .tapWaveform(timeSec: 25.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 25.0)
        #expect(effects == [.enginePlay(fromTimeSec: 25.0)])
    }

    // MARK: - Speed/Pitch Tests

    @Test("Speed delta increases speed")
    func testSpeedDelta_increasesSpeed() {
        var state = makeState(
            transport: Transport(speed: 1.0)
        )

        let effects = Reducer.reduce(state: &state, action: .speedDelta(0.05), now: fixedNow)

        #expect(abs(state.transport.speed - 1.05) < 0.001)
        #expect(effects == [.engineSetRate(1.05)])
        #expect(state.toast != nil)
    }

    @Test("Speed delta clamps to max")
    func testSpeedDelta_clampsToMax() {
        var state = makeState(
            transport: Transport(speed: 2.0)
        )

        let effects = Reducer.reduce(state: &state, action: .speedDelta(0.05), now: fixedNow)

        #expect(state.transport.speed == 2.0) // Clamped
        #expect(effects == [.engineSetRate(2.0)])
    }

    @Test("Speed delta clamps to min")
    func testSpeedDelta_clampsToMin() {
        var state = makeState(
            transport: Transport(speed: 0.25)
        )

        let effects = Reducer.reduce(state: &state, action: .speedDelta(-0.05), now: fixedNow)

        #expect(state.transport.speed == 0.25) // Clamped
        #expect(effects == [.engineSetRate(0.25)])
    }

    @Test("Pitch delta increases pitch")
    func testPitchDelta_increasesPitch() {
        var state = makeState(
            transport: Transport(pitchSemitones: 0)
        )

        let effects = Reducer.reduce(state: &state, action: .pitchDelta(1.0), now: fixedNow)

        #expect(state.transport.pitchSemitones == 1.0)
        #expect(effects == [.engineSetPitchSemitones(1.0)])
        #expect(state.toast != nil)
    }

    @Test("Pitch delta clamps to max")
    func testPitchDelta_clampsToMax() {
        var state = makeState(
            transport: Transport(pitchSemitones: 12.0)
        )

        let effects = Reducer.reduce(state: &state, action: .pitchDelta(1.0), now: fixedNow)

        #expect(state.transport.pitchSemitones == 12.0) // Clamped
    }

    @Test("Pitch delta clamps to min")
    func testPitchDelta_clampsToMin() {
        var state = makeState(
            transport: Transport(pitchSemitones: -12.0)
        )

        let effects = Reducer.reduce(state: &state, action: .pitchDelta(-1.0), now: fixedNow)

        #expect(state.transport.pitchSemitones == -12.0) // Clamped
    }

    // MARK: - Import Tests

    @Test("Import picked resets state and starts loading")
    func testImportPicked_resetsStateAndStartsLoading() {
        var state = makeState(
            track: TrackMeta(name: "Old", durationSec: 50),
            transport: Transport(isPlaying: true, currentTimeSec: 25.0),
            loop: LoopPoints(aSec: 10, bSec: 20, enabled: true),
            markers: [Marker(timeSec: 5)]
        )

        let url = URL(fileURLWithPath: "/test.mp3")
        let effects = Reducer.reduce(state: &state, action: .importPicked(url: url), now: fixedNow)

        #expect(state.isLoading)
        #expect(!state.transport.isPlaying)
        #expect(state.transport.currentTimeSec == 0)
        #expect(state.loop.aSec == nil)
        #expect(state.loop.bSec == nil)
        #expect(!state.loop.enabled)
        #expect(state.markers.isEmpty)
        #expect(effects == [.enginePause, .engineLoad(url: url)])
    }

    @Test("Import succeeded updates track and resets")
    func testImportSucceeded_updatesTrackAndResets() {
        var state = makeState(
            track: nil,
            isLoading: true
        )

        let track = TrackMeta(name: "New Track", durationSec: 120)
        let effects = Reducer.reduce(state: &state, action: .importSucceeded(track: track), now: fixedNow)

        #expect(state.track == track)
        #expect(!state.isLoading)
        #expect(state.transport.currentTimeSec == 0)
        #expect(state.viewport.startSec == 0)
        #expect(state.viewport.endSec == 120)
        #expect(effects == [.computePeaks])
    }

    @Test("Import failed shows toast")
    func testImportFailed_showsToast() {
        var state = makeState(
            track: nil,
            isLoading: true
        )

        let effects = Reducer.reduce(state: &state, action: .importFailed(message: "Invalid format"), now: fixedNow)

        #expect(!state.isLoading)
        #expect(state.toast != nil)
        #expect(state.toast?.message == "Invalid format")
        #expect(effects.isEmpty)
    }

    // MARK: - Loop Tests

    @Test("Set A sets loop point A")
    func testSetA_setsLoopPointA() {
        var state = makeState(
            loop: LoopPoints()
        )

        let effects = Reducer.reduce(state: &state, action: .setA(timeSec: 10.0), now: fixedNow)

        #expect(state.loop.aSec == 10.0)
        #expect(effects == [.engineSetLoop(aSec: 10.0, bSec: nil, enabled: false)])
    }

    @Test("Set B sets loop point B")
    func testSetB_setsLoopPointB() {
        var state = makeState(
            loop: LoopPoints(aSec: 10)
        )

        let effects = Reducer.reduce(state: &state, action: .setB(timeSec: 30.0), now: fixedNow)

        #expect(state.loop.bSec == 30.0)
        #expect(effects == [.engineSetLoop(aSec: 10.0, bSec: 30.0, enabled: false)])
    }

    @Test("Set AB swaps when A greater than B")
    func testSetAB_swapsWhenAGreaterThanB() {
        var state = makeState(
            loop: LoopPoints(aSec: 50)
        )

        // Set B to a value less than A
        _ = Reducer.reduce(state: &state, action: .setB(timeSec: 20.0), now: fixedNow)

        // Should swap so A < B
        #expect(state.loop.aSec == 20.0)
        #expect(state.loop.bSec == 50.0)
    }

    @Test("Toggle loop enabled when both points set enables loop")
    func testToggleLoopEnabled_whenBothPointsSet_enablesLoop() {
        var state = makeState(
            loop: LoopPoints(aSec: 10, bSec: 30, enabled: false)
        )

        let effects = Reducer.reduce(state: &state, action: .toggleLoopEnabled(true), now: fixedNow)

        #expect(state.loop.enabled)
        #expect(effects == [.engineSetLoop(aSec: 10, bSec: 30, enabled: true)])
    }

    @Test("Toggle loop enabled when missing points shows toast")
    func testToggleLoopEnabled_whenMissingPoints_showsToast() {
        var state = makeState(
            loop: LoopPoints(aSec: nil, bSec: nil, enabled: false)
        )

        let effects = Reducer.reduce(state: &state, action: .toggleLoopEnabled(true), now: fixedNow)

        #expect(!state.loop.enabled)
        #expect(state.toast != nil)
        #expect(state.toast?.message == "Set A and B")
        #expect(effects.isEmpty)
    }

    // MARK: - Marker Tests

    @Test("Add marker adds marker")
    func testAddMarker_addsMarker() {
        var state = makeState(markers: [])

        let effects = Reducer.reduce(state: &state, action: .addMarker(timeSec: 25.0), now: fixedNow)

        #expect(state.markers.count == 1)
        #expect(state.markers.first?.timeSec == 25.0)
        #expect(effects.isEmpty)
    }

    @Test("Delete marker removes marker")
    func testDeleteMarker_removesMarker() {
        let marker = Marker(timeSec: 25.0)
        var state = makeState(markers: [marker])

        let effects = Reducer.reduce(state: &state, action: .deleteMarker(id: marker.id), now: fixedNow)

        #expect(state.markers.isEmpty)
        #expect(effects.isEmpty)
    }
}

