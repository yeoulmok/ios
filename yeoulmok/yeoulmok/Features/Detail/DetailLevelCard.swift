import SwiftUI

/// Top of the alert detail (APP-DTL-07, #63). Not in Figma:
///
///     [주의] 🕘 자료 지연                 관측 12분 전
///     안전 ─ [주의] ─ 위험 ─ 대피
///     상류에 비가 많이 오고 있어요
///     ✦ AI 추정으로 판정했어요            (only when `estimated`)
struct DetailLevelCard: View {
    /// Temporary wording until QA: the level came from an AI estimate (API spec v0.4).
    static let estimatedText = "AI 추정으로 판정했어요"

    let detail: ValleyDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                StatusBadge(level: detail.level, size: .large)
                    .urgentPulse(detail.level)
                // Next to the level it qualifies: the judgment uses late data.
                if detail.isStale {
                    StaleLabel()
                }
                Spacer(minLength: 0)
                Text("관측 \(ValleyFormat.timeAgo(Self.latestObservation(in: detail)))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("detail.observedAgo")
            }
            LevelScale(level: detail.level)
            Text(detail.summary)
                .font(.title3.weight(.bold))
                .accessibilityIdentifier("detail.summary")
            if detail.isEstimated {
                Label(Self.estimatedText, systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("detail.estimated")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(detail.level.cardTint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(detail.level.cardTint.opacity(0.6), lineWidth: 1.5))
    }

    /// The newest measured observation time (AI estimates are not observations).
    /// `nil` when nothing was observed: shown as "-".
    nonisolated static func latestObservation(in detail: ValleyDetail) -> Date? {
        detail.observations.filter { !$0.isEstimated }.compactMap(\.observedAt).max()
    }
}

#Preview {
    let details = try! MockData.valleyDetails(bundle: .main)
    ScrollView {
        VStack(spacing: 16) {
            ForEach(details) { DetailLevelCard(detail: $0) }
        }
        .padding()
    }
}
