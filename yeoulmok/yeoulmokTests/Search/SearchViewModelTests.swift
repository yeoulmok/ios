import Foundation
import Testing
@testable import yeoulmok

@MainActor
struct SearchViewModelTests {
    @Test func startsInLoading() throws {
        let viewModel = SearchViewModel(repository: try MockValleyRepository())
        #expect(viewModel.state == .loading)
    }

    @Test func blankQueryShowsAllValleysInServerOrder() async throws {
        let viewModel = SearchViewModel(repository: try MockValleyRepository())

        await viewModel.search("  ")

        guard case let .loaded(valleys, source) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        // Server order, not home's risk order.
        #expect(valleys.map(\.id) == [1, 2, 3, 4, 5])
        #expect(source == "자료: 한강홍수통제소, 기상청")
    }

    @Test func queryIsTrimmedAndFiltersByName() async throws {
        let viewModel = SearchViewModel(repository: try MockValleyRepository())

        await viewModel.search(" 금대리 ")

        guard case let .loaded(valleys, _) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(valleys.map(\.name) == ["금대리 계곡"])
        #expect(valleys.first?.isSubscribed == true)
    }

    @Test func noMatchIsEmptyWithTheQuery() async throws {
        let viewModel = SearchViewModel(repository: try MockValleyRepository())

        await viewModel.search(" 없는계곡 ")

        #expect(viewModel.state == .empty(query: "없는계곡", source: "자료: 한강홍수통제소, 기상청"))
    }

    @Test func serverErrorShowsServerMessage() async {
        let error = APIError(code: "DEVICE_NOT_FOUND", message: "기기 정보를 확인할 수 없어요")
        let viewModel = SearchViewModel(repository: StubRepository(list: { _ in throw error }))

        await viewModel.search()

        #expect(viewModel.state == .failed(message: "기기 정보를 확인할 수 없어요"))
    }

    @Test func networkErrorShowsConnectionMessage() async {
        let viewModel = SearchViewModel(repository: StubRepository(list: { _ in
            throw URLError(.notConnectedToInternet)
        }))

        await viewModel.search()

        #expect(viewModel.state == .failed(message: "연결할 수 없어요"))
    }

    @Test func lateAnswerToAnOlderSearchIsIgnored() async throws {
        let mock = try MockValleyRepository()
        // "금" answers slowly, "갑" answers at once.
        let viewModel = SearchViewModel(repository: StubRepository(list: { query in
            if query == "금" { try await Task.sleep(for: .milliseconds(300)) }
            return try await mock.valleys(matching: query)
        }))

        let older = Task { await viewModel.search("금") }
        try await Task.sleep(for: .milliseconds(50))
        await viewModel.search("갑")
        await older.value

        guard case let .loaded(valleys, _) = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(valleys.map(\.name) == ["갑천 계곡"])
    }
}
