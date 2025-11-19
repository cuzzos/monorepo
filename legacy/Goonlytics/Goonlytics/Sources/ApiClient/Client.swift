import DependenciesMacros
import Foundation

@DependencyClient
public struct ApiClient: Sendable {
  public var apiRequest: @Sendable (ServerRoute.Api.Route) async throws -> (Data, URLResponse)
  public var baseUrl: @Sendable () -> URL = { URL(string: "/")! }
  public var logout: @Sendable () async -> Void
  public var request: @Sendable (ServerRoute) async throws -> (Data, URLResponse)
  public var setBaseUrl: @Sendable (URL) async -> Void

  public func apiRequest(
    route: ServerRoute.Api.Route,
    file: StaticString = #file,
    line: UInt = #line
  ) async throws -> (Data, URLResponse) {
    do {
      let (data, response) = try await self.apiRequest(route)
      #if DEBUG
        print(
          """
          API: route: \(route), \
          status: \((response as? HTTPURLResponse)?.statusCode ?? 0), \
          receive data: \(String(decoding: data, as: UTF8.self))
          """
        )
      #endif
      return (data, response)
    } catch {
      throw ApiError(error: error, file: file, line: line)
    }
  }

  public func apiRequest<A: Decodable>(
    route: ServerRoute.Api.Route,
    as: A.Type,
    file: StaticString = #file,
    line: UInt = #line
  ) async throws -> A {
    let (data, _) = try await self.apiRequest(route: route, file: file, line: line)
    do {
      return try apiDecode(A.self, from: data)
    } catch {
      throw ApiError(error: error, file: file, line: line)
    }
  }

  public func request(
    route: ServerRoute,
    file: StaticString = #file,
    line: UInt = #line
  ) async throws -> (Data, URLResponse) {
    do {
      let (data, response) = try await self.request(route)
      #if DEBUG
        print(
          """
          API: route: \(route), \
          status: \((response as? HTTPURLResponse)?.statusCode ?? 0), \
          receive data: \(String(decoding: data, as: UTF8.self))
          """
        )
      #endif
      return (data, response)
    } catch {
      throw ApiError(error: error, file: file, line: line)
    }
  }

  public func request<A: Decodable>(
    route: ServerRoute,
    as: A.Type,
    file: StaticString = #file,
    line: UInt = #line
  ) async throws -> A {
    let (data, _) = try await self.request(route: route, file: file, line: line)
    do {
      return try apiDecode(A.self, from: data)
    } catch {
      throw ApiError(error: error, file: file, line: line)
    }
  }
}

let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

extension Task where Failure == Never {
  /// An async function that never returns.
  static func never() async throws -> Success {
    for await element in AsyncStream<Success>.never {
      return element
    }
    throw _Concurrency.CancellationError()
  }
}
extension AsyncStream {
  static var never: Self {
    Self { _ in }
  }
}
