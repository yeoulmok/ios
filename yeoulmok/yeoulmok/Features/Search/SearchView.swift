import SwiftUI

/// "검색" tab: find valleys by name (APP-SRCH-02, Figma 02 v2 · 02a), narrowed by
/// province · city chips and loaded 20 at a time (APP-SRCH-04, #96).
/// Shows whatever `SearchViewModel.state` says; tapping a row opens its detail,
/// where the user subscribes (APP-DTL-06, #57).
struct SearchView: View {
    @State private var viewModel: SearchViewModel
    /// Text in the field. Kept in `@State`, so it survives tab switches.
    @State private var query = ""

    init(repository: any ValleyRepository) {
        _viewModel = State(initialValue: SearchViewModel(repository: repository))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            searchField
                .padding(.horizontal)
            Text("이름 있는 큰 계곡만 검색돼요")
                .font(.caption)
                .foregroundStyle(Theme.Text.body)
                .padding(.horizontal)
            if !viewModel.regions.isEmpty, !isFailed {
                SearchFilterChips(
                    total: viewModel.regions.reduce(0) { $0 + $1.count },
                    provinces: viewModel.regions, cities: viewModel.cities, filter: viewModel.filter,
                    selectProvince: { province in Task { await viewModel.selectProvince(province) } },
                    selectCity: { city in Task { await viewModel.selectCity(city) } })
                    .padding(.top, 4)
            }
            if let asOf = viewModel.offlineAsOf {
                OfflineBanner(asOf: asOf)
                    .padding(.horizontal)
            }
            content
        }
        .background { PhotoBackdrop(style: isFailed ? .offline : .normal, photoHeight: isFailed ? nil : 300) }
        .navigationTitle("계곡 검색")
        .task {
            // Runs each time the tab appears, so the list stays current (as many rows
            // as were shown, so coming back from a detail does not lose the scroll).
            async let chips: Void = viewModel.loadRegions()
            await viewModel.reload(query)
            await chips
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Text.label)
                .accessibilityHidden(true)
            TextField("계곡 이름 검색", text: $query)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .foregroundStyle(Theme.Text.primary)
                .accessibilityIdentifier("search.queryField")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: Theme.Radius.row)
        .onSubmit {
            Task { await viewModel.search(query) }
        }
        .onChange(of: query) { _, newValue in
                // Clearing the field brings the full list back without pressing search.
                if newValue.isEmpty {
                    Task { await viewModel.search() }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.Text.primary)
                Text("계곡 목록을 불러오고 있어요")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Text.body)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("search.loading")
        case let .loaded(valleys, source):
            resultList(valleys, source: source)
        case let .empty(query, source):
            // In a scroll view so it can be pulled to retry, like the banner says.
            ScrollView {
                SearchEmptyView(query: query, source: source, place: viewModel.shownFilter.placeName) {
                    await viewModel.clearFilter()
                }
                .containerRelativeFrame([.horizontal, .vertical])
                .opacity(viewModel.isRefreshing ? 0.5 : 1)
            }
            .overlay(alignment: .top) {
                if viewModel.isRefreshing { refreshingCircle.padding(.top, 12) }
            }
            .refreshable { await viewModel.retry() }
        case let .failed(message):
            VStack {
                Spacer()
                ErrorStateView(message: message) { await viewModel.retry() }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }

    private func resultList(_ valleys: [ValleySummary], source: String) -> some View {
        // All matches when the server counted them, else the rows received.
        let count = viewModel.total ?? valleys.count
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.shownFilter.placeName ?? "전체 계곡")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Text.primary)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(count)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Text.label)
                        .accessibilityLabel("\(count)곳")
                    Spacer()
                    if viewModel.isRefreshing { refreshingCircle }
                }
                .padding(.top, 12)
                Group {
                    ForEach(valleys) { valley in
                        SearchResultRow(valley: valley)
                            // #103: the next page starts 10 rows before the end. In its
                            // own task, so scrolling the row away does not cancel it.
                            .onAppear { Task { await viewModel.rowAppeared(valley) } }
                    }
                    SearchListEnd(viewModel: viewModel)
                }
                .opacity(viewModel.isRefreshing ? 0.5 : 1)
                // Figma 02 v2: the source line sits at the end of the list.
                SourceFooter(source: source)
                    .padding(.top, 12)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.immediately)
        .topBarScrollEdge()
        // "아래로 당겨 다시 시도" (OfflineBanner): the same search again.
        .refreshable { await viewModel.retry() }
    }
}

extension SearchView {
    /// A new first page is on its way: the old list stays dimmed under this (#96).
    private var refreshingCircle: some View {
        ProgressView()
            .tint(Theme.Text.primary)
            .accessibilityLabel("불러오는 중")
            .accessibilityIdentifier("search.refreshing")
    }

    private var isFailed: Bool {
        if case .failed = viewModel.state { true } else { false }
    }
}

#Preview {
    NavigationStack {
        SearchView(repository: try! MockValleyRepository())
    }
}

#Preview("126 valleys") {
    NavigationStack {
        SearchView(repository: try! MockValleyRepository(manyValleys: true, pageDelay: .milliseconds(600)))
    }
}
