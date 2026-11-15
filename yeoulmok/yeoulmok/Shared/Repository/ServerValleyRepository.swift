import Foundation

/// `ValleyRepository` backed by the real server.
///
/// Every request carries `X-Device-Id`. When the server answers `DEVICE_NOT_FOUND`
/// (its data was reset), the ID is replaced by a new registration and the request
/// is sent once more. A second failure is thrown to the screen.
nonisolated struct ServerValleyRepository: ValleyRepository {
    private let client: APIClient
    private let registrar: DeviceRegistrar

    init(client: APIClient, registrar: DeviceRegistrar) {
        self.client = client
        self.registrar = registrar
    }

    func valleys(matching query: String?) async throws -> ValleyListResponse {
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let items = trimmed.isEmpty ? [] : [URLQueryItem(name: "q", value: trimmed)]
        return try await send(.get, "valleys", query: items)
    }

    func subscribedValleys() async throws -> ValleyListResponse {
        try await send(.get, "me/valleys")
    }

    func valleyDetail(id: Int) async throws -> ValleyDetail {
        try await send(.get, "valleys/\(id)")
    }

    func subscribe(valleyID: Int) async throws {
        let _: SubscriptionResponse = try await send(.put, "me/subscriptions/\(valleyID)")
    }

    func unsubscribe(valleyID: Int) async throws {
        let _: SubscriptionResponse = try await send(.delete, "me/subscriptions/\(valleyID)")
    }

    private func send<Response: Decodable>(
        _ method: APIClient.Method, _ path: String, query: [URLQueryItem] = []
    ) async throws -> Response {
        let deviceID = try await registrar.deviceID()
        do {
            return try await client.send(method, path, query: query,
                                         headers: [DeviceRegistrar.deviceIDHeader: deviceID])
        } catch let error as APIError where error.isDeviceNotFound {
            await registrar.invalidate(deviceID)
            let newID = try await registrar.deviceID()
            return try await client.send(method, path, query: query,
                                         headers: [DeviceRegistrar.deviceIDHeader: newID])
        }
    }

    /// `{ "valley_id": 1, "subscribed": true }`. Only success matters to the app.
    private struct SubscriptionResponse: Decodable {}
}
