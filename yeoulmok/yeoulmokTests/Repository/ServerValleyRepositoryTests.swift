import Foundation
import Testing
@testable import yeoulmok

struct ServerValleyRepositoryTests {
    private static let list = #"""
    {"updated_at": "2026-11-07T22:00", "source": "자료: 한강홍수통제소, 기상청", "valleys": [
      {"id": 1, "name": "금대리 계곡", "region": "원주시 판부면", "lat": 37.27, "lon": 128.01,
       "level": "safe", "rain_1h_mm": 0.0, "water_rise_30m_m": null,
       "observed_at": "2026-11-07T21:50", "stale": false, "subscribed": true}]}
    """#
    private static let subscribed = #"{"valley_id": 1, "subscribed": true}"#
    private static let notFound = #"{"error": {"code": "DEVICE_NOT_FOUND", "message": "기기 정보를 확인할 수 없어요"}}"#

    @Test func listSendsDeviceIDAndDecodes() async throws {
        let server = FakeServer { _ in (200, Self.list) }
        let repository = server.repository(savedID: "d_saved")

        let response = try await repository.valleys(matching: nil)

        #expect(response.valleys.map(\.name) == ["금대리 계곡"])
        #expect(response.valleys.first?.isSubscribed == true)
        let request = try #require(server.requests.first)
        #expect(request.line == "GET /api/valleys")
        #expect(request.query == nil)
        #expect(request.deviceID == "d_saved")
    }

    @Test func searchSendsTrimmedQuery() async throws {
        let server = FakeServer { _ in (200, Self.list) }
        let repository = server.repository(savedID: "d_saved")

        _ = try await repository.valleys(matching: "  금대  ")
        _ = try await repository.valleys(matching: "   ")

        #expect(server.requests.map(\.query) == ["q=금대", nil])
    }

    @Test func eachMethodUsesItsEndpoint() async throws {
        let server = FakeServer { request in
            if request.line.hasPrefix("GET /api/valleys/") {
                return (404, #"{"error": {"code": "VALLEY_NOT_FOUND", "message": "계곡 정보를 찾을 수 없어요"}}"#)
            }
            return (200, request.line.contains("subscriptions") ? Self.subscribed : Self.list)
        }
        let repository = server.repository(savedID: "d_saved")

        _ = try await repository.subscribedValleys()
        try await repository.subscribe(valleyID: 3)
        try await repository.unsubscribe(valleyID: 3)
        await #expect(throws: APIError.valleyNotFound) { try await repository.valleyDetail(id: 3) }

        #expect(server.requests.map(\.line) == [
            "GET /api/me/valleys",
            "PUT /api/me/subscriptions/3",
            "DELETE /api/me/subscriptions/3",
            "GET /api/valleys/3",
        ])
        #expect(server.requests.allSatisfy { $0.deviceID == "d_saved" })
    }

    @Test func firstRequestRegistersTheDevice() async throws {
        let server = FakeServer { _ in (200, Self.list) }
        let repository = server.repository(savedID: nil)

        _ = try await repository.valleys(matching: nil)

        #expect(server.requests.map(\.line) == ["POST /api/devices", "GET /api/valleys"])
        #expect(server.requests.last?.deviceID == "d_1")
    }

    @Test func unknownDeviceRegistersAgainAndRetriesOnce() async throws {
        let server = FakeServer { request in
            request.deviceID == "d_gone" ? (404, Self.notFound) : (200, Self.subscribed)
        }
        let store = InMemoryDeviceIDStore(saved: "d_gone")
        let repository = server.repository(store: store)

        try await repository.subscribe(valleyID: 1)

        #expect(server.requests.map(\.line) == [
            "PUT /api/me/subscriptions/1", "POST /api/devices", "PUT /api/me/subscriptions/1",
        ])
        #expect(server.requests.last?.deviceID == "d_1")
        #expect(store.current == "d_1")
    }

    @Test func unknownDeviceTwiceIsThrown() async throws {
        let server = FakeServer { _ in (404, Self.notFound) }
        let repository = server.repository(savedID: "d_gone")

        await #expect(throws: APIError.self) { try await repository.subscribe(valleyID: 1) }

        // One retry only: no endless register-and-retry loop.
        #expect(server.requests.map(\.line) == [
            "PUT /api/me/subscriptions/1", "POST /api/devices", "PUT /api/me/subscriptions/1",
        ])
    }

    @Test func otherErrorsAreNotRetried() async {
        let server = FakeServer { _ in (502, "<html>Bad Gateway</html>") }
        let repository = server.repository(savedID: "d_saved")

        await #expect(throws: HTTPStatusError(statusCode: 502)) { try await repository.subscribe(valleyID: 1) }
        #expect(server.requests.count == 1)
    }

    @Test func failedRegistrationStillLoadsValleysWithoutID() async throws {
        let server = FakeServer(failRegistration: true) { _ in (200, Self.list) }
        let repository = server.repository(savedID: nil)

        let response = try await repository.valleys(matching: "금대")

        #expect(response.valleys.map(\.name) == ["금대리 계곡"])
        #expect(server.requests.map(\.line) == ["POST /api/devices", "GET /api/valleys"])
        #expect(server.requests.last?.deviceID == nil)
    }

    @Test func failedRegistrationStillLoadsDetailWithoutID() async throws {
        let server = FakeServer(failRegistration: true) { _ in (404, #"{"error": {"code": "VALLEY_NOT_FOUND", "message": "계곡 정보를 찾을 수 없어요"}}"#) }
        let repository = server.repository(savedID: nil)

        // The detail request is sent (no ID) and its own answer reaches the screen.
        await #expect(throws: APIError.valleyNotFound) { try await repository.valleyDetail(id: 1) }
        #expect(server.requests.map(\.line) == ["POST /api/devices", "GET /api/valleys/1"])
        #expect(server.requests.last?.deviceID == nil)
    }

    @Test func failedRegistrationFailsSubscriptionRequests() async {
        let server = FakeServer(failRegistration: true) { _ in (200, Self.subscribed) }
        let repository = server.repository(savedID: nil)

        await #expect(throws: (any Error).self) { try await repository.subscribe(valleyID: 1) }
        await #expect(throws: (any Error).self) { _ = try await repository.subscribedValleys() }
        // Each request tried to register again; none was sent without an ID.
        #expect(server.requests.map(\.line) == ["POST /api/devices", "POST /api/devices"])
    }

    @Test func registrationIsTriedAgainOnTheNextRequest() async throws {
        let server = FakeServer(failRegistration: true) { _ in (200, Self.list) }
        let repository = server.repository(savedID: nil)
        _ = try await repository.valleys(matching: nil)

        server.failRegistration = false
        _ = try await repository.valleys(matching: nil)

        #expect(server.requests.map(\.line) == [
            "POST /api/devices", "GET /api/valleys", "POST /api/devices", "GET /api/valleys",
        ])
        #expect(server.requests.last?.deviceID == "d_1")
    }
}

extension ServerValleyRepositoryTests {
    private static let answer = #"""
    {"updated_at": "2026-11-19T10:02", "valley_id": 1, "question": "여기 들어가도 돼요?",
     "answer": "지금 금대리 계곡은 '안전' 단계예요.", "ai_fallback": false, "level": "safe",
     "observed_at": "2026-11-19T09:50", "disclaimer": "판단 보조 정보이며 공식 재난경보를 대체하지 않습니다.",
     "source": "자료: 한강홍수통제소, 기상청"}
    """#

    /// #64: only the question goes to the server, with the device header.
    @Test func askPostsOnlyTheQuestionAndDecodes() async throws {
        let server = FakeServer { _ in (200, Self.answer) }
        let repository = server.repository(savedID: "d_saved")

        let answer = try await repository.ask(valleyID: 1, question: "여기 들어가도 돼요?")

        #expect(answer.answer == "지금 금대리 계곡은 '안전' 단계예요.")
        #expect(answer.isAIFallback == false)
        #expect(answer.level == .safe)
        #expect(answer.observedAt == ServerDate.parse("2026-11-19T09:50"))
        let request = try #require(server.requests.first)
        #expect(request.line == "POST /api/valleys/1/ask")
        #expect(request.deviceID == "d_saved")
        let body = try JSONSerialization.jsonObject(with: Data((request.body ?? "").utf8)) as? [String: String]
        #expect(body == ["question": "여기 들어가도 돼요?"])
    }

    @Test func askPassesServerErrorsThrough() async throws {
        let server = FakeServer { _ in
            (429, #"{"error": {"code": "TOO_MANY_QUESTIONS", "message": "질문이 많아요. 잠시 후 다시 물어봐 주세요"}}"#)
        }
        let repository = server.repository(savedID: "d_saved")

        await #expect(throws: APIError.tooManyQuestions) {
            try await repository.ask(valleyID: 1, question: "지금 비 많이 와요?")
        }
    }
}

/// Records requests and answers `/devices` with `d_1`, `d_2`, ... (or 500 while
/// `failRegistration`); other paths go to `answer`.
private final class FakeServer: @unchecked Sendable {
    struct Request {
        /// e.g. `"GET /api/valleys"`
        let line: String
        let query: String?
        let deviceID: String?
        /// The JSON body, when the request has one (#64).
        var body: String? = nil
    }

    private let lock = NSLock()
    private var recorded: [Request] = []
    private var issued = 0
    private let answer: @Sendable (Request) -> (Int, String)
    private var client: APIClient!
    private var registrationFails: Bool
    /// When true, `POST /devices` answers 500.
    var failRegistration: Bool {
        get { lock.withLock { registrationFails } }
        set { lock.withLock { registrationFails = newValue } }
    }

    init(failRegistration: Bool = false, answer: @escaping @Sendable (Request) -> (Int, String)) {
        self.answer = answer
        self.registrationFails = failRegistration
        client = StubURLProtocol.makeClient { [unowned self] request, body in
            let recordedRequest = Request(
                line: "\(request.httpMethod ?? "") \(request.url?.path() ?? "")",
                query: request.url?.query(percentEncoded: false),
                deviceID: request.value(forHTTPHeaderField: "X-Device-Id"),
                body: body.map { String(decoding: $0, as: UTF8.self) })
            let (status, body) = lock.withLock { () -> (Int, String) in
                recorded.append(recordedRequest)
                if recordedRequest.line == "POST /api/devices" {
                    if registrationFails { return (500, "Internal Server Error") }
                    issued += 1
                    return (201, #"{"device_id": "d_\#(issued)"}"#)
                }
                return answer(recordedRequest)
            }
            return (status, body.utf8Data)
        }
    }

    var requests: [Request] { lock.withLock { recorded } }

    func repository(savedID: String?) -> ServerValleyRepository {
        repository(store: InMemoryDeviceIDStore(saved: savedID))
    }

    func repository(store: InMemoryDeviceIDStore) -> ServerValleyRepository {
        ServerValleyRepository(client: client, registrar: DeviceRegistrar(client: client, store: store))
    }
}
