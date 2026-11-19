import SwiftUI

/// A bar for one observation against its threshold (APP-HOME-05 #59, reused in #63):
///
///     강수 1시간   ███████████▌|·····  32.5mm / 기준 15.0mm
///
/// The line marks the threshold; the bar turns the warning color past it.
/// A missing value (`null`) draws no bar at all and shows "-", never an empty bar
/// that could read as 0.
struct ThresholdGauge: View {
    let title: String
    let valueText: String
    let thresholdText: String?
    let value: Double?
    let threshold: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(valueText)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                if let thresholdText {
                    Text("/ 기준 \(thresholdText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            bar
        }
        .onAppear {
            if reduceMotion { shown = true } else {
                withAnimation(.easeOut(duration: 0.8).delay(0.15)) { shown = true }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var bar: some View {
        if let fill = GaugeMath.fill(value: value, threshold: threshold) {
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(GaugeMath.isOver(value: value, threshold: threshold)
                              ? ValleyLevel.danger.badgeBackground : Color.primary.opacity(0.55))
                        .frame(width: width * (shown ? fill : 0))
                    // The threshold line.
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 2, height: 14)
                        .offset(x: width * GaugeMath.thresholdPosition - 1)
                }
            }
            .frame(height: 10)
        } else {
            // No value or no threshold: say so instead of drawing an empty bar.
            Capsule()
                .strokeBorder(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(height: 10)
        }
    }
}

/// The numbers behind `ThresholdGauge`, kept apart from the view so they can be tested.
nonisolated enum GaugeMath {
    /// The bar shows up to 1.5× the threshold, so going past it is visible.
    static let range = 1.5
    /// Where the threshold line sits on the bar (0…1).
    static var thresholdPosition: Double { 1 / range }

    /// How much of the bar to fill (0…1), or `nil` when there is nothing to draw:
    /// no value, or no usable threshold. Falling water (a negative rise) fills nothing.
    static func fill(value: Double?, threshold: Double?) -> Double? {
        guard let value, let threshold, threshold > 0 else { return nil }
        return min(max(value / (threshold * range), 0), 1)
    }

    /// The value reached the threshold.
    static func isOver(value: Double?, threshold: Double?) -> Bool {
        guard let value, let threshold, threshold > 0 else { return false }
        return value >= threshold
    }
}

#Preview {
    VStack(spacing: 20) {
        ThresholdGauge(title: "강수 1시간", valueText: "32.5mm", thresholdText: "15.0mm", value: 32.5, threshold: 15)
        ThresholdGauge(title: "수위 30분", valueText: "+0.06m", thresholdText: "0.10m", value: 0.06, threshold: 0.1)
        ThresholdGauge(title: "수위 30분", valueText: "-", thresholdText: nil, value: nil, threshold: 0.1)
    }
    .padding()
}
