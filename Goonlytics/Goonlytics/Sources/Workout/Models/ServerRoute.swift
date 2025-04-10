import Foundation

public enum ServerRoute: Equatable {
  case api(Api)
  
  public struct Api: Equatable {
    public let route: Route
    
    public init(route: Route) {
      self.route = route
    }
    
    public enum Route: Equatable {
      case currentWorkout(rawText: String)
    }
  }
}