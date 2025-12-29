import Testing
import Foundation
@testable import Sharp9

struct ReducerTests {
    
    // MARK: - Test Helpers
    
    private func makeState(
        track: TrackMeta? = TrackMeta(name: "Test", durationSec: 100),
        transport: Transport = Transport(),
        loop: LoopPoints = LoopPoints(),
        markers: [Marker] = [],
        isLoading: Bool = false
    ) -> AppState {
        AppState(
            track: track,
            transport: transport,
            loop: loop,
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
    
    // MARK: - transportScrubChanged Tests

    @Test("Transport scrub changed keeps paused state and seeks immediately", arguments: [0.0, 1.0, 10.5, 50.0, 99.9])
    func testTransportScrubChanged_keepsPausedState(_ timeSec: Double) {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 3.0)
        )

        let effects = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: timeSec), now: fixedNow)

        #expect(!state.transport.isPlaying) // CRITICAL: Must NOT change playing state
        #expect(state.transport.currentTimeSec == timeSec)
        // When paused, seek immediately for visual feedback
        #expect(effects == [.engineSeek(timeSec: timeSec)])
    }

    @Test("Transport scrub changed keeps playing state and lets audio continue during drag", arguments: [0.0, 2.25, 15.0, 75.5])
    func testTransportScrubChanged_keepsPlayingState(_ timeSec: Double) {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 3.0)
        )

        let effects = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: timeSec), now: fixedNow)

        #expect(state.transport.isPlaying) // CRITICAL: Must NOT change playing state
        #expect(state.transport.currentTimeSec == timeSec)
        #expect(state.isScrubbing) // Should mark as scrubbing
        // When playing, let audio continue - no effect returned (visual-only update)
        // Audio will jump to final position only when drag ends
        #expect(effects == [])
    }
    
    @Test("Transport scrub changed clamps to track duration")
    func testTransportScrubChanged_clampsToTrackDuration() {
        var state = makeState(
            track: TrackMeta(name: "Test", durationSec: 100),
            transport: Transport(isPlaying: false, currentTimeSec: 0)
        )

        let effects = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 150.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 100.0) // Clamped to duration
        #expect(!state.transport.isPlaying) // Still paused
        #expect(effects == [.engineSeek(timeSec: 100.0)])
    }

    @Test("Transport scrub changed clamps to zero")
    func testTransportScrubChanged_clampsToZero() {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 50)
        )

        let effects = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: -10.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 0) // Clamped to 0
        #expect(!state.transport.isPlaying) // Still paused
        #expect(effects == [.engineSeek(timeSec: 0)])
    }
    
    // MARK: - transportScrubEnded Tests

    @Test("Transport scrub ended commits time without toggling play state when paused", arguments: [0.0, 5.0, 42.0])
    func testTransportScrubEnded_commitsPausedWithoutToggling(_ timeSec: Double) {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 1.0)
        )
        state.isScrubbing = true // Simulate that we were scrubbing

        let effects = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: timeSec), now: fixedNow)

        #expect(state.transport.currentTimeSec == timeSec)
        #expect(!state.transport.isPlaying) // CRITICAL: Must NOT change playing state
        #expect(!state.isScrubbing) // Should clear scrubbing flag
        #expect(effects == [.engineSeek(timeSec: timeSec)])
    }

    @Test("Transport scrub ended commits time and restarts playback when was playing", arguments: [0.0, 5.0, 42.0, 88.0])
    func testTransportScrubEnded_commitsPlayingWithoutToggling(_ timeSec: Double) {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 1.0)
        )
        state.isScrubbing = true // Simulate that we were scrubbing

        let effects = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: timeSec), now: fixedNow)

        #expect(state.transport.currentTimeSec == timeSec)
        #expect(state.transport.isPlaying) // CRITICAL: Must NOT change playing state
        #expect(!state.isScrubbing) // Should clear scrubbing flag
        // When was playing, restart from new position
        #expect(effects == [.enginePlay(fromTimeSec: timeSec)])
    }
    
    @Test("Transport scrub ended clamps to valid range")
    func testTransportScrubEnded_clampsToValidRange() {
        var state = makeState(
            track: TrackMeta(name: "Test", durationSec: 100),
            transport: Transport(isPlaying: true, currentTimeSec: 50.0)
        )
        state.isScrubbing = true // Simulate that we were scrubbing

        // Test upper bound - when playing, should restart from clamped position
        var effects = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: 200.0), now: fixedNow)
        #expect(state.transport.currentTimeSec == 100.0) // Clamped to duration
        #expect(state.transport.isPlaying) // Still playing
        #expect(effects == [.enginePlay(fromTimeSec: 100.0)]) // Restart from clamped position
        
        // Test lower bound - when playing, should restart from clamped position
        state.isScrubbing = true // Reset scrubbing flag
        effects = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: -50.0), now: fixedNow)
        #expect(state.transport.currentTimeSec == 0.0) // Clamped to 0
        #expect(state.transport.isPlaying) // Still playing
        #expect(effects == [.enginePlay(fromTimeSec: 0.0)]) // Restart from clamped position
    }

    // MARK: - tick Tests

    @Test("Tick updates current time when not scrubbing")
    func testTick_updatesCurrentTime() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 10.0)
        )
        state.isScrubbing = false

        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 15.0), now: fixedNow)

        #expect(state.transport.currentTimeSec == 15.0)
        #expect(effects.isEmpty)
    }
    
    @Test("Tick is ignored while scrubbing to prevent overwriting user position")
    func testTick_ignoredDuringScrub() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 50.0)
        )
        state.isScrubbing = true // User is actively scrubbing

        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 15.0), now: fixedNow)

        // Tick should be ignored - position stays at user's scrub position
        #expect(state.transport.currentTimeSec == 50.0)
        #expect(effects.isEmpty)
    }
    
    // MARK: - Playback Resume Tests (Issue: waveform doesn't move, play restarts)
    
    @Test("Toggle play resumes from current position not start")
    func testTogglePlay_resumesFromCurrentPosition() {
        // Scenario: User paused at 45 seconds, presses play
        // Expected: Playback should resume from 45 seconds, not 0
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 45.0)
        )
        state.isScrubbing = false // Not scrubbing

        let effects = Reducer.reduce(state: &state, action: .togglePlay, now: fixedNow)

        #expect(state.transport.isPlaying == true)
        #expect(state.transport.currentTimeSec == 45.0) // Position unchanged
        // Should play from current position, not 0
        #expect(effects == [.enginePlay(fromTimeSec: 45.0)])
    }
    
    @Test("isScrubbing should be false by default and after normal operations")
    func testIsScrubbing_defaultState() {
        let state = makeState()
        // Default state should not be scrubbing
        #expect(state.isScrubbing == false)
    }
    
    @Test("Tick updates time during normal playback without scrubbing")
    func testTick_updatesTimeDuringPlayback() {
        // Scenario: User pressed play, tick events should update time
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 0.0)
        )
        // isScrubbing should default to false for new state

        // Simulate tick events coming from engine
        _ = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 1.0), now: fixedNow)
        #expect(state.transport.currentTimeSec == 1.0)
        
        _ = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 2.0), now: fixedNow)
        #expect(state.transport.currentTimeSec == 2.0)
        
        _ = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 3.0), now: fixedNow)
        #expect(state.transport.currentTimeSec == 3.0)
    }
    
    // MARK: - Full Scrubbing Workflow Tests (Integration-style)
    
    @Test("Full scrub workflow while playing: audio continues during drag, jumps on release")
    func testFullScrubWorkflow_whilePlaying() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 10.0)
        )
        
        // STEP 1: User starts dragging at position 20.0
        var effects = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 20.0), now: fixedNow)
        
        #expect(state.isScrubbing == true, "Should mark as scrubbing")
        #expect(state.transport.isPlaying == true, "isPlaying must NOT change during scrub")
        #expect(state.transport.currentTimeSec == 20.0, "Visual position should update")
        #expect(effects == [], "No engine effect - audio continues playing")
        
        // STEP 2: Tick events come from engine but should be ignored
        effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 11.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 20.0, "Tick should NOT overwrite user's scrub position")
        #expect(effects == [], "Tick while scrubbing produces no effects")
        
        // STEP 3: User continues dragging to 30.0
        effects = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 30.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 30.0, "Visual position should follow drag")
        #expect(state.transport.isPlaying == true, "isPlaying still unchanged")
        
        // STEP 4: More ticks come in (engine still playing at ~12.0)
        effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 12.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 30.0, "Still at user's drag position")
        
        // STEP 5: User releases drag at 30.0
        effects = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: 30.0), now: fixedNow)
        
        #expect(state.isScrubbing == false, "Scrubbing should end")
        #expect(state.transport.isPlaying == true, "isPlaying must NOT change")
        #expect(state.transport.currentTimeSec == 30.0, "Position committed")
        #expect(effects == [.enginePlay(fromTimeSec: 30.0)], "Engine restarts from new position")
        
        // STEP 6: Ticks should now update the position again
        effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 31.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 31.0, "Ticks should update position after scrub ends")
    }
    
    @Test("Full scrub workflow while paused: seek immediately for feedback")
    func testFullScrubWorkflow_whilePaused() {
        var state = makeState(
            transport: Transport(isPlaying: false, currentTimeSec: 10.0)
        )
        
        // STEP 1: User starts dragging at position 20.0
        var effects = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 20.0), now: fixedNow)
        
        #expect(state.isScrubbing == true, "Should mark as scrubbing")
        #expect(state.transport.isPlaying == false, "isPlaying must stay false")
        #expect(state.transport.currentTimeSec == 20.0, "Position should update")
        #expect(effects == [.engineSeek(timeSec: 20.0)], "When paused, seek immediately for feedback")
        
        // STEP 2: User continues dragging to 35.0
        effects = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 35.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 35.0)
        #expect(effects == [.engineSeek(timeSec: 35.0)], "Continue seeking")
        
        // STEP 3: User releases drag at 35.0
        effects = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: 35.0), now: fixedNow)
        
        #expect(state.isScrubbing == false, "Scrubbing should end")
        #expect(state.transport.isPlaying == false, "isPlaying must stay false")
        #expect(state.transport.currentTimeSec == 35.0, "Position committed")
        #expect(effects == [.engineSeek(timeSec: 35.0)], "Final seek to commit position")
    }
    
    @Test("Import resets isScrubbing flag")
    func testImport_resetsScrubbingFlag() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 50.0)
        )
        state.isScrubbing = true // Simulate stuck scrubbing state
        
        let url = URL(fileURLWithPath: "/test.mp3")
        _ = Reducer.reduce(state: &state, action: .importPicked(url: url), now: fixedNow)
        
        #expect(state.isScrubbing == false, "Import should reset isScrubbing")
        #expect(state.transport.currentTimeSec == 0, "Time should reset")
        #expect(state.transport.isPlaying == false, "Playing should stop")
    }
    
    @Test("Import succeeded resets isScrubbing flag")
    func testImportSucceeded_resetsScrubbingFlag() {
        var state = makeState(isLoading: true)
        state.isScrubbing = true // Simulate stuck scrubbing state
        
        let track = TrackMeta(name: "New Track", durationSec: 120)
        _ = Reducer.reduce(state: &state, action: .importSucceeded(track: track), now: fixedNow)
        
        #expect(state.isScrubbing == false, "Import succeeded should reset isScrubbing")
    }
    
    // MARK: - Problem 2 Regression: Pause button should work after scrubbing while playing
    // This tests the domain behavior for the bug where pause button turned into play after scrubbing
    
    @Test("Scrub while playing then pause: pause should work correctly")
    func testScrubWhilePlaying_thenPause_shouldWork() {
        // SCENARIO: User is playing, scrubs to new position, then wants to pause
        // BUG: Pause button would turn into play button and not work
        // EXPECTED: After scrub ends, togglePlay should still pause correctly
        
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 10.0)
        )
        
        // Step 1: Start scrubbing while playing
        _ = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 30.0), now: fixedNow)
        #expect(state.transport.isPlaying == true, "isPlaying unchanged during scrub")
        
        // Step 2: End scrub
        var effects = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: 30.0), now: fixedNow)
        #expect(state.transport.isPlaying == true, "isPlaying must still be true after scrub ends")
        #expect(effects == [.enginePlay(fromTimeSec: 30.0)], "Engine should restart from new position")
        
        // Step 3: Now user presses pause - THIS IS THE CRITICAL TEST
        effects = Reducer.reduce(state: &state, action: .togglePlay, now: fixedNow)
        
        #expect(state.transport.isPlaying == false, "CRITICAL: Pause should set isPlaying to false")
        #expect(effects == [.enginePause], "CRITICAL: Should send pause effect")
        #expect(state.transport.currentTimeSec == 30.0, "Position should remain at scrubbed position")
    }
    
    @Test("Scrub while playing then play again: should resume from scrubbed position")
    func testScrubWhilePlaying_thenPlayAgain_shouldResumeFromScrubPosition() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 10.0)
        )
        
        // Scrub to 50.0
        _ = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 50.0), now: fixedNow)
        _ = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: 50.0), now: fixedNow)
        
        // Pause
        _ = Reducer.reduce(state: &state, action: .togglePlay, now: fixedNow)
        #expect(state.transport.isPlaying == false)
        #expect(state.transport.currentTimeSec == 50.0)
        
        // Play again - should play from 50.0, not 0 or 10
        let effects = Reducer.reduce(state: &state, action: .togglePlay, now: fixedNow)
        
        #expect(state.transport.isPlaying == true)
        #expect(effects == [.enginePlay(fromTimeSec: 50.0)], "Should play from scrubbed position")
    }
    
    @Test("Multiple scrubs while playing: isPlaying should never change")
    func testMultipleScrubs_whilePlaying_isPlayingShouldNeverChange() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 10.0)
        )
        
        // First scrub
        _ = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 20.0), now: fixedNow)
        #expect(state.transport.isPlaying == true)
        _ = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: 20.0), now: fixedNow)
        #expect(state.transport.isPlaying == true)
        
        // Second scrub
        _ = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 40.0), now: fixedNow)
        #expect(state.transport.isPlaying == true)
        _ = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: 40.0), now: fixedNow)
        #expect(state.transport.isPlaying == true)
        
        // Third scrub
        _ = Reducer.reduce(state: &state, action: .transportScrubChanged(timeSec: 60.0), now: fixedNow)
        #expect(state.transport.isPlaying == true)
        _ = Reducer.reduce(state: &state, action: .transportScrubEnded(timeSec: 60.0), now: fixedNow)
        #expect(state.transport.isPlaying == true, "isPlaying must NEVER change during/after scrubs")
        
        // Final check: pause should still work
        _ = Reducer.reduce(state: &state, action: .togglePlay, now: fixedNow)
        #expect(state.transport.isPlaying == false, "Pause should work after multiple scrubs")
    }

    // MARK: - Loop Boundary Tests (Business Logic)
    
    @Test("Tick at loop boundary triggers seek to loop start")
    func testTick_atLoopBoundary_seeksToLoopStart() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 20.0),
            loop: LoopPoints(aSec: 10.0, bSec: 30.0, enabled: true)
        )
        
        // Tick at exactly loop end
        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 30.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 10.0, "Should jump to loop start")
        #expect(effects == [.enginePlay(fromTimeSec: 10.0)], "Should restart playback from loop start")
    }
    
    @Test("Tick past loop boundary triggers seek to loop start")
    func testTick_pastLoopBoundary_seeksToLoopStart() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 29.0),
            loop: LoopPoints(aSec: 10.0, bSec: 30.0, enabled: true)
        )
        
        // Tick past loop end
        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 31.5), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 10.0, "Should jump to loop start")
        #expect(effects == [.enginePlay(fromTimeSec: 10.0)], "Should restart playback from loop start")
    }
    
    @Test("Tick before loop boundary does not trigger loop")
    func testTick_beforeLoopBoundary_noLoop() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 20.0),
            loop: LoopPoints(aSec: 10.0, bSec: 30.0, enabled: true)
        )
        
        // Tick before loop end
        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 25.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 25.0, "Should update to tick time")
        #expect(effects.isEmpty, "No loop effect needed")
    }
    
    @Test("Tick at loop boundary with loop disabled does not trigger loop")
    func testTick_loopDisabled_noLoop() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 29.0),
            loop: LoopPoints(aSec: 10.0, bSec: 30.0, enabled: false) // Loop disabled
        )
        
        // Tick past loop end, but loop is disabled
        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 35.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 35.0, "Should update to tick time normally")
        #expect(effects.isEmpty, "No loop effect because loop is disabled")
    }
    
    @Test("Tick with incomplete loop points does not trigger loop")
    func testTick_incompleteLoopPoints_noLoop() {
        var state = makeState(
            transport: Transport(isPlaying: true, currentTimeSec: 25.0),
            loop: LoopPoints(aSec: 10.0, bSec: nil, enabled: true) // Missing B point
        )
        
        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 35.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 35.0, "Should update normally")
        #expect(effects.isEmpty, "No loop effect because loop points incomplete")
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
    
    // MARK: - tappedAButton Tests
    
    @Test("Tapped A button sets A at current playhead position")
    func testTappedAButton_setsAAtCurrentPlayhead() {
        var state = makeState(
            transport: Transport(currentTimeSec: 25.0),
            loop: LoopPoints()
        )
        
        let effects = Reducer.reduce(state: &state, action: .tappedAButton, now: fixedNow)
        
        #expect(state.loop.aSec == 25.0)
        #expect(effects == [.engineSetLoop(aSec: 25.0, bSec: nil, enabled: false)])
    }
    
    @Test("Tapped A button resets B when current time is past B")
    func testTappedAButton_resetsBWhenCurrentTimePastB() {
        var state = makeState(
            transport: Transport(currentTimeSec: 50.0),
            loop: LoopPoints(aSec: 10.0, bSec: 30.0, enabled: false) // B is at 30, current is at 50
        )
        
        let effects = Reducer.reduce(state: &state, action: .tappedAButton, now: fixedNow)
        
        #expect(state.loop.aSec == 50.0, "A should be set to current time")
        #expect(state.loop.bSec == nil, "B should be reset to nil (default) when current > B")
        #expect(effects == [.engineSetLoop(aSec: 50.0, bSec: nil, enabled: false)])
    }
    
    @Test("Tapped A button does not reset B when current time is before B")
    func testTappedAButton_doesNotResetBWhenCurrentTimeBeforeB() {
        var state = makeState(
            transport: Transport(currentTimeSec: 20.0),
            loop: LoopPoints(aSec: 10.0, bSec: 30.0, enabled: false) // B is at 30, current is at 20
        )
        
        let effects = Reducer.reduce(state: &state, action: .tappedAButton, now: fixedNow)
        
        #expect(state.loop.aSec == 20.0, "A should be set to current time")
        #expect(state.loop.bSec == 30.0, "B should remain unchanged")
        #expect(effects == [.engineSetLoop(aSec: 20.0, bSec: 30.0, enabled: false)])
    }
    
    // MARK: - tappedBButton Tests
    
    @Test("Tapped B button sets B at current playhead position")
    func testTappedBButton_setsBAtCurrentPlayhead() {
        var state = makeState(
            transport: Transport(currentTimeSec: 75.0),
            loop: LoopPoints()
        )
        
        let effects = Reducer.reduce(state: &state, action: .tappedBButton, now: fixedNow)
        
        #expect(state.loop.bSec == 75.0)
        #expect(effects == [.engineSetLoop(aSec: nil, bSec: 75.0, enabled: false)])
    }
    
    @Test("Tapped B button resets A when current time is before A")
    func testTappedBButton_resetsAWhenCurrentTimeBeforeA() {
        var state = makeState(
            transport: Transport(currentTimeSec: 5.0),
            loop: LoopPoints(aSec: 30.0, bSec: 60.0, enabled: false) // A is at 30, current is at 5
        )
        
        let effects = Reducer.reduce(state: &state, action: .tappedBButton, now: fixedNow)
        
        #expect(state.loop.bSec == 5.0, "B should be set to current time")
        #expect(state.loop.aSec == nil, "A should be reset to nil (default) when current < A")
        #expect(effects == [.engineSetLoop(aSec: nil, bSec: 5.0, enabled: false)])
    }
    
    @Test("Tapped B button does not reset A when current time is after A")
    func testTappedBButton_doesNotResetAWhenCurrentTimeAfterA() {
        var state = makeState(
            transport: Transport(currentTimeSec: 50.0),
            loop: LoopPoints(aSec: 30.0, bSec: 60.0, enabled: false) // A is at 30, current is at 50
        )
        
        let effects = Reducer.reduce(state: &state, action: .tappedBButton, now: fixedNow)
        
        #expect(state.loop.bSec == 50.0, "B should be set to current time")
        #expect(state.loop.aSec == 30.0, "A should remain unchanged")
        #expect(effects == [.engineSetLoop(aSec: 30.0, bSec: 50.0, enabled: false)])
    }
    
    // MARK: - Loop with Effective Values Tests
    
    @Test("Tick at effective B boundary with only A set triggers loop using default B")
    func testTick_atEffectiveBBoundary_withOnlyASet_triggersLoop() {
        // When only A is set, effective B = track duration (100.0)
        var state = makeState(
            track: TrackMeta(name: "Test", durationSec: 100),
            transport: Transport(isPlaying: true, currentTimeSec: 95.0),
            loop: LoopPoints(aSec: 10.0, bSec: nil, enabled: true) // B uses default (track duration)
        )
        
        // Tick at track end (effective B)
        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 100.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 10.0, "Should jump to A")
        #expect(effects == [.enginePlay(fromTimeSec: 10.0)], "Should restart from A")
    }
    
    @Test("Tick at effective A boundary with only B set uses default A of 0")
    func testTick_loopWithOnlyBSet_usesDefaultAOfZero() {
        // When only B is set, effective A = 0
        var state = makeState(
            track: TrackMeta(name: "Test", durationSec: 100),
            transport: Transport(isPlaying: true, currentTimeSec: 45.0),
            loop: LoopPoints(aSec: nil, bSec: 50.0, enabled: true) // A uses default (0)
        )
        
        // Tick at B boundary
        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 50.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 0, "Should jump to effective A (0)")
        #expect(effects == [.enginePlay(fromTimeSec: 0)], "Should restart from effective A")
    }
    
    @Test("Tick with both loop points nil uses full track as loop range")
    func testTick_withBothPointsNil_usesFullTrackRange() {
        // When both are nil: effective A = 0, effective B = track duration
        var state = makeState(
            track: TrackMeta(name: "Test", durationSec: 100),
            transport: Transport(isPlaying: true, currentTimeSec: 95.0),
            loop: LoopPoints(aSec: nil, bSec: nil, enabled: true)
        )
        
        // Tick at track end
        let effects = Reducer.reduce(state: &state, action: .tick(currentTimeSec: 100.0), now: fixedNow)
        
        #expect(state.transport.currentTimeSec == 0, "Should jump to effective A (0)")
        #expect(effects == [.enginePlay(fromTimeSec: 0)], "Should restart from 0")
    }
    
    // MARK: - Selectors Tests (Loop Overlay Visibility)
    
    @Test("shouldShowLoopOverlay returns false when loop is disabled")
    func testShouldShowLoopOverlay_whenDisabled_returnsFalse() {
        let state = makeState(
            loop: LoopPoints(aSec: 10.0, bSec: 20.0, enabled: false)
        )
        
        #expect(!Selectors.shouldShowLoopOverlay(state))
    }
    
    @Test("shouldShowLoopOverlay returns false when A is not set")
    func testShouldShowLoopOverlay_whenANotSet_returnsFalse() {
        let state = makeState(
            loop: LoopPoints(aSec: nil, bSec: 20.0, enabled: true)
        )
        
        #expect(!Selectors.shouldShowLoopOverlay(state))
    }
    
    @Test("shouldShowLoopOverlay returns false when B is not set")
    func testShouldShowLoopOverlay_whenBNotSet_returnsFalse() {
        let state = makeState(
            loop: LoopPoints(aSec: 10.0, bSec: nil, enabled: true)
        )
        
        #expect(!Selectors.shouldShowLoopOverlay(state))
    }
    
    @Test("shouldShowLoopOverlay returns false when neither A nor B is set")
    func testShouldShowLoopOverlay_whenNeitherSet_returnsFalse() {
        let state = makeState(
            loop: LoopPoints(aSec: nil, bSec: nil, enabled: true)
        )
        
        #expect(!Selectors.shouldShowLoopOverlay(state))
    }
    
    @Test("shouldShowLoopOverlay returns true when loop is enabled and both A and B are set")
    func testShouldShowLoopOverlay_whenEnabledAndBothSet_returnsTrue() {
        let state = makeState(
            loop: LoopPoints(aSec: 10.0, bSec: 20.0, enabled: true)
        )
        
        #expect(Selectors.shouldShowLoopOverlay(state))
    }
    
    @Test("shouldShowLoopOverlay returns false when both A and B are set but loop is disabled")
    func testShouldShowLoopOverlay_whenBothSetButDisabled_returnsFalse() {
        let state = makeState(
            loop: LoopPoints(aSec: 10.0, bSec: 20.0, enabled: false)
        )
        
        #expect(!Selectors.shouldShowLoopOverlay(state))
    }
}

