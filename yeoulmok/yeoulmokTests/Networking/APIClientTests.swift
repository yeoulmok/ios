import Foundation
import Testing
@testable import yeoulmok

struct APIClientTests {
    /// #101: server answers are never written to the HTTP cache on the device.
    @Test func appRequestsUseNoHTTPCache() {
        let client = APIClient(baseURL: URL(string: "https://example.invalid/api")!)
        #expect(client.session.configuration.urlCache == nil)
        #expect(client.session.configuration.requestCachePolicy == .reloadIgnoringLocalCacheData)
        #expect(client.session !== URLSession.shared)
    }

    private struct Echo: Decodable, Equatable { let ok: Bool }
    private struct Body: Encodable, Sendable {
        let apnsToken: String?
        enum CodingKeys: String, CodingKey { case apnsToken = "apns_token" }
    }

    @Test func buildsURLMethodHeadersAndQuery() async throws {
        let seen = Recorder()
        let client = StubURLProtocol.makeClient { request, _ in
            seen.record(request)
            return (200, #"{"ok": true}"#.utf8Data)
        }

        let result: Echo = try await client.send(.get, "valleys",
                                                 query: [URLQueryItem(name: "q", value: "금대리")],
                                                 headers: ["X-Device-Id": "d_123"])

        #expect(result == Echo(ok: true))
        let request = try #require(seen.last)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path() == "/api/valleys")
        #expect(request.url?.query(percentEncoded: false) == "q=금대리")
        #expect(request.value(forHTTPHeaderField: "X-Device-Id") == "d_123")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func noQueryMeansNoQuestionMark() async throws {
        let seen = Recorder()
        let client = StubURLProtocol.makeClient { request, _ in
            seen.record(request)
            return (200, #"{"ok": true}"#.utf8Data)
        }

        let _: Echo = try await client.send(.get, "me/valleys")

        #expect(seen.last?.url?.absoluteString.hasSuffix("/api/me/valleys") == true)
    }

    @Test func sendsBodyAsJSON() async throws {
        let sentBody = Recorder()
        let client = StubURLProtocol.makeClient { request, body in
            sentBody.record(request, body: body)
            return (201, #"{"ok": true}"#.utf8Data)
        }

        let _: Echo = try await client.send(.post, "devices", body: Body(apnsToken: nil))

        #expect(sentBody.last?.httpMethod == "POST")
        #expect(sentBody.last?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let json = try #require(sentBody.lastBody)
        #expect(try JSONSerialization.jsonObject(with: json) as? [String: Any] != nil)
    }

    @Test func decodesServerTimesAsKoreanTime() async throws {
        struct Timed: Decodable { let updatedAt: Date
            enum CodingKeys: String, CodingKey { case updatedAt = "updated_at" } }
        let client = StubURLProtocol.makeClient { _, _ in
            (200, #"{"updated_at": "2026-11-07T22:00"}"#.utf8Data)
        }

        let timed: Timed = try await client.send(.get, "valleys")

        #expect(timed.updatedAt == ServerDate.parse("2026-11-07T22:00"))
    }

    @Test func serverErrorBodyBecomesAPIError() async {
        let client = StubURLProtocol.makeClient { _, _ in
            (404, #"{"error": {"code": "DEVICE_NOT_FOUND", "message": "기기 정보를 확인할 수 없어요"}}"#.utf8Data)
        }

        await #expect(throws: APIError(code: "DEVICE_NOT_FOUND", message: "기기 정보를 확인할 수 없어요")) {
            let _: Echo = try await client.send(.patch, "devices")
        }
    }

    @Test func otherErrorStatusBecomesHTTPStatusError() async {
        let client = StubURLProtocol.makeClient { _, _ in (502, "<html>Bad Gateway</html>".utf8Data) }

        await #expect(throws: HTTPStatusError(statusCode: 502)) {
            let _: Echo = try await client.send(.get, "valleys")
        }
    }

    @Test func connectionErrorPassesThrough() async {
        let client = StubURLProtocol.makeClient { _, _ in throw URLError(.notConnectedToInternet) }

        await #expect {
            let _: Echo = try await client.send(.get, "valleys")
        } throws: { error in
            (error as? URLError)?.code == .notConnectedToInternet
        }
    }

    @Test func nonServerErrorsShowConnectionMessage() {
        // The screen sentence for a 502 is the same as for no network (ErrorMessage).
        #expect(ErrorMessage.text(for: HTTPStatusError(statusCode: 502)) == "연결할 수 없어요")
    }
}

/// Keeps what the fake network received, for checks after the call.
private final class Recorder: @unchecked Sendable {
    private let lock = NSLock()
    private var requests: [(URLRequest, Data?)] = []

    func record(_ request: URLRequest, body: Data? = nil) {
        lock.withLock { requests.append((request, body)) }
    }

    var last: URLRequest? { lock.withLock { requests.last?.0 } }
    var lastBody: Data? { lock.withLock { requests.last?.1 } }
}
