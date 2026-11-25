import Foundation
import Testing
@testable import yeoulmok

/// APP-SRCH-04 (#96): filter chips, pages of 20, and the loading states of the search tab.
@MainActor
struct SearchPagingTests {
    private func manyValleys() throws -> SearchViewModel {
        SearchViewModel(repository: try MockValleyRepository(manyValleys: true))
    }

    // MARK: Pages

    @Test func firstPageIsTwentyOfTheTotal() async throws {
        let viewModel = try manyValleys()

        await viewModel.search()

        #expect(viewModel.valleys.count == 20)
        #expect(viewModel.total == 126)
        #expect(viewModel.canLoadMore)
        #expect(!viewModel.hasLoadedAll)
    }

    @Test func loadMoreAddsTheNextPageUntilTheEnd() async throws {
        let viewModel = try manyValleys()
        await viewModel.search()

        await viewModel.loadMore()
        #expect(viewModel.valleys.count == 40)

        for _ in 0..<10 { await viewModel.loadMore() }

        #expect(viewModel.valleys.count == 126)
        #expect(Set(viewModel.valleys.map(\.id)).count == 126)
        #expect(!viewModel.canLoadMore)
        #expect(viewModel.hasLoadedAll)
    }

    @Test func nextPageAsksFromTheEndWithTheSameSearch() async throws {
        let asked = RequestLog()
        let mock = try MockValleyRepository(manyValleys: true)
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            asked.append(request)
            return try await mock.valleyPage(request)
        }))
        await viewModel.selectProvince("강원")
        await viewModel.search(" 천 ")

        await viewModel.loadMore()

        let gangwon = ValleyFilter(province: "강원", city: nil)
        #expect(asked.requests.last == ValleyPageRequest(query: "천", filter: gangwon, offset: 20, limit: 20))
    }

    /// A server without pages sends everything and no `total`: nothing more to load,
    /// and no "모두 봤어요" (the server did not count).
    @Test func serverWithoutPagesShowsEverythingOnce() async throws {
        let calls = RequestLog()
        let stub = SearchViewModel(repository: StubRepository(list: { query in
            calls.append(ValleyPageRequest(query: query, filter: .all, offset: 0, limit: 0))
            return try await MockValleyRepository().valleys(matching: query)
        }))

        await stub.search()
        await stub.loadMore()

        #expect(stub.valleys.count == 5)
        #expect(stub.total == nil)
        #expect(!stub.canLoadMore)
        #expect(!stub.hasLoadedAll)
        #expect(calls.requests.count == 1)
    }

    @Test func failedPageKeepsTheListAndCanBeTriedAgain() async throws {
        let fails = Switch()
        let mock = try MockValleyRepository(manyValleys: true)
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            if request.offset > 0, fails.isOn { throw URLError(.notConnectedToInternet) }
            return try await mock.valleyPage(request)
        }))
        await viewModel.search()
        fails.isOn = true

        await viewModel.loadMore()
        #expect(viewModel.loadMoreFailed)
        #expect(viewModel.valleys.count == 20)
        #expect(viewModel.offlineAsOf == nil)

        // Scrolling again does not hammer the server; the button does.
        await viewModel.loadMore()
        #expect(viewModel.valleys.count == 20)

        fails.isOn = false
        await viewModel.retryMore()
        #expect(!viewModel.loadMoreFailed)
        #expect(viewModel.valleys.count == 40)
    }

    /// A page of the old list that arrives after a new search is thrown away.
    @Test func lateNextPageOfAnOlderListIsIgnored() async throws {
        let mock = try MockValleyRepository(manyValleys: true)
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            if request.offset > 0 { try await Task.sleep(for: .milliseconds(300)) }
            return try await mock.valleyPage(request)
        }))
        await viewModel.search()

        let olderPage = Task { await viewModel.loadMore() }
        try await Task.sleep(for: .milliseconds(50))
        await viewModel.selectProvince("서울")
        await olderPage.value

        #expect(viewModel.valleys.map(\.province) == ["서울"])
        #expect(!viewModel.isLoadingMore)
    }

    // MARK: Filter

    @Test func choosingAProvinceStartsAgainFromTheTop() async throws {
        let viewModel = try manyValleys()
        await viewModel.search()
        await viewModel.loadMore()

        await viewModel.selectProvince("강원")

        #expect(viewModel.filter == ValleyFilter(province: "강원", city: nil))
        #expect(viewModel.valleys.count == 20)
        #expect(viewModel.total == 111)
        #expect(viewModel.valleys.allSatisfy { $0.province == "강원" })
    }

    @Test func citiesShowOnlyForAProvinceWithSeveral() async throws {
        let viewModel = try manyValleys()
        await viewModel.loadRegions()
        #expect(viewModel.regions.first?.province == "강원")
        #expect(viewModel.cities.isEmpty)

        await viewModel.selectProvince("강원")
        #expect(viewModel.cities.first?.city == "횡성군")

        await viewModel.selectProvince("서울")
        #expect(viewModel.cities.isEmpty)
    }

    @Test func choosingACityKeepsTheProvinceAndANewProvinceClearsIt() async throws {
        let viewModel = try manyValleys()
        await viewModel.selectProvince("강원")

        await viewModel.selectCity("횡성군")
        #expect(viewModel.total == 14)

        await viewModel.selectProvince("경기")
        #expect(viewModel.filter == ValleyFilter(province: "경기", city: nil))
    }

    /// Filter and text together; "전체 지역에서 찾기" keeps the text.
    @Test func emptyWithFilterAndClearingIt() async throws {
        let viewModel = try manyValleys()
        await viewModel.selectProvince("서울")
        await viewModel.search("신림")
        #expect(viewModel.valleys.count == 1)

        await viewModel.selectProvince("제주")
        #expect(viewModel.state == .empty(query: "신림", source: "자료: 한강홍수통제소, 기상청"))
        #expect(viewModel.shownFilter.placeName == "제주")

        await viewModel.clearFilter()
        #expect(viewModel.filter == .all)
        // 원주 신림면 valleys match "신림" too, now that Seoul is no longer the only place.
        #expect(viewModel.valleys.count == 4)
        #expect(viewModel.valleys.contains { $0.name == "신림동 도림천" })
    }

    /// Without `/regions` the chips are hidden and search works as before.
    @Test func regionsFailureHidesTheChips() async throws {
        let viewModel = SearchViewModel(repository: StubRepository(regionList: {
            throw APIError(code: "NOT_FOUND", message: "없음")
        }))

        await viewModel.loadRegions()
        await viewModel.search()

        #expect(viewModel.regions.isEmpty)
        #expect(viewModel.valleys.count == 5)
    }

    @Test func retryLoadsChipsThatFailedBefore() async throws {
        let fails = Switch()
        fails.isOn = true
        let viewModel = SearchViewModel(repository: StubRepository(regionList: {
            if fails.isOn { throw URLError(.notConnectedToInternet) }
            return try await MockValleyRepository().regions()
        }))
        await viewModel.loadRegions()
        #expect(viewModel.regions.isEmpty)
        fails.isOn = false

        await viewModel.retry()

        #expect(!viewModel.regions.isEmpty)
    }

    // MARK: Loading

    /// While a new search is on its way the old list stays, marked as refreshing.
    @Test func newSearchKeepsTheOldListWhileRefreshing() async throws {
        let mock = try MockValleyRepository(manyValleys: true)
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            if request.query == "계곡" { try await Task.sleep(for: .milliseconds(300)) }
            return try await mock.valleyPage(request)
        }))
        await viewModel.search()
        #expect(!viewModel.isRefreshing)

        let searching = Task { await viewModel.search("계곡") }
        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.isRefreshing)
        #expect(viewModel.valleys.count == 20)

        await searching.value
        #expect(!viewModel.isRefreshing)
    }

    /// Back on the tab after scrolling: the same rows again, not just the first page.
    @Test func reloadKeepsAsManyRowsAsShown() async throws {
        let asked = RequestLog()
        let mock = try MockValleyRepository(manyValleys: true)
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            asked.append(request)
            return try await mock.valleyPage(request)
        }))
        await viewModel.search()
        await viewModel.loadMore()
        await viewModel.loadMore()

        await viewModel.reload("")

        #expect(asked.requests.last?.offset == 0)
        #expect(asked.requests.last?.limit == 60)
        #expect(viewModel.valleys.count == 60)
        #expect(viewModel.canLoadMore)
    }

    /// #98: back on the tab after scrolling past 100 rows. The server takes at most
    /// 100 at a time, so the rows come back in two requests, with no offline banner.
    @Test func reloadPastAHundredRowsAsksInChunks() async throws {
        let asked = RequestLog()
        let mock = try MockValleyRepository(manyValleys: true)
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            asked.append(request)
            return try await mock.valleyPage(request)
        }))
        await viewModel.search()
        for _ in 0..<10 { await viewModel.loadMore() }
        #expect(viewModel.valleys.count == 126)

        await viewModel.reload("")

        #expect(asked.requests.suffix(2).map(\.offset) == [0, 100])
        #expect(asked.requests.suffix(2).map(\.limit) == [100, 26])
        #expect(viewModel.valleys.count == 126)
        #expect(Set(viewModel.valleys.map(\.id)).count == 126)
        #expect(viewModel.offlineAsOf == nil)
        #expect(viewModel.hasLoadedAll)
    }

    /// A list that shrank on the server meanwhile: stops when there is no more.
    @Test func reloadStopsWhenTheServerHasFewer() async throws {
        let viewModel = try manyValleys()
        await viewModel.selectProvince("강원")
        for _ in 0..<10 { await viewModel.loadMore() }
        #expect(viewModel.valleys.count == 111)

        await viewModel.reload("")

        #expect(viewModel.valleys.count == 111)
        #expect(viewModel.total == 111)
        #expect(viewModel.offlineAsOf == nil)
    }

    @Test func reloadWithNewTextIsANewSearch() async throws {
        let viewModel = try manyValleys()
        await viewModel.search()
        await viewModel.loadMore()

        await viewModel.reload("도림천")

        #expect(viewModel.valleys.map(\.name) == ["신림동 도림천"])
    }

    /// While 강원 is on its way the chip is on at once, but the title still names the
    /// list on screen.
    @Test func titleFollowsTheListNotTheTappedChip() async throws {
        let mock = try MockValleyRepository(manyValleys: true)
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            if request.filter.province != nil { try await Task.sleep(for: .milliseconds(300)) }
            return try await mock.valleyPage(request)
        }))
        await viewModel.search()

        let choosing = Task { await viewModel.selectProvince("강원") }
        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.filter.province == "강원")
        #expect(viewModel.shownFilter == .all)
        #expect(viewModel.total == 126)

        await choosing.value
        #expect(viewModel.shownFilter.province == "강원")
        #expect(viewModel.total == 111)
    }

    @Test func failedFilterPutsTheChipsBack() async throws {
        let mock = try MockValleyRepository(manyValleys: true)
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            if request.filter.province == "강원" { throw URLError(.notConnectedToInternet) }
            return try await mock.valleyPage(request)
        }))
        await viewModel.search()

        await viewModel.selectProvince("강원")

        #expect(viewModel.filter == .all)
        #expect(viewModel.offlineAsOf != nil)
        #expect(viewModel.valleys.count == 20)
    }

    /// The very first load is the big spinner (`.loading`), not "refreshing".
    @Test func firstLoadIsNotRefreshing() async throws {
        let viewModel = SearchViewModel(repository: StubRepository(page: { request in
            try await Task.sleep(for: .milliseconds(300))
            return try await MockValleyRepository().valleyPage(request)
        }))

        let loading = Task { await viewModel.search() }
        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.state == .loading)
        #expect(!viewModel.isRefreshing)
        await loading.value
    }
}

private final class RequestLog: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [ValleyPageRequest] = []
    var requests: [ValleyPageRequest] { lock.withLock { values } }
    func append(_ request: ValleyPageRequest) { lock.withLock { values.append(request) } }
}

private final class Switch: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    var isOn: Bool {
        get { lock.withLock { value } }
        set { lock.withLock { value = newValue } }
    }
}
