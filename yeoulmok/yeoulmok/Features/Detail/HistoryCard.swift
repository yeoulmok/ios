import Charts
import SwiftUI

/// "최근 3시간" on the alert detail (APP-DTL-09, #90), from `GET /valleys/{id}/history`:
///
///     최근 3시간                       10분 간격
///     강수 1시간  ▁▁▁▂▃▅▆█   - - 주의 15 - - 위험 25
///     수위        ────╱‾‾‾
///
/// Rain is drawn as bars with the level limits as dashed lines in the level colors.
/// Water is the height at the gauge (easier to read than the 30-minute change), and
/// is left out for a valley without a gauge. A row with no value leaves a gap,
/// never a 0. The card is hidden when there is no history (`ValleyDetailView`).
struct HistoryCard: View {
    /// Temporary wording until QA.
    static let title = "최근 3시간"
    static let rainTitle = "강수 1시간"
    static let waterTitle = "수위"

    let history: ValleyHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(Self.title).font(.headline)
                Spacer()
                Text("\(history.stepMinutes)분 간격")
                    .font(.caption)
                    .foregroundStyle(Theme.Text.label)
            }
            rainChart
            if HistoryChartMath.hasWater(history) {
                waterChart
            }
        }
        .foregroundStyle(Theme.Text.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(HistoryChartMath.accessibilityText(history))
        .accessibilityIdentifier("detail.history")
    }

    // MARK: Rain

    private var rainChart: some View {
        let rain = HistoryChartMath.values(history.points, \.rainLastHourMM)
        let steps = history.thresholds.rainLastHour?.steps ?? []
        let top = HistoryChartMath.scaleTop(maxValue: rain.map(\.value).max() ?? 0, steps: steps)
        return VStack(alignment: .leading, spacing: 6) {
            Text(Self.rainTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Text.label)
            Chart {
                ForEach(rain, id: \.at) { item in
                    BarMark(x: .value("시각", item.at, unit: .minute), y: .value("강수", item.value), width: 6)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                ForEach(steps.filter { $0.value <= top }, id: \.level) { step in
                    RuleMark(y: .value("기준", step.value))
                        .foregroundStyle(step.level.badgeBackground)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .annotation(position: .top, alignment: .leading, spacing: 2) {
                            Text("\(step.level.title) \(ValleyFormat.rainfall(step.value))")
                                .font(.caption2)
                                .foregroundStyle(step.level.badgeBackground)
                        }
                }
            }
            .chartYScale(domain: 0...top)
            .chartXScale(domain: HistoryChartMath.timeDomain(history))
            .chartXAxis { timeAxis }
            .environment(\.calendar, HistoryChartMath.calendar)
            .environment(\.timeZone, ServerDate.timeZone)
            .chartYAxis { valueAxis(unit: "mm") }
            .frame(height: 140)
        }
    }

    // MARK: Water

    private var waterChart: some View {
        let segments = HistoryChartMath.segments(history.points, \.waterLevelM)
        let domain = HistoryChartMath.waterDomain(history)
        return VStack(alignment: .leading, spacing: 6) {
            Text(Self.waterTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Text.label)
            Chart {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    ForEach(segment, id: \.at) { item in
                        LineMark(x: .value("시각", item.at, unit: .minute), y: .value("수위", item.value),
                                 series: .value("구간", index))
                            .foregroundStyle(Theme.waterBlue)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                    // A lone value between gaps still shows as a dot.
                    if segment.count == 1, let only = segment.first {
                        PointMark(x: .value("시각", only.at, unit: .minute), y: .value("수위", only.value))
                            .foregroundStyle(Theme.waterBlue)
                    }
                }
            }
            .chartYScale(domain: domain)
            .chartXScale(domain: HistoryChartMath.timeDomain(history))
            .chartXAxis { timeAxis }
            .environment(\.calendar, HistoryChartMath.calendar)
            .environment(\.timeZone, ServerDate.timeZone)
            .chartYAxis { valueAxis(unit: "m") }
            .frame(height: 110)
        }
    }

    // MARK: Axes

    private var timeAxis: some AxisContent {
        AxisMarks(values: .stride(by: .hour)) { value in
            AxisGridLine().foregroundStyle(Color.white.opacity(0.12))
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(HistoryChartMath.timeLabel(date)).foregroundStyle(Theme.Text.label)
                }
            }
        }
    }

    private func valueAxis(unit: String) -> some AxisContent {
        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
            AxisGridLine().foregroundStyle(Color.white.opacity(0.12))
            AxisValueLabel().foregroundStyle(Theme.Text.label)
        }
    }
}

