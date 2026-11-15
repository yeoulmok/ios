import Foundation
import Testing
@testable import yeoulmok

@MainActor
struct ValleyDetailViewModelTests {
    @Test func startsInLoading() throws {
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: StubRepository())
        #expect(viewModel.state == .loading)
    }

    @Test func loadShowsThatValleysDetail() async throws {
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: StubRepository())

        await viewModel.load()

        guard case let .loaded(detail) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(detail.id == 1)
        #expect(detail.name == "금대리 계곡")
        #expect(detail.level == .caution)
        #expect(detail.summary == "상류에 비가 많이 오고 있어요")
    }

    @Test func unknownLevelIsLoadedNotAnError() async throws {
        // Feature spec 3-1: level unknown is shown with the "판정 불가" badge, not an error screen.
        let viewModel = ValleyDetailViewModel(valleyID: 2, repository: StubRepository())

        await viewModel.load()

        guard case let .loaded(detail) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(detail.level == .unknown)
    }

    @Test func serverErrorCodeShowsServerMessage() async {
        let repository = StubRepository(detail: { _ in throw APIError.valleyNotFound })
        let viewModel = ValleyDetailViewModel(valleyID: 99, repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .failed(message: "계곡 정보를 찾을 수 없어요"))
    }

    @Test func connectionErrorShowsConnectionMessage() async {
        let repository = StubRepository(detail: { _ in throw URLError(.notConnectedToInternet) })
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .failed(message: "연결할 수 없어요"))
    }

    @Test func failureAfterLoadKeepsTheShownDetail() async throws {
        let fails = Switch()
        let repository = StubRepository(detail: { id in
            if fails.isOn { throw URLError(.notConnectedToInternet) }
            return try await MockValleyRepository().valleyDetail(id: id)
        })
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: repository)
        await viewModel.load()
        let shown = viewModel.state

        fails.isOn = true
        await viewModel.load()

        #expect(viewModel.state == shown)
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
