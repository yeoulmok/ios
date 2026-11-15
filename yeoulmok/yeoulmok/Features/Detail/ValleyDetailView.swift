import SwiftUI

/// Alert detail (APP-04, Figma 04). Shows whatever `ValleyDetailViewModel.state` says.
/// #10 builds the header (name, badge, summary) and the loading / error handling;
/// #11 observations, #12 actions and #13 the disclaimer go between the summary and the source.
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
            // Temporary until the common error screen (#17).
            VStack {
                Spacer()
                Text(message)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("detail.error")
                Spacer()
                SourceFooter(source: nil)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }

    private func loaded(_ detail: ValleyDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                StatusBadge(level: detail.level, size: .large)
                Text(detail.summary)
                    .font(.title3.weight(.bold))
                    .accessibilityIdentifier("detail.summary")
                // #11 observations, #12 actions, #13 disclaimer go here.
                SourceFooter(source: detail.source)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
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
