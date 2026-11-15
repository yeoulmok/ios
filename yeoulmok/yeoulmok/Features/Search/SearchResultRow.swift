import SwiftUI

/// One valley in the search list (Figma 02 v2). No status badge here:
/// search is for finding and subscribing, the risk is shown on home and detail.
///
///     금대리 계곡              (구독중)
///     원주시 판부면
struct SearchResultRow: View {
    let valley: ValleySummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(valley.name)
                    .font(.headline)
                Text(valley.region)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            SubscriptionPill(isSubscribed: valley.isSubscribed)
        }
        .padding(.vertical, 12)
        // The empty space between text and pill is tappable too.
        .contentShape(Rectangle())
        // VoiceOver: "금대리 계곡, 원주시 판부면, 구독중".
        .accessibilityElement(children: .combine)
    }
}

#Preview("Mock valleys") {
    VStack(spacing: 0) {
        ForEach((try? MockData.valleyList().valleys) ?? []) { valley in
            SearchResultRow(valley: valley)
            Divider()
        }
    }
    .padding()
}
