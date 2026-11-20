import SwiftUI

/// "행동 요령" on the alert detail screen (APP-DTL-04, Figma 04).
/// The items are the server's `actions`, shown as they are and in order:
/// the app never writes, adds or reorders safety wording.
/// With no actions the whole section, title included, is hidden.
struct ActionList: View {
    static let title = "행동 요령"

    let actions: [String]

    var body: some View {
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(Self.title)
                    .font(.headline)
                    .foregroundStyle(Theme.Text.primary)
                    // VoiceOver can jump here with the headings rotor.
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        // Figma 04 bullet. Not read by VoiceOver.
                        Text("·")
                            .accessibilityHidden(true)
                        Text(action)
                            .foregroundStyle(Theme.Text.summary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("detail.action.\(index)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .listRowSurface(cornerRadius: Theme.Radius.card)
        }
    }
}

#Preview("대피 · 빈 목록") {
    VStack(alignment: .leading, spacing: 24) {
        ActionList(actions: ["즉시 높은 곳으로 대피", "계곡을 건너지 않기", "고립되면 119 신고"])
        ActionList(actions: [])
        Text("(빈 목록은 위에 아무것도 없음)").foregroundStyle(.secondary)
    }
    .padding()
}
