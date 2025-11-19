import Dependencies
import Foundation

extension ApiClient: DependencyKey {
    public static let liveValue = Self.live(
        baseUrl: URL(string: "https://swolytics-backend.fly.dev")!
    )
    
    public static func live(
        baseUrl: URL
    ) -> Self {
        actor Session {
            nonisolated let baseUrl: URL
            
            init(baseUrl: URL) {
                self.baseUrl = baseUrl
            }
            
            func apiRequest(route: ServerRoute.Api.Route) async throws -> (Data, URLResponse) {
                switch route {
                case .currentWorkout(let rawText):
                    let url = baseUrl.appendingPathComponent("strong/current_workout")
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let body = StrongWorkoutRequest(jobId: UUID().uuidString, rawText: rawText)
                    request.httpBody = try JSONEncoder().encode(body)
                    
                    return try await URLSession.shared.data(for: request)
                }
            }
            
            func request(route: ServerRoute) async throws -> (Data, URLResponse) {
                switch route {
                case .api(let api):
                    return try await apiRequest(route: api.route)
                default:
                    throw ApiError(error: URLError(.badURL), file: #file, line: #line)
                }
            }
        }
        
        let session = Session(baseUrl: baseUrl)
        
        return Self(
            apiRequest: { try await session.apiRequest(route: $0) },
            baseUrl: { session.baseUrl },
            logout: { },
            request: { try await session.request(route: $0) },
            setBaseUrl: { _ in }
        )
    }
}

extension DependencyValues {
    public var apiClient: ApiClient {
        get { self[ApiClient.self] }
        set { self[ApiClient.self] = newValue }
    }
} 
