import AVFoundation

/// Default audio engine implementation using AVAudioEngine
///
/// This engine is STATELESS - it does not track playhead position or playing state.
/// All state lives in the Model (AppState.transport). This class is a pure executor
/// of commands from the EffectRunner.
final class DefaultAudioEngine: AudioEngine, @unchecked Sendable {
    
    var onTimeUpdate: (@Sendable (Double) -> Void)?
    var onPlaybackFinished: (@Sendable () -> Void)?
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    
    private var audioFile: AVAudioFile?
    private var audioBuffer: AVAudioPCMBuffer?
    
    // Loop configuration (set via setLoop, used by play)
    private var loopA: Double?
    private var loopB: Double?
    private var loopEnabled = false
    
    // Time tracking for callbacks (needed to compute absolute time from player node)
    private var playbackStartOffset: Double = 0
    private var timeUpdateTask: Task<Void, Never>?
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        engine.attach(playerNode)
        engine.attach(timePitch)
        
        engine.connect(playerNode, to: timePitch, format: nil)
        engine.connect(timePitch, to: engine.mainMixerNode, format: nil)
    }
    
    func load(url: URL) async throws -> TrackMeta {
        // Stop any current playback
        stopPlayback()
        
        // Access security-scoped resource if needed
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url)
        } catch let error as NSError {
            // Handle specific AVAudioFile errors
            if error.domain == "com.apple.coreaudio.avfaudio" {
                switch error.code {
                case -10868:
                    throw AudioEngineError.invalidFormat
                case -43: // File not found
                    throw AudioEngineError.fileNotFound
                default:
                    throw AudioEngineError.loadFailed("Audio format not supported (error \(error.code))")
                }
            } else {
                throw AudioEngineError.loadFailed("Failed to open audio file: \(error.localizedDescription)")
            }
        }

        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioEngineError.loadFailed("Could not create buffer")
        }
        
        try file.read(into: buffer)
        
        self.audioFile = file
        self.audioBuffer = buffer
        
        // Connect with the file's format
        engine.disconnectNodeOutput(playerNode)
        engine.connect(playerNode, to: timePitch, format: format)
        
        if !engine.isRunning {
            try engine.start()
        }
        
        let duration = Double(file.length) / file.processingFormat.sampleRate
        let name = url.deletingPathExtension().lastPathComponent
        
        // Reset loop configuration
        loopA = nil
        loopB = nil
        loopEnabled = false
        
        return TrackMeta(name: name, durationSec: duration)
    }
    
    func play(from timeSec: Double) {
        guard let file = audioFile, let buffer = audioBuffer else { return }
        
        // Stop any current playback first
        stopPlayback()
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        let sampleRate = file.processingFormat.sampleRate
        let duration = Double(file.length) / sampleRate
        let clampedTime = max(0, min(timeSec, duration))
        
        // Record start offset for time calculations
        playbackStartOffset = clampedTime
        
        // Schedule and start playback
        schedulePlayback(from: clampedTime, buffer: buffer, file: file)
        playerNode.play()
        startTimeUpdateLoop(sampleRate: sampleRate)
    }
    
    func pause() {
        stopPlayback()
    }
    
    func setRate(_ rate: Double) {
        timePitch.rate = Float(rate)
    }
    
    func setPitchSemitones(_ semitones: Double) {
        // AVAudioUnitTimePitch uses cents (100 cents = 1 semitone)
        timePitch.pitch = Float(semitones * 100)
    }
    
    func setLoop(aSec: Double?, bSec: Double?, enabled: Bool) {
        self.loopA = aSec
        self.loopB = bSec
        self.loopEnabled = enabled
    }
    
    // MARK: - Private Methods
    
    private func stopPlayback() {
        timeUpdateTask?.cancel()
        timeUpdateTask = nil
        playerNode.stop()
    }
    
    private func schedulePlayback(from startTime: Double, buffer: AVAudioPCMBuffer, file: AVAudioFile) {
        let sampleRate = file.processingFormat.sampleRate
        let totalFrames = AVAudioFrameCount(file.length)
        let startFrame = AVAudioFramePosition(startTime * sampleRate)
        
        if loopEnabled, let a = loopA, let b = loopB, a < b {
            // Loop mode: schedule the loop region
            scheduleLoopRegion(a: a, b: b, file: file, buffer: buffer)
        } else {
            // Normal playback: schedule from start position to end
            let remainingFrames = totalFrames - AVAudioFrameCount(startFrame)
            
            if startFrame == 0 {
                // Play from beginning - use original buffer
                playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                    self?.handlePlaybackCompletion()
                }
            } else if remainingFrames > 0 {
                // Play from offset - create a sub-buffer
                guard let seekBuffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: remainingFrames
                ) else { return }
                
                // Copy frames from startFrame to end
                if let srcData = buffer.floatChannelData,
                   let dstData = seekBuffer.floatChannelData {
                    let channelCount = Int(file.processingFormat.channelCount)
                    for ch in 0..<channelCount {
                        memcpy(
                            dstData[ch],
                            srcData[ch].advanced(by: Int(startFrame)),
                            Int(remainingFrames) * MemoryLayout<Float>.size
                        )
                    }
                    seekBuffer.frameLength = remainingFrames
                }
                
                playerNode.scheduleBuffer(seekBuffer, at: nil, options: []) { [weak self] in
                    self?.handlePlaybackCompletion()
                }
            }
        }
    }
    
    private func scheduleLoopRegion(a: Double, b: Double, file: AVAudioFile, buffer: AVAudioPCMBuffer) {
        let sampleRate = file.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(a * sampleRate)
        let endFrame = AVAudioFramePosition(b * sampleRate)
        let loopFrameCount = AVAudioFrameCount(endFrame - startFrame)
        
        guard loopFrameCount > 0 else { return }
        
        // Create a buffer for the loop region
        guard let loopBuffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: loopFrameCount
        ) else { return }
        
        if let srcData = buffer.floatChannelData,
           let dstData = loopBuffer.floatChannelData {
            let channelCount = Int(file.processingFormat.channelCount)
            for ch in 0..<channelCount {
                memcpy(
                    dstData[ch],
                    srcData[ch].advanced(by: Int(startFrame)),
                    Int(loopFrameCount) * MemoryLayout<Float>.size
                )
            }
            loopBuffer.frameLength = loopFrameCount
        }
        
        // Schedule with loop option (loops indefinitely)
        playerNode.scheduleBuffer(loopBuffer, at: nil, options: .loops, completionHandler: nil)
    }
    
    private func handlePlaybackCompletion() {
        Task { @MainActor [weak self] in
            self?.onPlaybackFinished?()
        }
    }
    
    private func startTimeUpdateLoop(sampleRate: Double) {
        timeUpdateTask?.cancel()
        
        timeUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                let time = self.computeCurrentTime(sampleRate: sampleRate)
                
                // Handle loop boundary (for software-managed looping during playback)
                if self.loopEnabled,
                   let b = self.loopB,
                   time >= b,
                   let a = self.loopA {
                    // Jump back to loop start
                    self.play(from: a)
                    break // Exit this loop, new one will start
                }
                
                self.onTimeUpdate?(time)
                
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }
    
    private func computeCurrentTime(sampleRate: Double) -> Double {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return playbackStartOffset
        }
        
        // playerTime is relative to the scheduled buffer, add the start offset
        return playbackStartOffset + Double(playerTime.sampleTime) / sampleRate
    }
}
