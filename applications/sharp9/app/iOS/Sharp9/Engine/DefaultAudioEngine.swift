import AVFoundation

/// Default audio engine implementation using AVAudioEngine
final class DefaultAudioEngine: AudioEngine, @unchecked Sendable {
    
    var onTimeUpdate: (@Sendable (Double) -> Void)?
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    
    private var audioFile: AVAudioFile?
    private var audioBuffer: AVAudioPCMBuffer?
    private var isPlaying = false
    
    private var loopA: Double?
    private var loopB: Double?
    private var loopEnabled = false
    
    private var timeUpdateTask: Task<Void, Never>?
    private var currentRate: Double = 1.0
    
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
        // Stop current playback
        pause()
        
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
        
        return TrackMeta(name: name, durationSec: duration)
    }
    
    func play() {
        guard audioBuffer != nil else { return }
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        isPlaying = true
        schedulePlayback(from: currentTimeSec())
        playerNode.play()
        startTimeUpdateLoop()
    }
    
    func pause() {
        isPlaying = false
        playerNode.pause()
        stopTimeUpdateLoop()
    }
    
    func seek(to timeSec: Double) {
        guard let file = audioFile else { return }
        
        let wasPlaying = isPlaying
        playerNode.stop()
        
        let sampleRate = file.processingFormat.sampleRate
        let clampedTime = max(0, min(timeSec, Double(file.length) / sampleRate))
        
        if wasPlaying {
            schedulePlayback(from: clampedTime)
            playerNode.play()
        }
    }
    
    func setRate(_ rate: Double) {
        currentRate = rate
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
        
        // If currently playing and loop settings changed, reschedule
        if isPlaying {
            let currentTime = currentTimeSec()
            playerNode.stop()
            schedulePlayback(from: currentTime)
            playerNode.play()
        }
    }
    
    func currentTimeSec() -> Double {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return 0
        }
        
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }
    
    // MARK: - Private Methods
    
    private func schedulePlayback(from startTime: Double) {
        guard let file = audioFile, let buffer = audioBuffer else { return }
        
        let sampleRate = file.processingFormat.sampleRate
        let totalFrames = AVAudioFrameCount(file.length)
        
        // Calculate start frame
        let startFrame = AVAudioFramePosition(startTime * sampleRate)
        
        if loopEnabled, let a = loopA, let b = loopB, a < b {
            // Loop mode: schedule the loop region
            scheduleLoopRegion(a: a, b: b, sampleRate: sampleRate, totalFrames: totalFrames)
        } else {
            // Normal playback: schedule from current position to end
            playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                Task { @MainActor in
                    self?.isPlaying = false
                    self?.stopTimeUpdateLoop()
                }
            }
            
            // Seek to start position
            if startFrame > 0 {
                playerNode.stop()
                
                let remainingFrames = totalFrames - AVAudioFrameCount(startFrame)
                if remainingFrames > 0 {
                    guard let seekBuffer = AVAudioPCMBuffer(
                        pcmFormat: file.processingFormat,
                        frameCapacity: remainingFrames
                    ) else { return }
                    
                    // Copy frames from startFrame
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
                        Task { @MainActor in
                            self?.isPlaying = false
                            self?.stopTimeUpdateLoop()
                        }
                    }
                }
            }
        }
    }
    
    private func scheduleLoopRegion(a: Double, b: Double, sampleRate: Double, totalFrames: AVAudioFrameCount) {
        guard let buffer = audioBuffer, let file = audioFile else { return }
        
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
        
        // Schedule with loop option
        playerNode.scheduleBuffer(loopBuffer, at: nil, options: .loops, completionHandler: nil)
    }
    
    private func startTimeUpdateLoop() {
        stopTimeUpdateLoop()
        
        timeUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, self.isPlaying else { break }
                
                let time = self.currentTimeSec()
                
                // Check for loop boundary
                if self.loopEnabled,
                   let b = self.loopB,
                   time >= b,
                   let a = self.loopA {
                    self.seek(to: a)
                }
                
                self.onTimeUpdate?(time)
                
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }
    
    private func stopTimeUpdateLoop() {
        timeUpdateTask?.cancel()
        timeUpdateTask = nil
    }
}

