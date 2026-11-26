import SwiftUI

/// One valley in the search list (Figma 02 v2; design #71). No status badge here: the
/// risk is shown on home and detail. The whole row opens the detail, where the user
/// subscribes (APP-DTL-06, #57). "구독중" only says the state; it is not a button.
///
///     [금대리 계곡             구독중  ›]
///     [원주시 판부면                    ]
struct SearchResultRow: View {
    let valley: ValleySummary

    var body: some View {
        NavigationLink(value: ValleyRoute(valleyID: valley.id)) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(valley.name)
                        .font(.headline)
                        .foregroundStyle(Theme.Text.primary)
                    Text(valley.region)
                        .font(.footnote)
                        .foregroundStyle(Theme.Text.body)
                }
                Spacer(minLength: 8)
                if valley.isSubscribed {
                    Text(SubscriptionPill.title(isSubscribed: true))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Text.summary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }
                // Says "this opens something", now that the row has no button.
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Text.source)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .listRowSurface()
            // The empty space opens detail too.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // VoiceOver: "금대리 계곡, 원주시 판부면".
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("search.row.\(valley.id)")
    }
}

// Previews use the bundled mock data, which Release builds leave out (#102).
#if DEBUG
#Preview("Mock valleys") {
    NavigationStack {
        VStack(spacing: 8) {
            ForEach((try? MockData.valleyList().valleys) ?? []) { valley in
                SearchResultRow(valley: valley)
            }
        }
        .padding()
        .background(Theme.night)
    }
}
#endif
