import Foundation
import Testing
@testable import yeoulmok

@MainActor
struct HomeViewModelTests {
    @Test func startsInLoading() throws {
        let viewModel = HomeViewModel(repository: try MockValleyRepository())
        #expect(viewModel.state == .loading)
    }

    @Test func loadShowsSubscribedValleysInHomeOrder() async throws {
        let viewModel = HomeViewModel(repository: try MockValleyRepository())

        await viewModel.load()

        // Mock subscriptions: 1 주의, 2 판정 불가, 4 위험 → 위험, 주의, 판정 불가
        guard case let .loaded(valleys, source) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(valleys.map(\.id) == [4, 1, 2])
        #expect(source == "자료: 한강홍수통제소, 기상청")
    }

    @Test func noSubscriptionsIsEmptyNotError() async throws {
        let repository = try MockValleyRepository()
        for id in [1, 2, 4] {
            try await repository.unsubscribe(valleyID: id)
        }
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .empty(source: "자료: 한강홍수통제소, 기상청"))
    }

    @Test func serverErrorShowsServerMessage() async {
        let error = APIError(code: "DEVICE_NOT_FOUND", message: "기기 정보를 확인할 수 없어요")
        let viewModel = HomeViewModel(repository: FailingRepository(error: error))

        await viewModel.load()

        #expect(viewModel.state == .failed(message: "기기 정보를 확인할 수 없어요"))
    }

    @Test func networkErrorShowsConnectionMessage() async {
        let viewModel = HomeViewModel(repository: FailingRepository(error: URLError(.notConnectedToInternet)))

        await viewModel.load()

        #expect(viewModel.state == .failed(message: "연결할 수 없어요"))
    }

    // Pull to refresh (#9): a failed refresh keeps what was received before.

    @Test func failedRefreshKeepsTheList() async throws {
        let fails = Switch()
        let repository = StubRepository(list: { query in
            if fails.isOn { throw URLError(.notConnectedToInternet) }
            return try await MockValleyRepository().subscribedValleys()
        })
        let viewModel = HomeViewModel(repository: repository)
        await viewModel.load()
        let shown = viewModel.state

        fails.isOn = true
        await viewModel.load()

        #expect(viewModel.state == shown)
        guard case .loaded = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
    }

    @Test func failedRefreshKeepsTheEmptyState() async throws {
        let fails = Switch()
        let empty = ValleyListResponse(updatedAt: .now, source: "자료: 한강홍수통제소, 기상청", valleys: [])
        let viewModel = HomeViewModel(repository: StubRepository(list: { _ in
            if fails.isOn { throw URLError(.notConnectedToInternet) }
            return empty
        }))
        await viewModel.load()

        fails.isOn = true
        await viewModel.load()

        #expect(viewModel.state == .empty(source: "자료: 한강홍수통제소, 기상청"))
    }

    @Test func refreshAfterAnErrorShowsTheList() async throws {
        let fails = Switch()
        fails.isOn = true
        let viewModel = HomeViewModel(repository: StubRepository(list: { _ in
            if fails.isOn { throw URLError(.notConnectedToInternet) }
            return try await MockValleyRepository().subscribedValleys()
        }))
        await viewModel.load()
        #expect(viewModel.state == .failed(message: "연결할 수 없어요"))

        fails.isOn = false
        await viewModel.load()

        guard case let .loaded(valleys, _) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(valleys.map(\.id) == [4, 1, 2])
    }
}

/// A flag a `@Sendable` stub closure can read while the test flips it.
private final class Switch: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    var isOn: Bool {
        get { lock.withLock { value } }
        set { lock.withLock { value = newValue } }
    }
}

/// A repository whose every call fails with the given error.
private struct FailingRepository: ValleyRepository {
    let error: any Error

    func valleys(matching query: String?) async throws -> ValleyListResponse { throw error }
    func subscribedValleys() async throws -> ValleyListResponse { throw error }
    func valleyDetail(id: Int) async throws -> ValleyDetail { throw error }
    func subscribe(valleyID: Int) async throws { throw error }
    func unsubscribe(valleyID: Int) async throws { throw error }
    func ask(valleyID: Int, question: String) async throws -> AskAnswer { throw error }
}
