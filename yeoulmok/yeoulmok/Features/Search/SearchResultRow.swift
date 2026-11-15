import SwiftUI

/// One valley in the search list (Figma 02 v2). No status badge here:
/// search is for finding and subscribing, the risk is shown on home and detail.
///
///     [금대리 계곡            ]  [구독중]
///     [원주시 판부면          ]
///      └ opens detail           └ toggles subscription (only this reacts)
///
/// The two parts are siblings, not nested, so tapping the button never opens detail.
struct SearchResultRow: View {
    let valley: ValleySummary
    /// The subscription request for this valley is still running.
    var isPending = false
    var onToggleSubscription: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: ValleyRoute(valleyID: valley.id)) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(valley.name)
                            .font(.headline)
                        Text(valley.region)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                // The empty space up to the button opens detail too.
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // VoiceOver: "금대리 계곡, 원주시 판부면".
            .accessibilityElement(children: .combine)

            Button(action: onToggleSubscription) {
                SubscriptionPill(isSubscribed: valley.isSubscribed)
            }
            .buttonStyle(.plain)
            // One request per valley at a time (see SearchViewModel.pendingValleyIDs).
            .disabled(isPending)
            // VoiceOver: "금대리 계곡 구독중", so the button says which valley it is for.
            .accessibilityLabel("\(valley.name) \(SubscriptionPill.title(isSubscribed: valley.isSubscribed))")
            .accessibilityIdentifier("search.subscription.\(valley.id)")
        }
        .padding(.vertical, 12)
    }
}

#Preview("Mock valleys") {
    NavigationStack {
        VStack(spacing: 0) {
            ForEach((try? MockData.valleyList().valleys) ?? []) { valley in
                SearchResultRow(valley: valley)
                Divider()
            }
        }
        .padding()
    }
}
