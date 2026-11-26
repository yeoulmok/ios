import SwiftUI

/// Alert detail (APP-04, Figma 04). Shows whatever `ValleyDetailViewModel.state` says.
/// #10 builds the header (name, badge, summary) and the loading / error handling;
/// Under the summary: observations (#11), actions (#12), then the disclaimer (#13)
/// and the data source at the bottom.
struct ValleyDetailView: View {
    @State private var viewModel: ValleyDetailViewModel
    /// "AI에게 물어보기" (#64). Kept while the detail reloads.
    @State private var askModel: AskViewModel

    init(valleyID: Int, repository: any ValleyRepository, cache: ValleyCache? = nil) {
        _viewModel = State(initialValue: ValleyDetailViewModel(valleyID: valleyID, repository: repository, cache: cache))
        _askModel = State(initialValue: AskViewModel(valleyID: valleyID, repository: repository))
    }

    var body: some View {
        content
            .background { PhotoBackdrop(style: isFailed ? .offline : .normal, photoHeight: isFailed ? nil : 520) }
            // The name is drawn on the photo (#71); the title stays for VoiceOver and tests.
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            // Figma 04 has no tab bar: the detail covers the whole screen.
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)
                }
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
            .refreshable { await viewModel.refresh() }
        }
    }

    private func loaded(_ detail: ValleyDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let asOf = viewModel.offlineAsOf {
                    OfflineBanner(asOf: asOf)
                }
                // #63: name, level, summary on the photo (#71).
                DetailLevelCard(detail: detail)
                    .padding(.top, 8)
                Text("지금 수치")
                    .font(.headline)
                    .foregroundStyle(Theme.Text.primary)
                    .padding(.top, 24)
                ObservationSection(observations: detail.observations, rainLast24hMM: detail.rainLast24hMM)
                // APP-DTL-09 (#90): only when the server sent a history.
                if let history = viewModel.history {
                    HistoryCard(history: history)
                        .padding(.top, 4)
                }
                if let explanation = detail.aiExplanation, !explanation.isEmpty {
                    AIExplanationBox(text: explanation, isFallback: detail.isAIFallback)
                        .padding(.top, 4)
                }
                ActionList(actions: detail.actions)
                    .padding(.top, 8)
                AskSection(model: askModel)
                    .padding(.top, 8)
                DetailFooter(disclaimer: detail.disclaimer, source: detail.source)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .topBarScrollEdge()
        // Keeps the detail while reloading; a failed refresh keeps it too (view model).
        .refreshable { await viewModel.refresh() }
    }

    private var isFailed: Bool {
        if case .failed = viewModel.state { true } else { false }
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
