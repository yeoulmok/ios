import SwiftUI

/// Top of the alert detail, drawn on the photo (APP-DTL-07, #63; design #71):
///
///     금대리 계곡
///     관측 12분 전  🕘 자료 지연
///     [주의]  상류에 비가 많이 오고 있어요
///     안전 ─ [주의] ─ 위험 ─ 대피
///     ✦ AI 추정으로 판정했어요            (only when `estimated`)
struct DetailLevelCard: View {
    /// Temporary wording until QA: the level came from an AI estimate (API spec v0.4).
    static let estimatedText = "AI 추정으로 판정했어요"

    let detail: ValleyDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The navigation bar does not draw the name (#71), so it is the header here.
            Text(detail.name)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.Text.primary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                Text("관측 \(ValleyFormat.timeAgo(Self.latestObservation(in: detail)))")
                    .font(.footnote)
                    .foregroundStyle(Theme.Text.label)
                    .accessibilityIdentifier("detail.observedAgo")
                // Next to the time it qualifies: the judgment uses late data.
                if detail.isStale {
                    StaleLabel()
                }
            }
            .padding(.top, 4)
            HStack(alignment: .center, spacing: 10) {
                StatusBadge(level: detail.level, size: .large)
                Text(detail.summary)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.Text.summary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("detail.summary")
            }
            .padding(.top, 18)
            LevelScale(level: detail.level)
                .padding(.top, 14)
            if detail.isEstimated {
                Label(Self.estimatedText, systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Text.body)
                    .accessibilityIdentifier("detail.estimated")
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The newest measured observation time (AI estimates are not observations).
    /// `nil` when nothing was observed: shown as "-".
    nonisolated static func latestObservation(in detail: ValleyDetail) -> Date? {
        detail.observations.filter { !$0.isEstimated }.compactMap(\.observedAt).max()
    }
}

// Previews use the bundled mock data, which Release builds leave out (#102).
#if DEBUG
#Preview {
    let details = try! MockData.valleyDetails(bundle: .main)
    ScrollView {
        VStack(spacing: 32) {
            ForEach(details) { DetailLevelCard(detail: $0) }
        }
        .padding()
    }
    .background(PhotoBackdrop(style: .normal))
}
#endif
