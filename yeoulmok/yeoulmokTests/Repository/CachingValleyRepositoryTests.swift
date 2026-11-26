import Foundation
import Testing
@testable import yeoulmok

/// #103: answers are used again for 60 s, the same request at the same time is sent
/// once, and subscribing, pull to refresh and pushes always get fresh data.
struct CachingValleyRepositoryTests {
    @Test func sameAnswerWithinFreshTime() async throws {
        let server = CountingRepository()
        let clock = TestClock()
        let repository = CachingValleyRepository(wrapping: server, now: clock.now)

        _ = try await repository.subscribedValleys()
        clock.advance(by: .seconds(59))
        _ = try await repository.subscribedValleys()

        #expect(await server.count(.subscribed) == 1)
    }

    @Test func asksAgainAfterFreshTime() async throws {
        let server = CountingRepository()
        let clock = TestClock()
        let repository = CachingValleyRepository(wrapping: server, now: clock.now)

        _ = try await repository.valleyDetail(id: 1)
        clock.advance(by: .seconds(60))
        _ = try await repository.valleyDetail(id: 1)

        #expect(await server.count(.detail(1)) == 2)
    }

    @Test func eachKindIsKeptApart() async throws {
        let server = CountingRepository()
        let repository = CachingValleyRepository(wrapping: server)

        _ = try await repository.valleyDetail(id: 1)
        _ = try await repository.valleyDetail(id: 2)
        _ = try await repository.history(valleyID: 1, hours: 3)
        _ = try await repository.history(valleyID: 1, hours: 6)
        _ = try await repository.valleys(matching: nil)
        _ = try await repository.valleys(matching: "  ")
        let detail = try await repository.valleyDetail(id: 2)

        #expect(detail.id == 2)
        #expect(await server.count(.detail(1)) == 1)
        #expect(await server.count(.detail(2)) == 1)
        #expect(await server.count(.history(1, 3)) == 1)
        #expect(await server.count(.history(1, 6)) == 1)
        // Blank text is the whole list, like the server.
        #expect(await server.count(.allValleys) == 1)
    }

    @Test func searchTextAndPagesAlwaysGoToTheServer() async throws {
        let server = CountingRepository()
        let repository = CachingValleyRepository(wrapping: server)
        let page = ValleyPageRequest(query: nil, filter: .all, offset: 0, limit: 20)

        _ = try await repository.valleys(matching: "금대")
        _ = try await repository.valleys(matching: "금대")
        _ = try await repository.valleyPage(page)
        _ = try await repository.valleyPage(page)

        #expect(await server.count(.search("금대")) == 2)
        #expect(await server.count(.page) == 2)
    }

    @Test func sameRequestAtTheSameTimeIsSentOnce() async throws {
        let server = CountingRepository(delay: .milliseconds(100))
        let repository = CachingValleyRepository(wrapping: server)

        async let first = repository.valleyDetail(id: 1)
        async let second = repository.valleyDetail(id: 1)
        let both = try await [first, second]

        #expect(both.map(\.id) == [1, 1])
        #expect(await server.count(.detail(1)) == 1)
    }

    @Test func failureIsNotKept() async throws {
        let server = CountingRepository(failures: 1)
        let repository = CachingValleyRepository(wrapping: server)

        await #expect(throws: URLError.self) { try await repository.subscribedValleys() }
        let answer = try await repository.subscribedValleys()

        #expect(!answer.valleys.isEmpty)
        #expect(await server.count(.subscribed) == 2)
    }

    @Test(arguments: [true, false])
    func changingASubscriptionForgetsEverything(subscribing: Bool) async throws {
        let server = CountingRepository()
        let repository = CachingValleyRepository(wrapping: server)
        _ = try await repository.subscribedValleys()
        _ = try await repository.valleyDetail(id: 3)
        _ = try await repository.valleys(matching: nil)

        if subscribing {
            try await repository.subscribe(valleyID: 3)
        } else {
            try await repository.unsubscribe(valleyID: 3)
        }
        _ = try await repository.subscribedValleys()
        _ = try await repository.valleyDetail(id: 3)
        _ = try await repository.valleys(matching: nil)

        #expect(await server.count(.subscribed) == 2)
        #expect(await server.count(.detail(3)) == 2)
        #expect(await server.count(.allValleys) == 2)
    }

