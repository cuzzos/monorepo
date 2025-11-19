import Foundation

public struct StrongWorkoutRequest: Codable, Equatable {
    public let jobId: String
    public let rawText: String
    
    public init(jobId: String, rawText: String) {
        self.jobId = jobId
        self.rawText = rawText
    }
    
    private enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case rawText = "raw_text"
    }
} 