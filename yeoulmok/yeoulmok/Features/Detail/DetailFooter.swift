import SwiftUI

/// The disclaimer on the alert detail screen (APP-DTL-05). It is legally required,
/// so it must never be blank.
nonisolated enum DisclaimerText {
    /// Used when the server sends a blank `disclaimer`. Same wording as the issue
    /// and the server's current text.
    static let fallback = "판단 보조 정보이며 공식 재난경보를 대체하지 않습니다."

    /// Text to show for the server's `disclaimer` (`nil` when there is no response).
    static func display(_ disclaimer: String?) -> String {
        let text = disclaimer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? fallback : text
    }
}

/// Bottom of the alert detail screen (Figma 04): disclaimer, then data source.
/// Both are legally required and always shown, with fallbacks when the server
/// sends nothing usable.
struct DetailFooter: View {
    let disclaimer: String?
    let source: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(DisclaimerText.display(disclaimer))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("detail.disclaimer")
            SourceFooter(source: source)
        }
    }
}

#Preview("From server · no response") {
    VStack(alignment: .leading, spacing: 24) {
        DetailFooter(disclaimer: "판단 보조 정보이며 공식 재난경보를 대체하지 않습니다.", source: "자료: 기상청")
        DetailFooter(disclaimer: nil, source: nil)
    }
    .padding()
}
