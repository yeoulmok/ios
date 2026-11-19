import SwiftUI

/// The large card above the subscribed list (APP-HOME-05, #59). Not in Figma:
///
///     가장 위험한 구독 계곡
///     위험 예시 계곡                 [위험]
///     예시 지역 · 2.8km
///     안전 ─ 주의 ─ [위험] ─ 대피
///     물이 빠르게 불어날 수 있어요
///     강수 1시간  ████████▌|   32.5mm / 기준 15.0mm
///     수위 30분   ██████████| ↑ +0.18m / 기준 0.10m
///     관측 12분 전 · 자료 지연
///
/// Values come from the list (always there); thresholds and the summary from the
/// detail, which may still be loading or missing.
struct FeaturedValleyCard: View {
    let featured: FeaturedValley
    let detail: ValleyDetail?

    private var valley: ValleySummary { featured.valley }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(featured.reason.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(valley.name)
                        .font(.title2.weight(.bold))
                    Text(placeLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(level: valley.level, size: .large)
                    .urgentPulse(valley.level)
            }
            LevelScale(level: valley.level)
            if let detail {
                Text(detail.summary)
                    .font(.headline)
            }
            VStack(spacing: 12) {
                ThresholdGauge(
                    title: "강수 1시간",
                    valueText: ValleyFormat.rainfall(valley.rainLastHourMM),
                    thresholdText: threshold(.rainLastHour).map { ValleyFormat.rainfall($0) },
                    value: valley.rainLastHourMM,
                    threshold: threshold(.rainLastHour))
                ThresholdGauge(
                    title: "수위 30분",
                    valueText: ValleyFormat.waterRise(valley.waterRise30MinM),
                    thresholdText: threshold(.waterRise30Min).map { String(format: "%.2fm", $0) },
                    value: valley.waterRise30MinM,
                    threshold: threshold(.waterRise30Min),
                    change: valley.waterRise30MinM)
            }
            HStack(spacing: 8) {
                Text("관측 \(ValleyFormat.timeAgo(valley.observedAt))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if valley.isStale {
                    StaleLabel()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.6), lineWidth: 1.5))
    }

    /// "원주시 판부면 · 11.3km" (distance only when the location is known).
    private var placeLine: String {
        guard let meters = featured.distanceMeters else { return valley.region }
        return "\(valley.region) · \(NearbyValleys.distanceText(meters: meters))"
    }

    private var tint: Color { valley.level.cardTint }

    private func threshold(_ kind: ObservationKind) -> Double? {
        detail?.observations.first { $0.kind == kind }?.threshold
    }
}

#Preview {
    let valleys = try! MockData.valleyList().valleys
    let featured = FeaturedValley.pick(from: valleys.filter(\.isSubscribed), near: nil)!
    ScrollView {
        FeaturedValleyCard(featured: featured, detail: nil).padding()
    }
}