    @Test func failedSubscriptionChangeAlsoForgets() async throws {
        let server = CountingRepository(failsSubscriptions: true)
        let repository = CachingValleyRepository(wrapping: server)
        _ = try await repository.subscribedValleys()

        await #expect(throws: URLError.self) { try await repository.subscribe(valleyID: 3) }
        _ = try await repository.subscribedValleys()

        #expect(await server.count(.subscribed) == 2)
    }

    @Test func invalidateForgetsAllButTheRegions() async throws {
        let server = CountingRepository()
        let clock = TestClock()
        let repository = CachingValleyRepository(wrapping: server, now: clock.now)
        _ = try await repository.subscribedValleys()
        _ = try await repository.history(valleyID: 1, hours: 3)
        _ = try await repository.regions()

        await repository.invalidateCache()
        // Regions are kept for the whole run, however old.
        clock.advance(by: .seconds(3600))
        _ = try await repository.subscribedValleys()
        _ = try await repository.history(valleyID: 1, hours: 3)
        _ = try await repository.regions()

        #expect(await server.count(.subscribed) == 2)
        #expect(await server.count(.history(1, 3)) == 2)
        #expect(await server.count(.regions) == 1)
    }

    @Test func answerSentBeforeInvalidateIsNotKept() async throws {
        let server = CountingRepository(delay: .milliseconds(200))
        let repository = CachingValleyRepository(wrapping: server)

        // E.g. home was loading when the user subscribed somewhere else.
        let early = Task { try await repository.subscribedValleys() }
        try await Task.sleep(for: .milliseconds(50))
        await repository.invalidateCache()
        _ = try await early.value
        _ = try await repository.subscribedValleys()

        #expect(await server.count(.subscribed) == 2)
    }

    /// Pull to refresh on home, detail and nearby always reaches the server.
    @MainActor
    @Test func pullToRefreshAsksTheServerAgain() async throws {
        let server = CountingRepository()
        let repository = CachingValleyRepository(wrapping: server)
        let home = HomeViewModel(repository: repository)
        let detail = ValleyDetailViewModel(valleyID: 1, repository: repository)
        let nearby = NearbyViewModel(permission: FakeLocationPermission(.allowed), repository: repository)

        await home.load()
        await detail.load()
        await nearby.load()
        await home.refresh()
        await detail.refresh()
        await nearby.refresh()

        #expect(await server.count(.subscribed) == 2)
        #expect(await server.count(.history(1, 3)) == 2)
        #expect(await server.count(.allValleys) == 2)
    }

    // MARK: Featured detail guess (#103, item 3)

    /// Mock subscriptions: 1 금대리 (주의), 2 갑천 (판정 불가), 4 위험 예시 (위험) → 4 is featured.
    private func savedList(_ ids: [Int]) async throws -> ValleyCache {
        let cache = ValleyCache(directory: FileManager.default.temporaryDirectory
            .appending(path: "GuessTests-\(UUID().uuidString)", directoryHint: .isDirectory))
        let all = try await MockValleyRepository().subscribedValleys()
        await cache.saveSubscribedValleys(ValleyListResponse(
            updatedAt: all.updatedAt, source: all.source, valleys: all.valleys.filter { ids.contains($0.id) }))
        return cache
    }

    @MainActor
    @Test func justAfterLaunchTheFeaturedDetailTravelsWithTheList() async throws {
        let server = CountingRepository(delay: .milliseconds(150))
        let home = HomeViewModel(repository: CachingValleyRepository(wrapping: server),
                                 cache: try await savedList([1, 2, 4]))

        await home.load()

        let events = await server.events
        let detailStart = try #require(events.firstIndex(of: "start detail(4)"))
        let listEnd = try #require(events.firstIndex(of: "end subscribed"))
        #expect(detailStart < listEnd)
        #expect(await server.count(.detail(4)) == 1)
        #expect(home.featuredDetail?.id == 4)
    }

    @MainActor
    @Test func aWrongGuessStillShowsTheRightValley() async throws {
        let server = CountingRepository()
        // The saved list only had 1, so 1 is guessed; the server's list makes 4 featured.
        let home = HomeViewModel(repository: CachingValleyRepository(wrapping: server),
                                 cache: try await savedList([1]))

        await home.load()

        #expect(home.featured?.valley.id == 4)
        #expect(home.featuredDetail?.id == 4)
        #expect(await server.count(.detail(4)) == 1)
        #expect(await server.count(.detail(1)) <= 1)
    }

    @MainActor
    @Test func nothingSavedNothingGuessed() async throws {
        let server = CountingRepository()
        let home = HomeViewModel(repository: CachingValleyRepository(wrapping: server))

        await home.load()

        let events = await server.events
        #expect(events.prefix(2) == ["start subscribed", "end subscribed"])
        #expect(await server.total == 2)
    }

