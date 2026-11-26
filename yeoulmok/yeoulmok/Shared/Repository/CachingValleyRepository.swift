import Foundation

/// Wraps another repository and keeps its answers in memory for a short time (#103),
/// so a screen that appears again (back from a detail, another tab) does not wait for
/// the server to send the same data again. Screens and view models do not know it is
/// there: they still see a `ValleyRepository` (decorator).
///
/// - An answer is used again for `freshFor` (60 s, decided in #103). Observations come
///   every 10 minutes; pushes and pull to refresh call `invalidateCache()` and always
///   get fresh data.
/// - Requests for the same data at the same time share one server request.
/// - Failures are never kept: the next request asks the server again, and screens
///   keep falling back to `ValleyCache` (the saved copy on the device) as before.
/// - Subscribing or unsubscribing forgets everything, since every list and detail
///   says whether the valley is subscribed.
/// - Cached: subscribed list, the whole list (no search text), detail, history, and
///   the regions (kept for the whole run: they change when valleys are added).
///   Not cached: search text, search pages, subscriptions, questions.
actor CachingValleyRepository: ValleyRepository {
    /// How long an answer is used again.
    static let freshFor: Duration = .seconds(60)

    private let inner: any ValleyRepository
    private let freshFor: Duration
    /// Tests move the time forward without waiting.
    private let now: @Sendable () -> ContinuousClock.Instant

    private enum Key: Hashable {
        case allValleys, subscribed, detail(Int), history(Int, hours: Int), regions
    }

    private enum Answer: Sendable {
        case list(ValleyListResponse), detail(ValleyDetail), history(ValleyHistory), regions(ValleyRegions)
    }

    private struct Entry {
        let answer: Answer
        let savedAt: ContinuousClock.Instant
    }

    private var entries: [Key: Entry] = [:]
    private var running: [Key: Task<Answer, any Error>] = [:]
    /// Goes up on every `invalidateCache()`, so an answer to a request sent before it
    /// (e.g. before a subscription changed) is not saved.
    private var generation = 0

    init(wrapping inner: any ValleyRepository, freshFor: Duration = CachingValleyRepository.freshFor,
         now: @escaping @Sendable () -> ContinuousClock.Instant = { .now }) {
        self.inner = inner
        self.freshFor = freshFor
        self.now = now
    }

    // MARK: Cached

    func valleys(matching query: String?) async throws -> ValleyListResponse {
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard trimmed.isEmpty else { return try await inner.valleys(matching: query) }
        let inner = inner
        guard case let .list(answer) = try await answer(for: .allValleys, fetch: {
            .list(try await inner.valleys(matching: nil))
        }) else { preconditionFailure("allValleys holds a list") }
        return answer
    }

    func subscribedValleys() async throws -> ValleyListResponse {
        let inner = inner
        guard case let .list(answer) = try await answer(for: .subscribed, fetch: {
            .list(try await inner.subscribedValleys())
        }) else { preconditionFailure("subscribed holds a list") }
        return answer
    }

    func valleyDetail(id: Int) async throws -> ValleyDetail {
        let inner = inner
        guard case let .detail(answer) = try await answer(for: .detail(id), fetch: {
            .detail(try await inner.valleyDetail(id: id))
        }) else { preconditionFailure("detail holds a detail") }
        return answer
    }

    func history(valleyID: Int, hours: Int) async throws -> ValleyHistory {
        let inner = inner
        guard case let .history(answer) = try await answer(for: .history(valleyID, hours: hours), fetch: {
            .history(try await inner.history(valleyID: valleyID, hours: hours))
        }) else { preconditionFailure("history holds a history") }
        return answer
    }

    func regions() async throws -> ValleyRegions {
        let inner = inner
        guard case let .regions(answer) = try await answer(for: .regions, expires: false, fetch: {
            .regions(try await inner.regions())
        }) else { preconditionFailure("regions holds regions") }
        return answer
    }

    // MARK: Passed through

    func valleyPage(_ request: ValleyPageRequest) async throws -> ValleyListResponse {
        try await inner.valleyPage(request)
    }

    func ask(valleyID: Int, question: String) async throws -> AskAnswer {
        try await inner.ask(valleyID: valleyID, question: question)
    }

    /// Forgets everything afterwards, also when it fails (the server may have changed it).
    func subscribe(valleyID: Int) async throws {
        defer { forget() }
        try await inner.subscribe(valleyID: valleyID)
    }

    func unsubscribe(valleyID: Int) async throws {
        defer { forget() }
        try await inner.unsubscribe(valleyID: valleyID)
    }

    /// Pull to refresh and pushes. The regions stay: they are not about the water.
    func invalidateCache() async {
        forget()
        await inner.invalidateCache()
    }

    // MARK: -

    private func forget() {
        let regions = entries[.regions]
        entries = [:]
        entries[.regions] = regions
        running = [:]
        generation += 1
    }

    /// The saved answer while it is fresh, else the running request, else a new one.
    private func answer(for key: Key, expires: Bool = true,
                        fetch: @escaping @Sendable () async throws -> Answer) async throws -> Answer {
        if let entry = entries[key], !expires || now() - entry.savedAt < freshFor {
            return entry.answer
        }
        if let task = running[key] {
            return try await task.value
        }

        let task = Task { try await fetch() }
        running[key] = task
        let sentIn = generation
        defer {
            if running[key] == task { running[key] = nil }
        }

        let answer = try await task.value
        if sentIn == generation {
            entries[key] = Entry(answer: answer, savedAt: now())
        }
        return answer
    }
}
