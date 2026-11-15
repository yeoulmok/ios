import Foundation
import Testing
@testable import yeoulmok

struct DeviceRegistrarTests {
    private static let notFound = #"{"error": {"code": "DEVICE_NOT_FOUND", "message": "기기 정보를 확인할 수 없어요"}}"#

    @Test func savedIDIsUsedWithoutRegistering() async throws {
        let server = FakeDeviceServer()
        let registrar = DeviceRegistrar(client: server.client, store: InMemoryDeviceIDStore(saved: "d_saved"))

        #expect(try await registrar.deviceID() == "d_saved")
        #expect(server.requests.isEmpty)
    }

    @Test func firstTimeRegistersAndSaves() async throws {
        let server = FakeDeviceServer()
        let store = InMemoryDeviceIDStore()
        let registrar = DeviceRegistrar(client: server.client, store: store)

        let id = try await registrar.deviceID()

        #expect(id == "d_1")
        #expect(store.current == "d_1")
        let request = try #require(server.requests.first)
        #expect(request.method == "POST")
        #expect(request.path == "/api/devices")
        #expect(request.json["platform"] as? String == "ios")
        #expect(request.json["apns_token"] == nil)   // nil is left out of the JSON
    }

    @Test func registersOnlyOnceForManyRequests() async throws {
        let server = FakeDeviceServer(delay: 0.2)
        let registrar = DeviceRegistrar(client: server.client, store: InMemoryDeviceIDStore())

        async let a = registrar.deviceID()
        async let b = registrar.deviceID()
        async let c = registrar.deviceID()
        let ids = try await [a, b, c]

        #expect(ids == ["d_1", "d_1", "d_1"])
        #expect(server.requests.count == 1)
        #expect(try await registrar.deviceID() == "d_1")
        #expect(server.requests.count == 1)
    }

    @Test func failedRegistrationSavesNothingAndTriesAgain() async throws {
        let server = FakeDeviceServer(failFirst: 1)
        let store = InMemoryDeviceIDStore()
        let registrar = DeviceRegistrar(client: server.client, store: store)

        await #expect(throws: URLError.self) { try await registrar.deviceID() }
        #expect(store.current == nil)

        #expect(try await registrar.deviceID() == "d_2")
        #expect(store.current == "d_2")
    }

    @Test func unreadableKeychainDoesNotRegisterANewID() async {
        let server = FakeDeviceServer()
        let store = InMemoryDeviceIDStore(saved: "d_saved")
        store.failsToLoad = true
        let registrar = DeviceRegistrar(client: server.client, store: store)

        await #expect(throws: KeychainError.self) { try await registrar.deviceID() }
        #expect(server.requests.isEmpty)
    }

    @Test func invalidatedIDIsReplacedByANewRegistration() async throws {
        let server = FakeDeviceServer()
        let store = InMemoryDeviceIDStore(saved: "d_old")
        let registrar = DeviceRegistrar(client: server.client, store: store)
        _ = try await registrar.deviceID()

        await registrar.invalidate("d_old")

        #expect(try await registrar.deviceID() == "d_1")
        #expect(store.current == "d_1")
    }

    @Test func invalidatingAnOlderIDKeepsTheNewOne() async throws {
        let server = FakeDeviceServer()
        let store = InMemoryDeviceIDStore(saved: "d_new")
        let registrar = DeviceRegistrar(client: server.client, store: store)
        _ = try await registrar.deviceID()

        await registrar.invalidate("d_old")

        #expect(try await registrar.deviceID() == "d_new")
        #expect(store.current == "d_new")
        #expect(server.requests.isEmpty)
    }

    @Test func pushTokenIsSentWithPATCH() async throws {
        let server = FakeDeviceServer()
        let registrar = DeviceRegistrar(client: server.client, store: InMemoryDeviceIDStore(saved: "d_saved"))

        try await registrar.updatePushToken("tok_a")

        let request = try #require(server.requests.last)
        #expect(request.method == "PATCH")
        #expect(request.path == "/api/devices")
        #expect(request.deviceID == "d_saved")
        #expect(request.json["apns_token"] as? String == "tok_a")
    }

    @Test func samePushTokenIsSentOnlyOnce() async throws {
        let server = FakeDeviceServer()
        let registrar = DeviceRegistrar(client: server.client, store: InMemoryDeviceIDStore(saved: "d_saved"))

        try await registrar.updatePushToken("tok_a")
        try await registrar.updatePushToken("tok_a")
        try await registrar.updatePushToken("tok_b")

        #expect(server.requests.map { $0.json["apns_token"] as? String } == ["tok_a", "tok_b"])
    }

    @Test func pushTokenBeforeRegistrationGoesWithTheRegistration() async throws {
        let server = FakeDeviceServer()
        let registrar = DeviceRegistrar(client: server.client, store: InMemoryDeviceIDStore())

        try await registrar.updatePushToken("tok_a")

        #expect(server.requests.count == 1)
        #expect(server.requests.first?.method == "POST")
        #expect(server.requests.first?.json["apns_token"] as? String == "tok_a")
    }

    @Test func unknownIDOnPATCHRegistersAgainWithTheToken() async throws {
        let server = FakeDeviceServer(patchAnswer: (404, Self.notFound))
        let store = InMemoryDeviceIDStore(saved: "d_gone")
        let registrar = DeviceRegistrar(client: server.client, store: store)

        try await registrar.updatePushToken("tok_a")

        #expect(server.requests.map(\.method) == ["PATCH", "POST"])
        #expect(server.requests.last?.json["apns_token"] as? String == "tok_a")
        #expect(store.current == "d_1")
    }
}

/// Answers `/devices` like the server: POST issues `d_1`, `d_2`, ...
private final class FakeDeviceServer: @unchecked Sendable {
    struct Request {
        let method: String
        let path: String
        let deviceID: String?
        let json: [String: Any]
    }

    private let lock = NSLock()
    private var recorded: [Request] = []
    private var posts = 0
    private var failuresLeft: Int
    private let delay: TimeInterval
    private let patchAnswer: (Int, String)?
    private(set) var client: APIClient!

    init(delay: TimeInterval = 0, failFirst: Int = 0, patchAnswer: (Int, String)? = nil) {
        self.delay = delay
        self.failuresLeft = failFirst
        self.patchAnswer = patchAnswer
        client = StubURLProtocol.makeClient { [unowned self] request, body in
            try self.answer(request, body: body)
        }
    }

    var requests: [Request] { lock.withLock { recorded } }

    private func answer(_ request: URLRequest, body: Data?) throws -> (status: Int, body: Data) {
        if delay > 0 { Thread.sleep(forTimeInterval: delay) }
        let json = body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        let method = request.httpMethod ?? ""
        return try lock.withLock {
            recorded.append(Request(method: method, path: request.url?.path() ?? "",
                                    deviceID: request.value(forHTTPHeaderField: "X-Device-Id"), json: json))
            if method == "POST" {
                posts += 1
                if failuresLeft > 0 {
                    failuresLeft -= 1
                    throw URLError(.notConnectedToInternet)
                }
                return (201, #"{"device_id": "d_\#(posts)"}"#.utf8Data)
            }
            if let patchAnswer { return (patchAnswer.0, patchAnswer.1.utf8Data) }
            let id = request.value(forHTTPHeaderField: "X-Device-Id") ?? ""
            return (200, #"{"device_id": "\#(id)", "notify_on": true, "has_apns_token": true}"#.utf8Data)
        }
    }
}