    /// Without a cache the hint does nothing: mocks (and their failure switches) see
    /// the same requests as before.
    @MainActor
    @Test func repositoryWithoutACacheIgnoresTheGuess() async throws {
        let server = CountingRepository()
        let home = HomeViewModel(repository: server, cache: try await savedList([1, 2, 4]))

        await home.load()
        try await Task.sleep(for: .milliseconds(50))

        #expect(await server.count(.detail(4)) == 1)
        #expect(await server.total == 2)
    }

    /// The number written in the PR: app start → home → featured detail → back →
    /// nearby tab → home tab, all within a minute.
    @MainActor
    @Test(arguments: [false, true])
    func requestsForATypicalVisit(cached: Bool) async throws {
        let server = CountingRepository()
        let repository: any ValleyRepository = cached ? CachingValleyRepository(wrapping: server) : server

        let home = HomeViewModel(repository: repository)
        await home.load()
        let featured = try #require(home.featured?.valley.id)
        await ValleyDetailViewModel(valleyID: featured, repository: repository).load()
        await home.load()
        await NearbyViewModel(permission: FakeLocationPermission(.allowed), repository: repository).load()
        await home.load()

        // Without the cache: 3 × (subscribed + featured detail) + history + whole list.
        #expect(await server.total == (cached ? 4 : 9))
    }
}

/// The mock data, counting every request it gets.
private actor CountingRepository: ValleyRepository {
    enum Call: Hashable {
        case allValleys, search(String), page, regions, subscribed, detail(Int), history(Int, Int), ask, change
    }

    private let mock: MockValleyRepository
    private let delay: Duration?
    private var failures: Int
    private let failsSubscriptions: Bool
    private var calls: [Call: Int] = [:]
    /// "start …" and "end …" in the order they happened.
    private(set) var events: [String] = []

    init(delay: Duration? = nil, failures: Int = 0, failsSubscriptions: Bool = false) {
        mock = try! MockValleyRepository()
        self.delay = delay
        self.failures = failures
        self.failsSubscriptions = failsSubscriptions
    }

    func count(_ call: Call) -> Int { calls[call, default: 0] }

    /// Every request but subscription changes.
    var total: Int { calls.filter { $0.key != .change }.values.reduce(0, +) }

    private func record(_ call: Call) async throws {
        calls[call, default: 0] += 1
        events.append("start \(call)")
        defer { events.append("end \(call)") }
        if let delay { try await Task.sleep(for: delay) }
        if failures > 0 {
            failures -= 1
            throw URLError(.notConnectedToInternet)
        }
    }

    func valleys(matching query: String?) async throws -> ValleyListResponse {
        let text = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        try await record(text.isEmpty ? .allValleys : .search(text))
        return try await mock.valleys(matching: query)
    }

    func valleyPage(_ request: ValleyPageRequest) async throws -> ValleyListResponse {
        try await record(.page)
        return try await mock.valleyPage(request)
    }

    func regions() async throws -> ValleyRegions {
        try await record(.regions)
        return try await mock.regions()
    }

    func subscribedValleys() async throws -> ValleyListResponse {
        try await record(.subscribed)
        return try await mock.subscribedValleys()
    }

    func valleyDetail(id: Int) async throws -> ValleyDetail {
        try await record(.detail(id))
        return try await mock.valleyDetail(id: id)
    }

    func subscribe(valleyID: Int) async throws {
        try await record(.change)
        if failsSubscriptions { throw URLError(.notConnectedToInternet) }
    }

    func unsubscribe(valleyID: Int) async throws {
        try await record(.change)
        if failsSubscriptions { throw URLError(.notConnectedToInternet) }
    }

    func ask(valleyID: Int, question: String) async throws -> AskAnswer {
        try await record(.ask)
        return try await mock.ask(valleyID: valleyID, question: question)
    }

    func history(valleyID: Int, hours: Int) async throws -> ValleyHistory {
        try await record(.history(valleyID, hours))
        return try await mock.history(valleyID: valleyID, hours: hours)
    }
}

/// A clock the test moves by hand.
private nonisolated final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var instant = ContinuousClock.now

    var now: @Sendable () -> ContinuousClock.Instant {
        { [self] in lock.withLock { instant } }
    }

    func advance(by duration: Duration) {
        lock.withLock { instant += duration }
    }
}
