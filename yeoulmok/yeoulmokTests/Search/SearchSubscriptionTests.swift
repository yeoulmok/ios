import Foundation
import Testing
@testable import yeoulmok

/// APP-SRCH-03: "구독" ↔ "구독중" from the search list.
/// Mock subscriptions: 1 금대리, 2 갑천, 4 위험 예시. Not subscribed: 3 안전 예시, 5 대피 예시.
@MainActor
struct SearchSubscriptionTests {
    private func isSubscribed(_ id: Int, in viewModel: SearchViewModel) -> Bool? {
        guard case let .loaded(valleys, _) = viewModel.state else { return nil }
        return valleys.first { $0.id == id }?.isSubscribed
    }

    @Test func subscribeFlipsButtonAndReachesHome() async throws {
        let repository = try MockValleyRepository()
        let viewModel = SearchViewModel(repository: repository)
        await viewModel.search()

        await viewModel.toggleSubscription(valleyID: 3)

        #expect(isSubscribed(3, in: viewModel) == true)
        // Home reads the same repository, so it sees the new subscription.
        let home = try await repository.subscribedValleys().valleys.map(\.id)
        #expect(home.contains(3))
        #expect(viewModel.toastMessage == nil)
    }

    @Test func unsubscribeFlipsButtonAndLeavesHome() async throws {
        let repository = try MockValleyRepository()
        let viewModel = SearchViewModel(repository: repository)
        await viewModel.search()

        await viewModel.toggleSubscription(valleyID: 1)

        #expect(isSubscribed(1, in: viewModel) == false)
        let home = try await repository.subscribedValleys().valleys.map(\.id)
        #expect(!home.contains(1))
    }

    @Test func buttonFlipsBeforeTheServerAnswers() async throws {
        let viewModel = SearchViewModel(repository: StubRepository(changeSubscription: { _, _ in
            try await Task.sleep(for: .milliseconds(300))
        }))
        await viewModel.search()

        let request = Task { await viewModel.toggleSubscription(valleyID: 3) }
        try await Task.sleep(for: .milliseconds(50))

        #expect(isSubscribed(3, in: viewModel) == true)
        #expect(viewModel.pendingValleyIDs == [3])
        await request.value
        #expect(viewModel.pendingValleyIDs.isEmpty)
    }

    @Test(arguments: [3, 1])
    func failureFlipsBackAndShowsToast(valleyID: Int) async throws {
        let viewModel = SearchViewModel(repository: StubRepository(changeSubscription: { _, _ in
            throw URLError(.notConnectedToInternet)
        }))
        await viewModel.search()
        let before = isSubscribed(valleyID, in: viewModel)

        await viewModel.toggleSubscription(valleyID: valleyID)

        #expect(isSubscribed(valleyID, in: viewModel) == before)
        #expect(viewModel.toastMessage == "구독을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.")
        #expect(viewModel.pendingValleyIDs.isEmpty)
    }

    @Test func secondTapWhileWaitingIsIgnored() async throws {
        let calls = Counter()
        let viewModel = SearchViewModel(repository: StubRepository(changeSubscription: { _, _ in
            await calls.increment()
            try await Task.sleep(for: .milliseconds(300))
        }))
        await viewModel.search()

        let first = Task { await viewModel.toggleSubscription(valleyID: 3) }
        try await Task.sleep(for: .milliseconds(50))
        await viewModel.toggleSubscription(valleyID: 3)
        await first.value

        #expect(await calls.value == 1)
        #expect(isSubscribed(3, in: viewModel) == true)
    }

    @Test func otherValleysCanChangeWhileOneIsWaiting() async throws {
        let calls = Counter()
        let viewModel = SearchViewModel(repository: StubRepository(changeSubscription: { id, _ in
            await calls.increment()
            if id == 3 { try await Task.sleep(for: .milliseconds(300)) }
        }))
        await viewModel.search()

        let slow = Task { await viewModel.toggleSubscription(valleyID: 3) }
        try await Task.sleep(for: .milliseconds(50))
        await viewModel.toggleSubscription(valleyID: 5)
        await slow.value

        #expect(await calls.value == 2)
        #expect(isSubscribed(3, in: viewModel) == true)
        #expect(isSubscribed(5, in: viewModel) == true)
    }
}

private actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}
