import SwiftUI

/// "검색" tab: find valleys by name (APP-SRCH-02, Figma 02 v2 · 02a).
/// Shows whatever `SearchViewModel.state` says; tapping a row opens its detail,
/// tapping its "구독" / "구독중" button toggles the subscription (APP-SRCH-03).
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
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            content
        }
        // Figma 02b: subscribe/unsubscribe failed. Sits right above the tab bar.
        .toast(message: $viewModel.toastMessage)
        .navigationTitle("계곡 검색")
        .task {
            // Runs each time the tab appears, so the list stays current.
            await viewModel.search(query)
        }
    }

    private var searchField: some View {
        TextField("계곡 이름 검색", text: $query)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("search.queryField")
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
            SearchEmptyView(query: query, source: source)
        case let .failed(message):
            // Temporary until the common error screen (#17).
            VStack {
                Spacer()
                Text(message)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func resultList(_ valleys: [ValleySummary], source: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(valleys) { valley in
                    SearchResultRow(
                        valley: valley,
                        isPending: viewModel.pendingValleyIDs.contains(valley.id),
                        onToggleSubscription: {
                            Task { await viewModel.toggleSubscription(valleyID: valley.id) }
                        }
                    )
                    Divider()
                }
                // Figma 02 v2: the source line sits at the end of the list.
                SourceFooter(source: source)
                    .padding(.top, 12)
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

#Preview {
    NavigationStack {
        SearchView(repository: try! MockValleyRepository())
    }
}
