import Foundation
@testable import yeoulmok

/// Fake network for tests: requests never leave the machine, a closure answers them.
///
/// Swift Testing runs tests in parallel, so each test gets its own host
/// (`StubURLProtocol.makeClient`) and only its own requests reach its closure.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest, Data?) throws -> (status: Int, body: Data)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var handlers: [String: Handler] = [:]

    /// An `APIClient` whose requests are answered by `handler` instead of the network.
    static func makeClient(_ handler: @escaping Handler) -> APIClient {
        let host = "test-\(UUID().uuidString.lowercased()).invalid"
        lock.withLock { handlers[host] = handler }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return APIClient(baseURL: URL(string: "https://\(host)/api")!,
                         session: URLSession(configuration: configuration))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let host = request.url?.host() ?? ""
        let handler = Self.lock.withLock { Self.handlers[host] }
        do {
            guard let handler else { throw URLError(.cannotFindHost) }
            let (status, body) = try handler(request, Self.body(of: request))
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    /// URLSession moves `httpBody` into a stream before it reaches a URLProtocol.
    private static func body(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

extension String {
    /// Test JSON as `Data`.
    var utf8Data: Data { Data(utf8) }
}
