import Foundation
import Observation

/// State of the search tab (APP-SRCH-02, Figma 02 v2 · 02a; APP-SRCH-04, #96).
/// The view only reads the properties.
///
/// The list comes in pages of `pageSize`: the first page replaces the list, later
/// pages (`loadMore`) are added to its end until `total` is reached. A server without
/// pages sends no `total`, and then the first page is the whole list.
@Observable
final class SearchViewModel {
    /// The screen is in exactly one of these at a time (feature spec 3-1).
    enum State: Equatable {
        /// First load. The screen frame stays and a spinner is shown.
        case loading
        /// Valleys in server order (no risk sorting: search rows have no badge).
        /// Every page loaded so far, in order.
        case loaded(valleys: [ValleySummary], source: String)
        /// Request succeeded but nothing matched (Figma 02a).
        /// `query` is the trimmed search text, empty when there was none.
        /// The filter that was on is `shownFilter`.
        case empty(query: String, source: String)
        /// Request failed and nothing was loaded before. Screen: `ErrorStateView`.
        case failed(message: String)
    }

    /// Valleys asked for at a time.
    static let pageSize = 20

    private(set) var state: State = .loading

    /// Provinces for the filter chips, most valleys first. Empty when the server has no
    /// `/regions` yet: then the chips are hidden and the list works as before.
    private(set) var regions: [ValleyRegions.Province] = []
    /// The chosen chips. Changes at once on a tap; the list follows when it arrives.
    private(set) var filter: ValleyFilter = .all
    /// The filter the list (or empty screen) on screen was asked with, for its title
    /// and wording, so they never name a place whose list has not arrived yet.
    private(set) var shownFilter: ValleyFilter = .all
    /// All matches for the list on screen; `nil` when the server sent everything at once.
    private(set) var total: Int?
    /// A new first page is on its way while the old list (or empty screen) is shown.
    private(set) var isRefreshing = false
    /// The next page is on its way.
    private(set) var isLoadingMore = false
    /// The next page failed; the list stays and the end of it offers "다시 시도".
    private(set) var loadMoreFailed = false

    private let repository: any ValleyRepository
    /// Counts first-page requests, so an older answer (or a page of an older list) that
    /// arrives late is thrown away.
    private var latestRequest = 0
    /// The last text passed to `search`, for "다시 시도" (#17).
    private(set) var lastQuery = ""
    /// Set when the last search failed and older results stay on screen (APP-COM-07):
    /// their `updated_at`. Search results are not saved on the device.
    private(set) var offlineAsOf: Date?
    /// `updated_at` of the results on screen.
    private var shownUpdatedAt: Date?

    init(repository: any ValleyRepository) {
        self.repository = repository
    }

    /// Valleys on screen, whatever the state.
    var valleys: [ValleySummary] {
        if case let .loaded(valleys, _) = state { valleys } else { [] }
    }

    /// More valleys match than are on screen.
    var canLoadMore: Bool {
        guard let total else { return false }
        return !valleys.isEmpty && valleys.count < total
    }

    /// Every match is on screen, counted by the server: "N곳 모두 봤어요".
    var hasLoadedAll: Bool {
        total != nil && !valleys.isEmpty && !canLoadMore
    }

    /// The selected province chip's cities, when there is more than one to choose from.
    var cities: [ValleyRegions.City] {
        guard let province = filter.province,
              let cities = regions.first(where: { $0.province == province })?.cities,
              cities.count > 1 else { return [] }
        return cities
    }

    /// Loads the chips once; tried again on the next `loadRegions` while it failed.
    func loadRegions() async {
        guard regions.isEmpty else { return }
        if let answer = try? await repository.regions() {
            regions = answer.chipOrder
        }
    }

    /// Loads the first page of valleys matching `query` (all valleys when it is blank)
    /// and the current filter. Does not reset `state` to `.loading`, so the old list
    /// stays (dimmed, `isRefreshing`) while waiting.
    func search(_ query: String = "") async {
        await load(query, limit: Self.pageSize, quietly: false)
    }

