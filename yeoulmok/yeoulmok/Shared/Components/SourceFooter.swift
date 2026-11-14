import SwiftUI

/// Data source line at the bottom of home, nearby, and detail screens
/// (APP-COM-03, Figma: SourceFooter). Pass the response's `source`, or `nil`
/// while there is no response yet; the required wording is shown either way.
///
///     SourceFooter(source: response?.source)
struct SourceFooter: View {
    let source: String?

    var body: some View {
        Text(SourceText.display(source))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

#Preview("From server") {
    SourceFooter(source: "자료: 기상청")
        .padding()
}

#Preview("No response yet") {
    SourceFooter(source: nil)
        .padding()
}
