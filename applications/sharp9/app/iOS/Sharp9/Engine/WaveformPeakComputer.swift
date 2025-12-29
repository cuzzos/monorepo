import AVFoundation
import Accelerate

/// Computes waveform peaks from audio files
final class WaveformPeakComputer: Sendable {
    
    init() {}
    
    /// Compute peaks from an audio file URL
    /// - Parameters:
    ///   - url: The audio file URL
    ///   - targetBuckets: Number of buckets to compute
    /// - Returns: WaveformPeaks data
    func computePeaks(url: URL, targetBuckets: Int) async throws -> WaveformPeaks {
        try await Task.detached(priority: .userInitiated) {
            try self.computePeaksSync(url: url, targetBuckets: targetBuckets)
        }.value
    }
    
    private func computePeaksSync(url: URL, targetBuckets: Int) throws -> WaveformPeaks {
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)
        
        guard frameCount > 0 else {
            return .empty
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioEngineError.loadFailed("Could not create audio buffer")
        }
        
        try audioFile.read(into: buffer)
        
        guard let floatData = buffer.floatChannelData else {
            throw AudioEngineError.loadFailed("Could not read float channel data")
        }
        
        let channelCount = Int(format.channelCount)
        let sampleCount = Int(buffer.frameLength)
        let durationSec = Double(audioFile.length) / format.sampleRate
        
        // Mix down to mono if stereo
        var monoSamples = [Float](repeating: 0, count: sampleCount)
        
        if channelCount == 1 {
            monoSamples = Array(UnsafeBufferPointer(start: floatData[0], count: sampleCount))
        } else {
            // Average all channels
            for i in 0..<sampleCount {
                var sum: Float = 0
                for ch in 0..<channelCount {
                    sum += floatData[ch][i]
                }
                monoSamples[i] = sum / Float(channelCount)
            }
        }
        
        // Compute min/max per bucket
        let buckets = min(targetBuckets, sampleCount)
        let samplesPerBucket = sampleCount / buckets
        
        var minPeaks = [Float](repeating: 0, count: buckets)
        var maxPeaks = [Float](repeating: 0, count: buckets)
        
        for bucket in 0..<buckets {
            let startSample = bucket * samplesPerBucket
            let endSample = min(startSample + samplesPerBucket, sampleCount)
            let range = startSample..<endSample
            
            if range.isEmpty { continue }
            
            var minVal: Float = 0
            var maxVal: Float = 0
            
            monoSamples.withUnsafeBufferPointer { ptr in
                let slice = UnsafeBufferPointer(rebasing: ptr[range])
                vDSP_minv(slice.baseAddress!, 1, &minVal, vDSP_Length(slice.count))
                vDSP_maxv(slice.baseAddress!, 1, &maxVal, vDSP_Length(slice.count))
            }
            
            minPeaks[bucket] = minVal
            maxPeaks[bucket] = maxVal
        }
        
        return WaveformPeaks(
            min: minPeaks,
            max: maxPeaks,
            buckets: buckets,
            durationSec: durationSec
        )
    }
}

