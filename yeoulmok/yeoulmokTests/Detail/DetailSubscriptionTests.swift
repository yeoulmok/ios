import Foundation
import Testing
@testable import yeoulmok

/// APP-DTL-06 (#57): "구독" ↔ "구독중" on the alert detail. Same rules the search list had (#7).
/// Mock subscriptions: 1 금대리, 2 갑천, 4 위험 예시. Not subscribed: 3 안전 예시, 5 대피 예시.
@MainActor
struct DetailSubscriptionTests {
    private func isSubscribed(_ viewModel: ValleyDetailViewModel) -> Bool? {
        guard case let .loaded(detail) = viewModel.state else { return nil }
        return detail.isSubscribed
    }

    @Test func subscribeFlipsButtonAndReachesHome() async throws {
        let repository = try MockValleyRepository()
        let viewModel = ValleyDetailViewModel(valleyID: 3, repository: repository)
        await viewModel.load()
        #expect(isSubscribed(viewModel) == false)

        await viewModel.toggleSubscription()

        #expect(isSubscribed(viewModel) == true)
        // Home reads the same repository, so it sees the new subscription.
        let home = try await repository.subscribedValleys().valleys.map(\.id)
        #expect(home.contains(3))
        #expect(viewModel.toastMessage == nil)
    }

    @Test func unsubscribeFlipsButtonAndLeavesHome() async throws {
        let repository = try MockValleyRepository()
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: repository)
        await viewModel.load()

        await viewModel.toggleSubscription()

        #expect(isSubscribed(viewModel) == false)
        let home = try await repository.subscribedValleys().valleys.map(\.id)
        #expect(!home.contains(1))
    }

    @Test func buttonFlipsBeforeTheServerAnswers() async throws {
        let viewModel = ValleyDetailViewModel(valleyID: 3, repository: StubRepository(changeSubscription: { _, _ in
            try await Task.sleep(for: .milliseconds(300))
        }))
        await viewModel.load()

        let request = Task { await viewModel.toggleSubscription() }
        try await Task.sleep(for: .milliseconds(50))

        #expect(isSubscribed(viewModel) == true)
        #expect(viewModel.isSubscriptionPending)
        await request.value
        #expect(!viewModel.isSubscriptionPending)
    }

    @Test(arguments: [3, 1])
    func failureFlipsBackAndShowsToast(valleyID: Int) async throws {
        let viewModel = ValleyDetailViewModel(valleyID: valleyID, repository: StubRepository(changeSubscription: { _, _ in
            throw URLError(.notConnectedToInternet)
        }))
        await viewModel.load()
        let before = isSubscribed(viewModel)

        await viewModel.toggleSubscription()

        #expect(isSubscribed(viewModel) == before)
        #expect(viewModel.toastMessage == "구독을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.")
        #expect(!viewModel.isSubscriptionPending)
    }

    @Test func secondTapWhileWaitingIsIgnored() async throws {
        let calls = Counter()
        let viewModel = ValleyDetailViewModel(valleyID: 3, repository: StubRepository(changeSubscription: { _, _ in
            await calls.increment()
            try await Task.sleep(for: .milliseconds(300))
        }))
        await viewModel.load()

        let first = Task { await viewModel.toggleSubscription() }
        try await Task.sleep(for: .milliseconds(50))
        await viewModel.toggleSubscription()
        await first.value

        #expect(await calls.value == 1)
        #expect(isSubscribed(viewModel) == true)
    }

    @Test func nothingHappensBeforeTheDetailLoads() async throws {
        let calls = Counter()
        let viewModel = ValleyDetailViewModel(valleyID: 3, repository: StubRepository(changeSubscription: { _, _ in
            await calls.increment()
        }))

        await viewModel.toggleSubscription()

        #expect(await calls.value == 0)
        #expect(viewModel.state == .loading)
    }

    @Test func savedCopyKeepsTheNewSubscription() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "DetailSubscriptionTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let cache = ValleyCache(directory: directory)
        let viewModel = ValleyDetailViewModel(valleyID: 3, repository: try MockValleyRepository(), cache: cache)
        await viewModel.load()

        await viewModel.toggleSubscription()

        #expect(await cache.detail(id: 3)?.isSubscribed == true)
    }
}

private actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}
