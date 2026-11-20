import SwiftUI

/// "🕘 자료 지연" (APP-COM-05, Figma 공통 · 컴포넌트 StaleLabel).
/// Shown when the server sends `stale: true` (observation older than 15 minutes;
/// the server decides this). Data is still shown: being late is not an error.
struct StaleLabel: View {
    static let text = "자료 지연"

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock")
                .accessibilityHidden(true)
            Text(Self.text)
        }
        .font(.caption)
        .foregroundStyle(Theme.stale)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("staleLabel")
    }
}

#Preview {
    HStack {
        Text("관측 21:30").font(.caption).foregroundStyle(.secondary)
        StaleLabel()
    }
    .padding()
}
