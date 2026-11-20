import SwiftUI

/// "검색" tab: find valleys by name (APP-SRCH-02, Figma 02 v2 · 02a).
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
            if let asOf = viewModel.offlineAsOf {
                OfflineBanner(asOf: asOf)
                    .padding(.horizontal)
            }
            content
        }
        .background { PhotoBackdrop(style: isFailed ? .offline : .normal, photoHeight: isFailed ? nil : 300) }
        .navigationTitle("계곡 검색")
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            // Runs each time the tab appears, so the list stays current.
            await viewModel.search(query)
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
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .loaded(valleys, source):
            resultList(valleys, source: source)
        case let .empty(query, source):
            // In a scroll view so it can be pulled to retry, like the banner says.
            ScrollView {
                SearchEmptyView(query: query, source: source)
                    .containerRelativeFrame([.horizontal, .vertical])
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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("전체 계곡")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Text.primary)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(valleys.count)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Text.label)
                        .accessibilityLabel("\(valleys.count)곳")
                }
                .padding(.top, 12)
                ForEach(valleys) { valley in
                    SearchResultRow(valley: valley)
                }
                // Figma 02 v2: the source line sits at the end of the list.
                SourceFooter(source: source)
                    .padding(.top, 12)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.immediately)
        // "아래로 당겨 다시 시도" (OfflineBanner): the same search again.
        .refreshable { await viewModel.retry() }
    }
}

extension SearchView {
    private var isFailed: Bool {
        if case .failed = viewModel.state { true } else { false }
    }
}

#Preview {
    NavigationStack {
        SearchView(repository: try! MockValleyRepository())
    }
}
