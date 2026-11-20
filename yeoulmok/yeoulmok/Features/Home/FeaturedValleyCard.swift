import SwiftUI

/// The one valley shown large on the photo above the subscribed list (APP-HOME-05, #59;
/// public-alert design #71). No card around it: it sits on the photo.
///
///     가장 위험한 구독 계곡
///     위험 예시 계곡
///     예시 지역 · 2.8km
///     [위험]  물이 빠르게 불어날 수 있어요
///     관측 12분 전  🕘 자료 지연
///     [강수 1시간 32.5mm …] [수위 30분 +0.18m …]
///     [지금 할 일 · 즉시 물에서 나오기        ›]
///
/// Values come from the list (always there); thresholds, the summary and the action
/// from the detail, which may still be loading or missing.
struct FeaturedValleyCard: View {
    let featured: FeaturedValley
    let detail: ValleyDetail?

    private var valley: ValleySummary { featured.valley }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(featured.reason.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Text.label)
            Text(valley.name)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.Text.primary)
                .padding(.top, 4)
            Text(placeLine)
                .font(.subheadline)
                .foregroundStyle(Theme.Text.body)
                .padding(.top, 2)
            HStack(alignment: .center, spacing: 10) {
                StatusBadge(level: valley.level, size: .large)
                if let detail {
                    Text(detail.summary)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Text.summary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 16)
            HStack(spacing: 8) {
                Text("관측 \(ValleyFormat.timeAgo(valley.observedAt))")
                    .font(.footnote)
                    .foregroundStyle(Theme.Text.label)
                if valley.isStale {
                    StaleLabel()
                }
            }
            .padding(.top, 10)
            HStack(spacing: 10) {
                MetricTile(
                    title: "강수 1시간",
                    valueText: ValleyFormat.rainfall(valley.rainLastHourMM),
                    thresholdText: threshold(.rainLastHour).map { ValleyFormat.rainfall($0) },
                    value: valley.rainLastHourMM,
                    threshold: threshold(.rainLastHour))
                MetricTile(
                    title: "수위 30분",
                    valueText: ValleyFormat.waterRise(valley.waterRise30MinM),
                    thresholdText: threshold(.waterRise30Min).map { String(format: "%.2fm", $0) },
                    value: valley.waterRise30MinM,
                    threshold: threshold(.waterRise30Min))
            }
            .padding(.top, 18)
            if let action = detail?.actions.first {
                HStack(spacing: 8) {
                    (Text("지금 할 일 · ").foregroundStyle(Theme.Text.label)
                        + Text(action).bold().foregroundStyle(Theme.Text.primary))
                        .font(.subheadline)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.Text.label)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .glassCard(cornerRadius: Theme.Radius.row)
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // One sentence for VoiceOver, like the old card (reason, name, level, summary).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [featured.reason.title, valley.name, placeLine, "단계 \(valley.level.title)"]
        if let detail { parts.append(detail.summary) }
        parts.append("강수 1시간 \(ValleyFormat.rainfall(valley.rainLastHourMM))")
        parts.append("수위 30분 \(ValleyFormat.waterRise(valley.waterRise30MinM))")
        parts.append("관측 \(ValleyFormat.timeAgo(valley.observedAt))")
        if valley.isStale { parts.append(StaleLabel.text) }
        if let action = detail?.actions.first { parts.append("지금 할 일 \(action)") }
        return parts.joined(separator: ", ")
    }

    /// "원주시 판부면 · 11.3km" (distance only when the location is known).
    private var placeLine: String {
        guard let meters = featured.distanceMeters else { return valley.region }
        return "\(valley.region) · \(NearbyValleys.distanceText(meters: meters))"
    }

    private func threshold(_ kind: ObservationKind) -> Double? {
        detail?.observations.first { $0.kind == kind }?.threshold
    }
}

/// One number on a glass tile (#71):
///
///     강수 1시간
///     32.5mm
///     기준 15.0mm
///     [기준의 2.2배]      (only with a value and a threshold)
struct MetricTile: View {
    let title: String
    let valueText: String
    let thresholdText: String?
    let value: Double?
    let threshold: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Text.label)
            Text(valueText)
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.Text.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text("기준 \(thresholdText ?? ValleyFormat.missing)")
                .font(.caption)
                .foregroundStyle(Theme.Text.body)
            if let ratioText = Self.ratioText(value: value, threshold: threshold) {
                Text(ratioText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isOver ? Theme.tagText : Theme.Text.body)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isOver ? Theme.tagFill : Color.white.opacity(0.1), in: Capsule())
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }

    private var isOver: Bool {
        guard let value, let threshold else { return false }
        return value >= threshold
    }

    /// "기준의 2.2배". `nil` without a value, a threshold, or for a value at or below 0
    /// (a falling level is not "0배" of the threshold).
    nonisolated static func ratioText(value: Double?, threshold: Double?) -> String? {
        guard let value, let threshold, threshold > 0, value > 0 else { return nil }
        return String(format: "기준의 %.1f배", value / threshold)
    }
}

#Preview {
    let valleys = try! MockData.valleyList().valleys
    let featured = FeaturedValley.pick(from: valleys.filter(\.isSubscribed), near: nil)!
    ScrollView {
        FeaturedValleyCard(featured: featured, detail: nil).padding()
    }
    .background(PhotoBackdrop(style: .normal))
}
