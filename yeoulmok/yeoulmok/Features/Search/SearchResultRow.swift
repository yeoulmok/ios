import SwiftUI

/// One valley in the search list (Figma 02 v2). No status badge here: the risk is
/// shown on home and detail. The whole row opens the detail, where the user
/// subscribes (APP-DTL-06, #57 — the subscription button moved there from this row).
///
///     [금대리 계곡                    ›]
///     [원주시 판부면                   ]
struct SearchResultRow: View {
    let valley: ValleySummary

    var body: some View {
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
                // Says "this opens something", now that the row has no button.
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.vertical, 12)
            // The empty space opens detail too.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // VoiceOver: "금대리 계곡, 원주시 판부면".
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("search.row.\(valley.id)")
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
