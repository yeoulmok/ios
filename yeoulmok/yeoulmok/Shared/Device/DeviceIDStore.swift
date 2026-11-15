import Foundation
import Security

/// Keeps the `device_id` the server issued (`POST /devices`).
/// A protocol, so `DeviceRegistrar` can be tested with an in-memory store.
nonisolated protocol DeviceIDStore: Sendable {
    /// The saved ID, or `nil` when this device has not registered yet.
    func load() throws -> String?
    func save(_ deviceID: String) throws
    /// Removes the saved ID. Nothing saved is not an error.
    func delete() throws
}

/// `DeviceIDStore` in the Keychain.
///
/// - Readable after the first unlock since boot, so a background push launch can read it.
/// - `ThisDeviceOnly`: not copied to a new phone through a backup. The ID belongs to
///   this phone's push token, so a new phone must register on its own.
nonisolated struct KeychainDeviceIDStore: DeviceIDStore {
    /// Tests pass their own `service`, so they never touch the app's real item.
    let service: String
    private let account = "device_id"

    init(service: String = "com.yeoulmok.app.device") {
        self.service = service
    }

    func load() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError(status: status)
        }
    }

    func save(_ deviceID: String) throws {
        let data = Data(deviceID.utf8)
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var item = baseQuery
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError(status: addStatus) }
        default:
            throw KeychainError(status: status)
        }
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

/// A Keychain call failed. `status` is an `OSStatus` such as `errSecInteractionNotAllowed`.
nonisolated struct KeychainError: Error, Equatable {
    let status: OSStatus
}
