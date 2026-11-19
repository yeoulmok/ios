import SwiftUI

/// Alert detail (APP-04, Figma 04). Shows whatever `ValleyDetailViewModel.state` says.
/// #10 builds the header (name, badge, summary) and the loading / error handling;
/// Under the summary: observations (#11), actions (#12), then the disclaimer (#13)
/// and the data source at the bottom.
struct ValleyDetailView: View {
    @State private var viewModel: ValleyDetailViewModel

    init(valleyID: Int, repository: any ValleyRepository, cache: ValleyCache? = nil) {
        _viewModel = State(initialValue: ValleyDetailViewModel(valleyID: valleyID, repository: repository, cache: cache))
    }

    var body: some View {
        content
            // Figma 04: the valley name is the large title under "‹ 뒤로".
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            // Figma 04 has no tab bar: the detail covers the whole screen.
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                // APP-DTL-06 (#57): subscribing happens here, not in the search list.
                // Not in Figma; placed like the settings gear on home.
                if case let .loaded(detail) = viewModel.state {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await viewModel.toggleSubscription() }
                        } label: {
                            SubscriptionPill(isSubscribed: detail.isSubscribed)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSubscriptionPending)
                        // VoiceOver: "금대리 계곡 구독중".
                        .accessibilityLabel("\(detail.name) \(SubscriptionPill.title(isSubscribed: detail.isSubscribed))")
                        .accessibilityIdentifier("detail.subscription")
                    }
                }
            }
            .toast(message: $viewModel.toastMessage)
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
                if let asOf = viewModel.offlineAsOf {
                    OfflineBanner(asOf: asOf)
                }
                // #63: level, scale, summary in one card.
                DetailLevelCard(detail: detail)
                Text("지금 수치")
                    .font(.headline)
                    .padding(.top, 8)
                ObservationSection(observations: detail.observations)
                if let explanation = detail.aiExplanation, !explanation.isEmpty {
                    AIExplanationBox(text: explanation, isFallback: detail.isAIFallback)
                        .padding(.top, 4)
                }
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
