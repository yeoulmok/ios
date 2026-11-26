import SwiftUI

/// "홈" tab: subscribed valleys (APP-HOME-01, Figma 01 v2).
/// Shows whatever `HomeViewModel.state` says; it holds no logic of its own.
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    /// Called when "+ 계곡 추가" is tapped. `RootView` decides where to go.
    private let onAddValley: () -> Void

    init(repository: any ValleyRepository, cache: ValleyCache? = nil,
         location: (any LocationPermission)? = nil, onAddValley: @escaping () -> Void = {}) {
        // `@State` keeps the same view model while this view stays on screen.
        _viewModel = State(initialValue: HomeViewModel(repository: repository, cache: cache, location: location))
        self.onAddValley = onAddValley
    }

    var body: some View {
        content
            .background { backdrop }
            // The title stays for the back button and VoiceOver, but is not drawn:
            // the photo and the featured valley are the top of the screen (#71).
            .navigationTitle("여울목")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)
                }
                // Feature spec IA: settings from a gear at the top of home (not in Figma 01).
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: SettingsRoute()) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("설정")
                    .accessibilityIdentifier("home.settings")
                }
            }
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
                VStack {
                    offlineBanner
                    HomeEmptyView(source: source, onAddValley: onAddValley)
                }
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

    /// Photo for the list (fades into the dark list area), darker for empty and error.
    @ViewBuilder
    private var backdrop: some View {
        switch viewModel.state {
        case .loading, .loaded: PhotoBackdrop(style: .normal, photoHeight: 600)
        case .empty: PhotoBackdrop(style: .guide)
        case .failed: PhotoBackdrop(style: .offline)
        }
    }

    private func valleyList(_ valleys: [ValleySummary], source: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                offlineBanner
                // APP-HOME-05 (#59): one valley, large, with its numbers, on the photo.
                if let featured = viewModel.featured {
                    NavigationLink(value: ValleyRoute(valleyID: featured.valley.id)) {
                        FeaturedValleyCard(featured: featured, detail: viewModel.featuredDetail)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.featured")
                    .padding(.bottom, 28)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("구독한 계곡")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Text.primary)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(valleys.count)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Text.label)
                        .accessibilityLabel("\(valleys.count)곳")
                    Spacer()
                    AddValleyButton(action: onAddValley)
                }
                ForEach(valleys) { valley in
                    // Only says "open this valley"; RootView decides which screen that is.
                    NavigationLink(value: ValleyRoute(valleyID: valley.id)) {
                        ValleyCard(valley: valley)
                    }
                    // Keep the row's own colors instead of tinting the text blue.
                    .buttonStyle(.plain)
                }
                // Figma: the source line sits at the end of the list and scrolls with it.
                SourceFooter(source: source)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .refreshable { await viewModel.refresh() }
        // No hard top edge here: the photo card starts at the top, so the band showed
        // even before scrolling (#83). Only the settings button sits above it.
    }

    /// Above the last received data when the latest request failed (APP-COM-07).
    @ViewBuilder
    private var offlineBanner: some View {
        if let asOf = viewModel.offlineAsOf {
            OfflineBanner(asOf: asOf)
        }
    }

    /// A full-screen view in a scroll view, so it can be pulled to refresh too (#9).
    private func pullable(@ViewBuilder _ content: () -> some View) -> some View {
        ScrollView {
            content()
                .padding()
                .containerRelativeFrame([.horizontal, .vertical])
        }
        .refreshable { await viewModel.refresh() }
    }
}

// Previews use the bundled mock data, which Release builds leave out (#102).
#if DEBUG
#Preview {
    NavigationStack {
        HomeView(repository: try! MockValleyRepository())
    }
}
#endif
