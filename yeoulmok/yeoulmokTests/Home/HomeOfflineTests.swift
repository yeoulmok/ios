import Foundation
import Testing
@testable import yeoulmok

/// APP-COM-07 (#16): when the server cannot be reached, home keeps or restores the
/// last received list and says how old it is.
@MainActor
struct HomeOfflineTests {
    private let cache = ValleyCache(directory: FileManager.default.temporaryDirectory
        .appending(path: "HomeOfflineTests-\(UUID().uuidString)", directoryHint: .isDirectory))

    @Test func successSavesTheListAndShowsNoBanner() async throws {
        let viewModel = HomeViewModel(repository: FakeHomeServer().repository, cache: cache)

        await viewModel.load()

        #expect(viewModel.offlineAsOf == nil)
        let saved = try #require(await cache.subscribedValleys())
        #expect(saved.valleys.map(\.id) == [1, 2, 4])
    }

    @Test func failedRefreshKeepsTheListAndShowsItsTime() async throws {
        let server = FakeHomeServer()
        let viewModel = HomeViewModel(repository: server.repository, cache: cache)
        await viewModel.load()
        let shown = viewModel.state

        server.isDown = true
        await viewModel.load()

        #expect(viewModel.state == shown)
        #expect(viewModel.offlineAsOf == ServerDate.parse("2026-11-07T22:00"))
    }

    @Test func failureAtLaunchShowsTheSavedListWithItsTime() async throws {
        await cache.saveSubscribedValleys(try await MockValleyRepository().subscribedValleys())
        let server = FakeHomeServer()
        server.isDown = true
        let viewModel = HomeViewModel(repository: server.repository, cache: cache)

        await viewModel.load()

        guard case let .loaded(valleys, _) = viewModel.state else {
            Issue.record("expected the saved list, got \(viewModel.state)")
            return
        }
        #expect(valleys.map(\.id) == [4, 1, 2], "saved list in home order")
        #expect(viewModel.offlineAsOf == ServerDate.parse("2026-11-07T22:00"))
    }

    @Test func failureWithNothingSavedIsTheErrorScreen() async {
        let server = FakeHomeServer()
        server.isDown = true
        let viewModel = HomeViewModel(repository: server.repository, cache: cache)

        await viewModel.load()

        #expect(viewModel.state == .failed(message: "연결할 수 없어요"))
        #expect(viewModel.offlineAsOf == nil)
    }

    @Test func successAfterBeingOfflineRemovesTheBanner() async throws {
        let server = FakeHomeServer()
        let viewModel = HomeViewModel(repository: server.repository, cache: cache)
        await viewModel.load()
        server.isDown = true
        await viewModel.load()
        #expect(viewModel.offlineAsOf != nil)

        server.isDown = false
        await viewModel.load()

        #expect(viewModel.offlineAsOf == nil)
    }

    @Test func bannerTextHasDateAndKoreanTime() throws {
        let date = try #require(ServerDate.parse("2026-11-06T23:00"))
        #expect(OfflineBanner.text(asOf: date) == "연결할 수 없어 11월 6일 23:00 기준 정보를 보여드려요")
    }
}

/// The mock subscribed list (updated_at 2026-11-07T22:00), or a lost connection while `isDown`.
private final class FakeHomeServer: @unchecked Sendable {
    private let lock = NSLock()
    private var down = false
    var isDown: Bool {
        get { lock.withLock { down } }
        set { lock.withLock { down = newValue } }
    }

    var repository: StubRepository {
        StubRepository(list: { [self] _ in
            if isDown { throw URLError(.notConnectedToInternet) }
            return try await MockValleyRepository().subscribedValleys()
        })
    }
}
