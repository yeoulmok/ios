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
            pullable {
                HomeEmptyView(source: source, onAddValley: onAddValley)
            }
        case let .failed(message):
            pullable {
                VStack {
                    Spacer()
                    ErrorStateView(message: message) { await viewModel.load() }
                    Spacer()
                    SourceFooter(source: nil)
                }
            }
        }
    }

    private func valleyList(_ valleys: [ValleySummary], source: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("구독한 계곡")
                    .font(.headline)
                ForEach(valleys) { valley in
                    // Only says "open this valley"; RootView decides which screen that is.
                    NavigationLink(value: ValleyRoute(valleyID: valley.id)) {
                        ValleyCard(valley: valley)
                    }
                    // Keep the card's own colors instead of tinting the text blue.
                    .buttonStyle(.plain)
                }
                AddValleyButton(action: onAddValley)
                // Figma: the source line sits at the end of the list and scrolls with it.
                SourceFooter(source: source)
                    .padding(.top, 4)
            }
            .padding()
        }
        .refreshable { await viewModel.load() }
    }

    /// A full-screen view in a scroll view, so it can be pulled to refresh too (#9).
    private func pullable(@ViewBuilder _ content: () -> some View) -> some View {
        ScrollView {
            content()
                .padding()
                .containerRelativeFrame([.horizontal, .vertical])
        }
        .refreshable { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        HomeView(repository: try! MockValleyRepository())
    }
}
