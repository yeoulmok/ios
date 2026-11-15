import Foundation

/// Gives every server request this phone's `device_id` (no login: the ID is the user).
///
/// - The first time, it registers with `POST /devices` and saves the ID in `store`.
///   After that it uses the saved ID and never registers again.
/// - Requests that ask at the same time share one registration.
/// - A failed registration saves nothing. The next request tries again.
/// - A new APNs token is sent with `PATCH /devices`, or with the registration.
/// - When the server no longer knows the ID (`DEVICE_NOT_FOUND`), callers pass it to
///   `invalidate(_:)` and the next request registers again.
actor DeviceRegistrar {
    private let client: APIClient
    private let store: any DeviceIDStore

    /// The ID for this run, so the Keychain is read once.
    private var currentID: String?
    /// The registration that is running now, if any.
    private var registration: Task<String, any Error>?
    /// The newest APNs token from iOS.
    private var pushToken: String?
    /// The token the server has for `currentID` (sent this run).
    private var sentPushToken: String?

    init(client: APIClient, store: any DeviceIDStore) {
        self.client = client
        self.store = store
    }

    /// The saved ID, or a new one from the server.
    /// Throws when the Keychain cannot be read (registering again would lose the
    /// user's subscriptions) or when registration fails.
    func deviceID() async throws -> String {
        if let currentID { return currentID }
        if let saved = try store.load() {
            currentID = saved
            return saved
        }
        if let registration {
            return try await registration.value
        }

        let token = pushToken
        let task = Task { [client] in
            let response: DeviceResponse = try await client.send(
                .post, "devices", body: RegisterRequest(apnsToken: token))
            return response.deviceID
        }
        registration = task
        defer { registration = nil }

        let id = try await task.value
        // If saving fails the ID still works for this run; the next launch registers again.
        try? store.save(id)
        currentID = id
        sentPushToken = token
        return id
    }

    /// Call with every token iOS gives (`didRegisterForRemoteNotificationsWithDeviceToken`).
    /// Sends it only when the server does not have it yet.
    func updatePushToken(_ token: String) async throws {
        pushToken = token
        let id = try await deviceID()   // a new registration already carries the token
        guard token != sentPushToken else { return }

        do {
            let _: DeviceResponse = try await client.send(
                .patch, "devices", body: UpdateRequest(apnsToken: token),
                headers: [Self.deviceIDHeader: id])
            sentPushToken = token
        } catch let error as APIError where error.isDeviceNotFound {
            invalidate(id)
            _ = try await deviceID()    // registers again with the token
        }
    }

    /// The server answered `DEVICE_NOT_FOUND` for `deviceID`: forget it, so the next
    /// `deviceID()` registers again. Ignored when the ID was already replaced, so a
    /// late failure never throws away a newer ID.
    func invalidate(_ deviceID: String) {
        guard deviceID == currentID || currentID == nil else { return }
        if (try? store.load()) == deviceID {
            try? store.delete()
        }
        currentID = nil
        sentPushToken = nil
    }

    nonisolated static let deviceIDHeader = "X-Device-Id"

    private struct RegisterRequest: Encodable, Sendable {
        let apnsToken: String?
        let platform = "ios"
        enum CodingKeys: String, CodingKey {
            case apnsToken = "apns_token", platform
        }
    }

    private struct UpdateRequest: Encodable, Sendable {
        let apnsToken: String
        enum CodingKeys: String, CodingKey { case apnsToken = "apns_token" }
    }

    /// `POST` and `PATCH /devices` both answer with at least `device_id`.
    private struct DeviceResponse: Decodable, Sendable {
        let deviceID: String
        enum CodingKeys: String, CodingKey { case deviceID = "device_id" }
    }
}

nonisolated extension APIError {
    /// The server does not know the `X-Device-Id` sent (e.g. its data was reset).
    var isDeviceNotFound: Bool { code == "DEVICE_NOT_FOUND" }
}