/// The numbers behind `HistoryCard`, apart from the view so they can be tested.
nonisolated enum HistoryChartMath {
    struct Item: Equatable {
        let at: Date
        let value: Double
    }

    /// Times are Korean time on every device (like the rest of the app).
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = ServerDate.timeZone
        return calendar
    }()

    /// "21:00", in Korean time.
    static func timeLabel(_ date: Date) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// Rows that have the value; rows without one are skipped (a gap, not 0).
    static func values(_ points: [HistoryPoint], _ key: KeyPath<HistoryPoint, Double?>) -> [Item] {
        points.compactMap { point in point[keyPath: key].map { Item(at: point.at, value: $0) } }
    }

    /// Runs of rows that have the value, split where a value is missing, so the line
    /// breaks at the gap instead of jumping across it.
    static func segments(_ points: [HistoryPoint], _ key: KeyPath<HistoryPoint, Double?>) -> [[Item]] {
        var runs: [[Item]] = []
        var current: [Item] = []
        for point in points {
            if let value = point[keyPath: key] {
                current.append(Item(at: point.at, value: value))
            } else if !current.isEmpty {
                runs.append(current)
                current = []
            }
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }

    /// Top of the rain scale: just above the next limit the rain has not reached, so
    /// that limit is in view, and higher limits (far above) do not squash the bars.
    /// Past every limit: a bit above the highest bar.
    static func scaleTop(maxValue: Double, steps: [(level: ValleyLevel, value: Double)]) -> Double {
        if let next = steps.map(\.value).sorted().first(where: { $0 > maxValue }) {
            return next * 1.15
        }
        return max(maxValue * 1.15, 1)
    }

    /// Water scale: the values with some room around them (at least 0.2 m tall), so a
    /// steady level reads as flat, not as noise.
    static func waterDomain(_ history: ValleyHistory) -> ClosedRange<Double> {
        let levels = values(history.points, \.waterLevelM).map(\.value)
        guard let low = levels.min(), let high = levels.max() else { return 0...1 }
        let middle = (low + high) / 2
        let half = max((high - low) / 2 + 0.05, 0.1)
        return max(0, middle - half)...(middle + half)
    }

    /// The whole window, so every chart lines up even when the first rows are missing.
    static func timeDomain(_ history: ValleyHistory) -> ClosedRange<Date> {
        guard let first = history.points.first?.at, let last = history.points.last?.at, first < last else {
            let now = history.updatedAt
            return now.addingTimeInterval(-Double(history.hours) * 3600)...now
        }
        return first...last
    }

    /// The water chart only makes sense with a gauge and at least one value.
    static func hasWater(_ history: ValleyHistory) -> Bool {
        history.hasWater && !values(history.points, \.waterLevelM).isEmpty
    }

    /// VoiceOver: "최근 3시간, 강수 1시간 0.0mm에서 18.0mm, 수위 0.21m에서 0.34m".
    /// Uses the first and last known values; a measurement with none says "-".
    static func accessibilityText(_ history: ValleyHistory) -> String {
        var parts = [HistoryCard.title]
        parts.append("\(HistoryCard.rainTitle) \(range(values(history.points, \.rainLastHourMM), ValleyFormat.rainfall))")
        if history.hasWater {
            parts.append("\(HistoryCard.waterTitle) \(range(values(history.points, \.waterLevelM)) { String(format: "%.2fm", $0 ?? 0) })")
        }
        return parts.joined(separator: ", ")
    }

    private static func range(_ items: [Item], _ format: (Double?) -> String) -> String {
        guard let first = items.first, let last = items.last else { return ValleyFormat.missing }
        return "\(format(first.value))에서 \(format(last.value))"
    }
}

#Preview {
    let histories = try! MockData.valleyHistories(bundle: .main)
    ScrollView {
        VStack(spacing: 16) {
            ForEach(histories, id: \.valleyID) { HistoryCard(history: $0) }
        }
        .padding()
    }
    .background(Theme.night)
}
