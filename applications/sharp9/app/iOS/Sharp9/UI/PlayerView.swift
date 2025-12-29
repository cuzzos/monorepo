import SwiftUI
import UniformTypeIdentifiers

/// Main content view composing all UI components
struct PlayerView: View {
    @Bindable var core: Core
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 0) {
                TrackRow(
                    trackName: core.state.track?.name,
                    onImportTapped: { showingFilePicker = true }
                ).padding()
                
                contentView()
                    .frame(maxHeight: .infinity)
                
                VStack(spacing: 0) {
                    LoopBar(
                        selectedTool: core.state.tool,
                        isLoopEnabled: core.state.loop.enabled,
                        hasLoopStart: core.state.loop.aSec != nil,
                        hasLoopEnd: core.state.loop.bSec != nil,
                        onToolSelected: { tool in
                            core.send(.setTool(tool))
                        },
                        onSetLoopEnabled: { enabled in
                            core.send(.toggleLoopEnabled(enabled))
                        },
                        onSetLoopStart: {
                            core.send(.setA(timeSec: core.state.transport.currentTimeSec))
                        },
                        onSetLoopEnd: {
                            core.send(.setB(timeSec: core.state.transport.currentTimeSec))
                        }
                    )
                    .padding(.vertical, 8)
                    
                    PlaybackBar(
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
                            // Seek to effective A position
                            let duration = core.state.track?.durationSec ?? 0
                            let time = core.state.loop.effectiveA(trackDuration: duration)
                            core.send(.transportScrubEnded(timeSec: time))
                        },
                        onSeekNext: {
                            // Seek to effective B position
                            let duration = core.state.track?.durationSec ?? 0
                            let time = core.state.loop.effectiveB(trackDuration: duration)
                            core.send(.transportScrubEnded(timeSec: time))
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
            .safeAreaPadding(.bottom, 16)
            .background(DesignColors.bg.ignoresSafeArea())
            .overlay {
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
                    core.send(.togglePlay)
                },
                onDrag: { time in
                    core.send(.transportScrubChanged(timeSec: time))
                },
                onDragEnded: { time in
                    core.send(.transportScrubEnded(timeSec: time))
                }
            )
            
            // Overview waveform
            OverviewWaveformView(
                peaks: core.peaks,
                state: core.state,
                onTap: { time in
                    // Tap in overview should immediately seek and commit
                    core.send(.transportScrubEnded(timeSec: time))
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
    PlayerView(core: Core(deps: .live))
}
//
//#Preview("Christmas Time is Here") {
//    let core = Core(deps: .live)
//    core.state = AppState(
//        track: TrackMeta(name: "Christmas Time is Here", durationSec: 180.0),
//        transport: Transport(isPlaying: false, currentTimeSec: 45.0, speed: 1.0, pitchSemitones: 0.0),
//        loop: LoopPoints(aSec: 30.0, bSec: 90.0, enabled: true),
//        mode: .loop
//    )
//    return PlayerView(core: core)
//}
//
