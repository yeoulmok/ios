import Foundation
import Testing
@testable import yeoulmok

/// Uses the simulator's real Keychain. Each test has its own `service`,
/// so parallel tests and the app's real item never mix.
struct KeychainDeviceIDStoreTests {
    private let store = KeychainDeviceIDStore(service: "test.\(UUID().uuidString)")

    @Test func nothingSavedLoadsNil() throws {
        #expect(try store.load() == nil)
    }

    @Test func savedIDLoadsBack() throws {
        defer { try? store.delete() }
        try store.save("d_abc123")

        #expect(try store.load() == "d_abc123")
    }

    @Test func savingAgainReplacesTheOldID() throws {
        defer { try? store.delete() }
        try store.save("d_old")
        try store.save("d_new")

        #expect(try store.load() == "d_new")
    }

    @Test func deleteRemovesTheID() throws {
        try store.save("d_abc123")
        try store.delete()

        #expect(try store.load() == nil)
    }

    @Test func deletingWhenNothingSavedIsFine() throws {
        try store.delete()
    }

    @Test func storesDoNotShareIDs() throws {
        let other = KeychainDeviceIDStore(service: "test.\(UUID().uuidString)")
        defer { try? store.delete() }
        try store.save("d_abc123")

        #expect(try other.load() == nil)
    }
}
