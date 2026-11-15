import Foundation
@testable import yeoulmok

/// `DeviceIDStore` in memory, for tests that should not touch the Keychain.
final class InMemoryDeviceIDStore: DeviceIDStore, @unchecked Sendable {
    private let lock = NSLock()
    private var saved: String?
    /// Makes `load()` throw, like a Keychain read before the first unlock.
    var failsToLoad = false

    init(saved: String? = nil) {
        self.saved = saved
    }

    var current: String? { lock.withLock { saved } }

    func load() throws -> String? {
        try lock.withLock {
            if failsToLoad { throw KeychainError(status: errSecInteractionNotAllowed) }
            return saved
        }
    }

    func save(_ deviceID: String) throws { lock.withLock { saved = deviceID } }
    func delete() throws { lock.withLock { saved = nil } }
}
