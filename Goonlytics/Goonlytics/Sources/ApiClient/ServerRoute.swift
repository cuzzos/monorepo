import Foundation

public enum ServerRoute: Equatable, Sendable {
  case api(Api)
  
  public struct Api: Equatable, Sendable {
    public let route: Route
    
    public init(route: Route) {
      self.route = route
    }
    
    public enum Route: Equatable, Sendable {
      case currentWorkout(rawText: String)
    }
  }
}