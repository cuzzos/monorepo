import SwiftUI
import UniformTypeIdentifiers

/// Main content view composing all UI components
struct ContentView: View {
    @Bindable var core: Core
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignColors.bg
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    TrackRow(
                        trackName: core.state.track?.name,
                        onImportTapped: { showingFilePicker = true }
                    )
                    
                    contentView()
                        .frame(maxHeight: .infinity)
                    
                    VStack(spacing: 0) {
                        ModeBar(
                            currentMode: core.state.mode,
                            loopEnabled: core.state.loop.enabled,
                            onModeSelected: { mode in
                                core.send(.setMode(mode))
                            },
                            onLoopToggle: { enabled in
                                core.send(.toggleLoopEnabled(enabled))
                            }
                        )
                        .padding(.vertical, 8)
                        
                        TransportBar(
                            state: core.state,
                            onSpeedDelta: { delta in
                                core.send(.speedDelta(delta))
                            },
                            onPitchDelta: { delta in
                                core.send(.pitchDelta(delta))
                            },
                            onTogglePlay: {
                                core.send(.togglePlay)
                            },
                            onSeekPrev: {
                                // Seek to A if set, otherwise start
                                let time = core.state.loop.aSec ?? 0
                                core.send(.dragScrub(timeSec: time))
                            },
                            onSeekNext: {
                                // Seek to B if set, otherwise end
                                let duration = core.state.track?.durationSec ?? 0
                                let time = core.state.loop.bSec ?? duration
                                core.send(.dragScrub(timeSec: time))
                            }
                        )
                        .padding(.bottom, 16)
                    }
                    .overlay {
                        if core.state.track == nil {
                            // Semi-transparent overlay when no track is loaded
                            Color.black.opacity(0.3)
                                .allowsHitTesting(true) // Blocks interaction
                        }
                    }
                }
                .padding(.horizontal)
                .safeAreaPadding(.bottom, 16)
                
                // Toast overlay
                VStack {
                    Spacer()
                        .frame(height: 200)
                    ToastOverlay(toast: core.state.toast)
                    Spacer()
                }
            }
            .navigationTitle("sharp9")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") {
                        // Dismiss action - for now does nothing as this is the main view
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Menu", systemImage: "line.3.horizontal") {
                        // Menu action
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            .toolbarBackground(DesignColors.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: audioContentTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .onAppear {
                core.send(.onAppear)
            }
        }
    }
    
    // MARK: - Content State
    
    @ViewBuilder
    private func contentView() -> some View {
        if core.state.track != nil {
            // Has track loaded - show full UI
            trackLoadedContent()
        } else if core.state.isLoading {
            // Loading state
            loadingContent()
        } else {
            // Empty state
            emptyContent()
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private func trackLoadedContent() -> some View {
        VStack(spacing: 0) {
            // Keyboard strip
            KeyboardStrip()
                .padding(.vertical, 8)
            
            // Main waveform
            WaveformView(
                peaks: core.peaks,
                state: core.state,
                onTap: { time in
                    core.send(.tapWaveform(timeSec: time))
                },
                onDrag: { time in
                    core.send(.dragScrub(timeSec: time))
                }
            )
            
            // Overview waveform
            OverviewWaveformView(
                peaks: core.peaks,
                state: core.state,
                onTap: { time in
                    core.send(.dragScrub(timeSec: time))
                }
            )
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func loadingContent() -> some View {
        VStack {
            Spacer()
            
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.5)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func emptyContent() -> some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignColors.textTertiary)
                
                Text("Tap 'Import File' to get started")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
    
    // MARK: - File Import
    
    private var audioContentTypes: [UTType] {
        [
            .wav,
            .aiff,
            .mp3,
            UTType(filenameExtension: "m4a") ?? .audio,
            UTType(filenameExtension: "caf") ?? .audio,
            UTType(filenameExtension: "aac") ?? .audio
        ]
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            core.send(.importPicked(url: url))
            
        case .failure:
            core.send(.importFailed(message: "Unable to open file"))
        }
    }
}

#Preview {
    ContentView(core: Core(deps: .live))
}

#Preview("Christmas Time is Here") {
    let core = Core(deps: .live)
    core.state = AppState(
        track: TrackMeta(name: "Christmas Time is Here", durationSec: 180.0),
        transport: Transport(isPlaying: false, currentTimeSec: 45.0, speed: 1.0, pitchSemitones: 0.0),
        loop: LoopPoints(aSec: 30.0, bSec: 90.0, enabled: true),
        mode: .loop
    )
    return ContentView(core: core)
}

