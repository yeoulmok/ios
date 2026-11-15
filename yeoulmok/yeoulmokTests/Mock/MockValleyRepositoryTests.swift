import Foundation
import Testing
@testable import yeoulmok

struct MockValleyRepositoryTests {
    private let repository: any ValleyRepository

    init() throws {
        // A fresh repository per test, so subscriptions never leak between tests.
        repository = try MockValleyRepository()
    }

    @Test(arguments: [
        (nil, [1, 2, 3, 4, 5]),
        ("", [1, 2, 3, 4, 5]),
        ("금대", [1]),
        ("횡성", [2]),
        ("예시", [3, 4, 5]),
        ("없는 계곡", []),
    ] as [(String?, [Int])])
    func searchMatchesNameOrRegion(query: String?, expectedIDs: [Int]) async throws {
        let response = try await repository.valleys(matching: query)
        #expect(response.valleys.map(\.id) == expectedIDs)
        #expect(response.source.isEmpty == false)
    }

    @Test func subscribedValleysKeepSubscriptionOrder() async throws {
        #expect(try await repository.subscribedValleys().valleys.map(\.id) == [1, 2, 4])

        try await repository.subscribe(valleyID: 5)
        try await repository.subscribe(valleyID: 3)

        #expect(try await repository.subscribedValleys().valleys.map(\.id) == [1, 2, 4, 5, 3])
    }

    @Test func subscribeShowsEverywhere() async throws {
        try await repository.subscribe(valleyID: 3)

        let inList = try await repository.valleys(matching: nil).valleys.first { $0.id == 3 }
        #expect(inList?.isSubscribed == true)
        #expect(try await repository.valleyDetail(id: 3).isSubscribed == true)
    }

    @Test func unsubscribeShowsEverywhere() async throws {
        try await repository.unsubscribe(valleyID: 1)

        #expect(try await repository.subscribedValleys().valleys.map(\.id) == [2, 4])
        let inList = try await repository.valleys(matching: nil).valleys.first { $0.id == 1 }
        #expect(inList?.isSubscribed == false)
        #expect(try await repository.valleyDetail(id: 1).isSubscribed == false)
    }

    @Test func repeatingSubscribeOrUnsubscribeIsHarmless() async throws {
        try await repository.subscribe(valleyID: 1)
        try await repository.subscribe(valleyID: 1)
        #expect(try await repository.subscribedValleys().valleys.map(\.id) == [1, 2, 4])

        try await repository.unsubscribe(valleyID: 3)
        #expect(try await repository.subscribedValleys().valleys.map(\.id) == [1, 2, 4])
    }

    @Test func unknownValleyThrowsNotFound() async {
        await #expect(throws: APIError.valleyNotFound) {
            try await repository.valleyDetail(id: 99)
        }
        await #expect(throws: APIError.valleyNotFound) {
            try await repository.subscribe(valleyID: 99)
        }
        await #expect(throws: APIError.valleyNotFound) {
            try await repository.unsubscribe(valleyID: 99)
        }
    }

    @Test func failureSwitchFailsChangesAndKeepsSubscriptions() async throws {
        let failing = try MockValleyRepository(failsSubscriptionChanges: true)

        await #expect(throws: URLError.self) { try await failing.subscribe(valleyID: 3) }
        await #expect(throws: URLError.self) { try await failing.unsubscribe(valleyID: 1) }

        // Nothing changed: still 1 금대리, 2 갑천, 4 위험 예시.
        let subscribed = try await failing.subscribedValleys().valleys.map(\.id)
        #expect(subscribed == [1, 2, 4])
    }

    @Test func firstLoadFailureSwitchFailsOnlyTheFirstLoad() async throws {
        let failing = try MockValleyRepository(failsFirstLoad: true)

        await #expect(throws: URLError.self) { try await failing.subscribedValleys() }

        // "다시 시도" (#17) then works, for every kind of load.
        #expect(try await failing.subscribedValleys().valleys.map(\.id) == [1, 2, 4])
        #expect(try await failing.valleys(matching: nil).valleys.count == 5)
        #expect(try await failing.valleyDetail(id: 1).name == "금대리 계곡")
    }

    @Test func offlineAfterFirstLoadSwitchAnswersEachRequestOnce() async throws {
        let mock = try MockValleyRepository(failsRepeatedLoads: true)

        #expect(try await mock.subscribedValleys().valleys.count == 3)
        #expect(try await mock.valleyDetail(id: 1).id == 1)
        #expect(try await mock.valleys(matching: "금대").valleys.count == 1)

        // Asking again is "offline" (pull to refresh, #16).
        await #expect(throws: URLError.self) { try await mock.subscribedValleys() }
        await #expect(throws: URLError.self) { try await mock.valleyDetail(id: 1) }
        await #expect(throws: URLError.self) { try await mock.valleys(matching: "금대") }
        // A request not asked before still works once.
        #expect(try await mock.valleyDetail(id: 2).id == 2)
    }
}
