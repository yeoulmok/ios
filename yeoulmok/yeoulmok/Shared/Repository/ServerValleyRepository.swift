import Foundation

/// `ValleyRepository` backed by the real server.
///
/// Every request carries `X-Device-Id`. When the server answers `DEVICE_NOT_FOUND`
/// (its data was reset), the ID is replaced by a new registration and the request
/// is sent once more. A second failure is thrown to the screen.
///
/// When registration fails, requests that work without an ID (valley list, search,
/// detail) are sent without it, so a failed registration never blocks browsing
/// (issue #8, feature spec 3-1). Subscription requests need the ID and throw.
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
        return try await send(.get, "valleys", query: items, needsDevice: false)
    }

    func subscribedValleys() async throws -> ValleyListResponse {
        try await send(.get, "me/valleys")
    }

    func valleyDetail(id: Int) async throws -> ValleyDetail {
        try await send(.get, "valleys/\(id)", needsDevice: false)
    }

    func subscribe(valleyID: Int) async throws {
        let _: SubscriptionResponse = try await send(.put, "me/subscriptions/\(valleyID)")
    }

    func unsubscribe(valleyID: Int) async throws {
        let _: SubscriptionResponse = try await send(.delete, "me/subscriptions/\(valleyID)")
    }

    /// - Parameter needsDevice: `false` when the server answers without `X-Device-Id`
    ///   (then `subscribed` is always `false`).
    private func send<Response: Decodable>(
        _ method: APIClient.Method, _ path: String, query: [URLQueryItem] = [],
        needsDevice: Bool = true
    ) async throws -> Response {
        let deviceID: String
        do {
            deviceID = try await registrar.deviceID()
        } catch where !needsDevice {
            // Registration failed (it is tried again on the next request): show the
            // valleys anyway, just without this device's subscriptions.
            return try await client.send(method, path, query: query)
        }
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