    /// The tab appears again (e.g. back from a detail, where the user may have
    /// subscribed): the same list asked again with as many rows as are shown, so it
    /// neither shrinks back to one page nor dims. The first time it is `search`.
    func reload(_ query: String) async {
        guard case let .loaded(shown, _) = state, query == lastQuery else {
            await search(query)
            return
        }
        await load(query, limit: max(Self.pageSize, shown.count), quietly: true)
    }

    private func load(_ query: String, limit: Int, quietly: Bool) async {
        latestRequest += 1
        let request = latestRequest
        lastQuery = query
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        isRefreshing = !quietly && state != .loading
        let requestedFilter = filter
        isLoadingMore = false
        loadMoreFailed = false

        let result: Result<ValleyListResponse, any Error>
        do {
            result = .success(try await repository.valleyPage(ValleyPageRequest(
                query: trimmed.isEmpty ? nil : trimmed, filter: requestedFilter, offset: 0, limit: limit)))
        } catch {
            result = .failure(error)
        }

        // The user searched again while this one was waiting: keep the newer result.
        guard request == latestRequest else { return }
        isRefreshing = false
        switch result {
        case let .success(response):
            state = response.valleys.isEmpty
                ? .empty(query: trimmed, source: response.source)
                : .loaded(valleys: response.valleys, source: response.source)
            total = response.total
            shownFilter = requestedFilter
            shownUpdatedAt = response.updatedAt
            offlineAsOf = nil
        case let .failure(error):
            switch state {
            case .loaded, .empty:
                // Feature spec 3-1: keep what is shown and say how old it is. The chips
                // go back to the list that stays, like a subscribe button that fails.
                offlineAsOf = shownUpdatedAt
                filter = shownFilter
            case .loading, .failed:
                state = .failed(message: ErrorMessage.text(for: error))
            }
        }
    }

    /// The next page, when the end of the list comes into view. Does nothing while a
    /// page is on its way, after a failure (until `retryMore`), or when all are shown.
    func loadMore() async {
        guard canLoadMore, !isLoadingMore, !isRefreshing, !loadMoreFailed,
              case let .loaded(shown, source) = state else { return }
        let request = latestRequest
        isLoadingMore = true
        let trimmed = lastQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        let result: Result<ValleyListResponse, any Error>
        do {
            result = .success(try await repository.valleyPage(ValleyPageRequest(
                query: trimmed.isEmpty ? nil : trimmed, filter: shownFilter,
                offset: shown.count, limit: Self.pageSize)))
        } catch {
            result = .failure(error)
        }

        // The list was replaced (new search or filter) while this page was on its way.
        guard request == latestRequest else { return }
        isLoadingMore = false
        switch result {
        case let .success(response):
            let known = Set(shown.map(\.id))
            let added = response.valleys.filter { !known.contains($0.id) }
            state = .loaded(valleys: shown + added, source: source)
            // An empty page means the server has no more, whatever `total` said.
            total = added.isEmpty ? shown.count : response.total
        case .failure:
            loadMoreFailed = true
        }
    }

    /// "다시 시도" at the end of the list after a page failed.
    func retryMore() async {
        loadMoreFailed = false
        await loadMore()
    }

    /// A province chip. `nil` is "전체". Choosing a province clears the city.
    func selectProvince(_ province: String?) async {
        guard province != filter.province || filter.city != nil else { return }
        filter = ValleyFilter(province: province, city: nil)
        await search(lastQuery)
    }

    /// A city chip of the chosen province. `nil` is "<도> 전체".
    func selectCity(_ city: String?) async {
        guard filter.province != nil, city != filter.city else { return }
        filter.city = city
        await search(lastQuery)
    }

    /// "전체 지역에서 찾기" on the empty screen: same text, no filter.
    func clearFilter() async {
        filter = .all
        await search(lastQuery)
    }

    /// "다시 시도" on the error screen (#17) and pull to refresh: the same search
    /// again, and the chips if they did not load.
    func retry() async {
        async let chips: Void = loadRegions()
        await search(lastQuery)
        await chips
    }
}
