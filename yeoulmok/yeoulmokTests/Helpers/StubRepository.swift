import Foundation
@testable import yeoulmok

/// A repository whose answers are given by closures, so a test can make a call
/// fail or answer late. Calls a test does not set up behave like the mock data.
struct StubRepository: ValleyRepository {
    /// `valleys(matching:)` and `subscribedValleys()`.
    var list: @Sendable (String?) async throws -> ValleyListResponse
    /// `subscribe` (true) and `unsubscribe` (false).
    var changeSubscription: @Sendable (Int, Bool) async throws -> Void

    init(
        list: @escaping @Sendable (String?) async throws -> ValleyListResponse = { query in
            try await MockValleyRepository().valleys(matching: query)
        },
        changeSubscription: @escaping @Sendable (Int, Bool) async throws -> Void = { _, _ in }
    ) {
        self.list = list
        self.changeSubscription = changeSubscription
    }

    func valleys(matching query: String?) async throws -> ValleyListResponse { try await list(query) }
    func subscribedValleys() async throws -> ValleyListResponse { try await list(nil) }
    func valleyDetail(id: Int) async throws -> ValleyDetail { throw URLError(.unsupportedURL) }
    func subscribe(valleyID: Int) async throws { try await changeSubscription(valleyID, true) }
    func unsubscribe(valleyID: Int) async throws { try await changeSubscription(valleyID, false) }
}
