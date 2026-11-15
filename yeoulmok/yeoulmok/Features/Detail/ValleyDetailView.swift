import SwiftUI

/// Alert detail (APP-04, Figma 04). Shows whatever `ValleyDetailViewModel.state` says.
/// #10 builds the header (name, badge, summary) and the loading / error handling;
/// Under the summary: observations (#11), actions (#12), then the disclaimer (#13)
/// and the data source at the bottom.
struct ValleyDetailView: View {
    @State private var viewModel: ValleyDetailViewModel

    init(valleyID: Int, repository: any ValleyRepository) {
        _viewModel = State(initialValue: ValleyDetailViewModel(valleyID: valleyID, repository: repository))
    }

    var body: some View {
        content
            // Figma 04: the valley name is the large title under "‹ 뒤로".
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            // Figma 04 has no tab bar: the detail covers the whole screen.
            .toolbar(.hidden, for: .tabBar)
            .task {
                await viewModel.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            // Feature spec 3-1: keep the screen frame (back button), show a spinner.
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .loaded(detail):
            loaded(detail)
        case let .failed(message):
            // Common error screen (#17). Can also be pulled to retry.
            ScrollView {
                VStack {
                    Spacer()
                    ErrorStateView(message: message) { await viewModel.load() }
                    Spacer()
                    // The disclaimer and source stay even when the detail failed to load.
                    DetailFooter(disclaimer: nil, source: nil)
                }
                .padding()
                .containerRelativeFrame([.horizontal, .vertical])
            }
            .refreshable { await viewModel.load() }
        }
    }

    private func loaded(_ detail: ValleyDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    StatusBadge(level: detail.level, size: .large)
                    // Next to the level it qualifies: the judgment uses late data.
                    if detail.isStale {
                        StaleLabel()
                    }
                }
                Text(detail.summary)
                    .font(.title3.weight(.bold))
                    .accessibilityIdentifier("detail.summary")
                ObservationSection(observations: detail.observations)
                    .padding(.top, 4)
                ActionList(actions: detail.actions)
                    .padding(.top, 8)
                DetailFooter(disclaimer: detail.disclaimer, source: detail.source)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        // Keeps the detail while reloading; a failed refresh keeps it too (view model).
        .refreshable { await viewModel.load() }
    }

    private var title: String {
        if case let .loaded(detail) = viewModel.state { detail.name } else { "" }
    }
}

#Preview("주의") {
    NavigationStack {
        ValleyDetailView(valleyID: 1, repository: try! MockValleyRepository())
    }
}

#Preview("판정 불가") {
    NavigationStack {
        ValleyDetailView(valleyID: 2, repository: try! MockValleyRepository())
    }
}

#Preview("없는 계곡") {
    NavigationStack {
        ValleyDetailView(valleyID: 99, repository: try! MockValleyRepository())
    }
}
