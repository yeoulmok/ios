import SwiftUI

/// "홈" tab: subscribed valleys (APP-HOME-01, Figma 01 v2).
/// Shows whatever `HomeViewModel.state` says; it holds no logic of its own.
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    /// Called when "+ 계곡 추가" is tapped. `RootView` decides where to go.
    private let onAddValley: () -> Void

    init(repository: any ValleyRepository, onAddValley: @escaping () -> Void = {}) {
        // `@State` keeps the same view model while this view stays on screen.
        _viewModel = State(initialValue: HomeViewModel(repository: repository))
        self.onAddValley = onAddValley
    }

    var body: some View {
        content
            .navigationTitle("여울목")
            .task {
                await viewModel.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            // Feature spec 3-1: keep the screen frame (title, tab bar), show a spinner.
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .loaded(valleys, source):
            valleyList(valleys, source: source)
        case let .empty(source):
            // Temporary until the empty state screen (#18).
            placeholder("구독한 계곡이 없어요", source: source)
        case let .failed(message):
            // Temporary until the common error screen (#17).
            placeholder(message, source: nil)
        }
    }

    private func valleyList(_ valleys: [ValleySummary], source: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("구독한 계곡")
                    .font(.headline)
                ForEach(valleys) { valley in
                    ValleyCard(valley: valley)
                }
                AddValleyButton(action: onAddValley)
                // Figma: the source line sits at the end of the list and scrolls with it.
                SourceFooter(source: source)
                    .padding(.top, 4)
            }
            .padding()
        }
    }

    private func placeholder(_ message: String, source: String?) -> some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundStyle(.secondary)
            Spacer()
            SourceFooter(source: source)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        HomeView(repository: try! MockValleyRepository())
    }
}
