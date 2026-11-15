import Foundation
import Testing
@testable import yeoulmok

/// APP-COM-07 (#16) on the alert detail and in search.
@MainActor
struct DetailOfflineTests {
    private let cache = ValleyCache(directory: FileManager.default.temporaryDirectory
        .appending(path: "DetailOfflineTests-\(UUID().uuidString)", directoryHint: .isDirectory))
    private static let mockTime = ServerDate.parse("2026-11-07T22:00")

    @Test func detailSuccessIsSavedWithoutBanner() async throws {
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: StubRepository(), cache: cache)

        await viewModel.load()

        #expect(viewModel.offlineAsOf == nil)
        #expect(await cache.detail(id: 1)?.name == "금대리 계곡")
    }

    @Test func detailFailedRefreshKeepsItAndShowsItsTime() async throws {
        let server = Outage()
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: server.repository, cache: cache)
        await viewModel.load()
        let shown = viewModel.state

        server.error = URLError(.notConnectedToInternet)
        await viewModel.load()

        #expect(viewModel.state == shown)
        #expect(viewModel.offlineAsOf == Self.mockTime)
    }

    @Test func detailFailureAtOpenShowsTheSavedCopy() async throws {
        await cache.saveDetail(try await MockValleyRepository().valleyDetail(id: 1))
        let server = Outage()
        server.error = URLError(.notConnectedToInternet)
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: server.repository, cache: cache)

        await viewModel.load()

        guard case let .loaded(detail) = viewModel.state else {
            Issue.record("expected the saved detail, got \(viewModel.state)")
            return
        }
        #expect(detail.id == 1)
        #expect(viewModel.offlineAsOf == Self.mockTime)
    }

    @Test func detailServerErrorCodeNeverUsesTheSavedCopy() async throws {
        await cache.saveDetail(try await MockValleyRepository().valleyDetail(id: 1))
        let server = Outage()
        server.error = APIError.valleyNotFound
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: server.repository, cache: cache)

        await viewModel.load()

        // The server said the valley is gone: show that, not an old copy.
        #expect(viewModel.state == .failed(message: "계곡 정보를 찾을 수 없어요"))
        #expect(viewModel.offlineAsOf == nil)
    }

    @Test func homeServerErrorCodeNeverUsesTheSavedList() async throws {
        await cache.saveSubscribedValleys(try await MockValleyRepository().subscribedValleys())
        let server = Outage()
        server.error = APIError(code: "DEVICE_NOT_FOUND", message: "기기 정보를 확인할 수 없어요")
        let viewModel = HomeViewModel(repository: server.repository, cache: cache)

        await viewModel.load()

        #expect(viewModel.state == .failed(message: "기기 정보를 확인할 수 없어요"))
    }

    @Test func searchFailureKeepsResultsAndShowsTheirTime() async throws {
        let server = Outage()
        let viewModel = SearchViewModel(repository: server.repository)
        await viewModel.search("금대")
        let shown = viewModel.state

        server.error = URLError(.notConnectedToInternet)
        await viewModel.retry()

        #expect(viewModel.state == shown)
        #expect(viewModel.offlineAsOf == Self.mockTime)

        server.error = nil
        await viewModel.retry()
        #expect(viewModel.offlineAsOf == nil)
    }
}

/// Mock answers, or `error` while it is set.
private final class Outage: @unchecked Sendable {
    private let lock = NSLock()
    private var current: (any Error)?
    var error: (any Error)? {
        get { lock.withLock { current } }
        set { lock.withLock { current = newValue } }
    }

    var repository: StubRepository {
        StubRepository(
            list: { [self] query in
                if let error { throw error }
                return try await MockValleyRepository().valleys(matching: query)
            },
            detail: { [self] id in
                if let error { throw error }
                return try await MockValleyRepository().valleyDetail(id: id)
            })
    }
}
