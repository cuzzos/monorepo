import Foundation

/// The complete application state
struct AppState: Sendable, Equatable {
    var track: TrackMeta?
    var transport: Transport
    var loop: LoopPoints
    var mode: Mode
    var markers: [Marker]
    var viewport: Viewport
    var isLoading: Bool
    var toast: ToastState?
    /// Track if user is actively scrubbing (to ignore engine tick events during scrub)
    var isScrubbing: Bool
    
    init(
        track: TrackMeta? = nil,
        transport: Transport = Transport(),
        loop: LoopPoints = LoopPoints(),
        mode: Mode = .loop,
        markers: [Marker] = [],
        viewport: Viewport = Viewport(),
        isLoading: Bool = false,
        toast: ToastState? = nil,
        isScrubbing: Bool = false
    ) {
        self.track = track
        self.transport = transport
        self.loop = loop
        self.mode = mode
        self.markers = markers
        self.viewport = viewport
        self.isLoading = isLoading
        self.toast = toast
        self.isScrubbing = isScrubbing
    }
}

