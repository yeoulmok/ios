import Foundation
@testable import yeoulmok

/// A repository whose answers are given by closures, so a test can make a call
/// fail or answer late. Calls a test does not set up behave like the mock data.
struct StubRepository: ValleyRepository {
    /// `valleys(matching:)` and `subscribedValleys()`.
    var list: @Sendable (String?) async throws -> ValleyListResponse
    /// `subscribe` (true) and `unsubscribe` (false).
    var changeSubscription: @Sendable (Int, Bool) async throws -> Void
    /// `valleyDetail(id:)`.
    var detail: @Sendable (Int) async throws -> ValleyDetail
    /// `ask(valleyID:question:)` (#64).
    var ask: @Sendable (Int, String) async throws -> AskAnswer
    /// `history(valleyID:hours:)` (#90).
    var history: @Sendable (Int, Int) async throws -> ValleyHistory
    /// `valleyPage(_:)` (#96). `nil`: answers with `list(query)`, like a server without
    /// pages (no `total`), so older search tests keep working through `list`.
    var page: (@Sendable (ValleyPageRequest) async throws -> ValleyListResponse)?
    /// `regions()` (#96).
    var regionList: @Sendable () async throws -> ValleyRegions

    init(
        list: @escaping @Sendable (String?) async throws -> ValleyListResponse = { query in
            try await MockValleyRepository().valleys(matching: query)
        },
        changeSubscription: @escaping @Sendable (Int, Bool) async throws -> Void = { _, _ in },
        detail: @escaping @Sendable (Int) async throws -> ValleyDetail = { id in
            try await MockValleyRepository().valleyDetail(id: id)
        },
        ask: @escaping @Sendable (Int, String) async throws -> AskAnswer = { id, question in
            try await MockValleyRepository().ask(valleyID: id, question: question)
        },
        history: @escaping @Sendable (Int, Int) async throws -> ValleyHistory = { id, hours in
            try await MockValleyRepository().history(valleyID: id, hours: hours)
        },
        page: (@Sendable (ValleyPageRequest) async throws -> ValleyListResponse)? = nil,
        regionList: @escaping @Sendable () async throws -> ValleyRegions = {
            try await MockValleyRepository().regions()
        }
    ) {
        self.page = page
        self.regionList = regionList
        self.history = history
        self.ask = ask
        self.list = list
        self.changeSubscription = changeSubscription
        self.detail = detail
    }

    func valleys(matching query: String?) async throws -> ValleyListResponse { try await list(query) }
    func valleyPage(_ request: ValleyPageRequest) async throws -> ValleyListResponse {
        if let page { return try await page(request) }
        return try await list(request.query)
    }
    func regions() async throws -> ValleyRegions { try await regionList() }
    func subscribedValleys() async throws -> ValleyListResponse { try await list(nil) }
    func valleyDetail(id: Int) async throws -> ValleyDetail { try await detail(id) }
    func subscribe(valleyID: Int) async throws { try await changeSubscription(valleyID, true) }
    func unsubscribe(valleyID: Int) async throws { try await changeSubscription(valleyID, false) }
    func ask(valleyID: Int, question: String) async throws -> AskAnswer { try await ask(valleyID, question) }
    func history(valleyID: Int, hours: Int) async throws -> ValleyHistory { try await history(valleyID, hours) }
}
