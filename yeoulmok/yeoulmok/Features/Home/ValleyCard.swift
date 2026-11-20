import SwiftUI

/// One subscribed valley on the home list: a short row on the dark area (#71).
///
///     [위험]  위험 예시 계곡                 21:40
///             수위 +0.18m · 강수 32.5mm   🕘 자료 지연
///
/// The region is not drawn, but VoiceOver still reads it with the full numbers.
struct ValleyCard: View {
    let valley: ValleySummary

    var body: some View {
        HStack(spacing: 12) {
            StatusBadge(level: valley.level)
            VStack(alignment: .leading, spacing: 2) {
                Text(valley.name)
                    .font(.headline)
                    .foregroundStyle(Theme.Text.primary)
                Text(Self.shortObservationText(for: valley))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Text.body)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(ValleyFormat.observedTime(valley.observedAt))
                    .font(.caption)
                    .foregroundStyle(Theme.Text.label)
                if valley.isStale {
                    StaleLabel()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSurface()
        // VoiceOver reads the whole row at once, name first.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [valley.name, valley.region, valley.level.title, Self.observationText(for: valley),
                     "관측 \(ValleyFormat.observedTime(valley.observedAt))"]
        if valley.isStale { parts.append(StaleLabel.text) }
        return parts.joined(separator: ", ")
    }

    /// "30분 상승 +0.18m · 강수 32.5mm": the row's short line. Missing values read "-".
    static func shortObservationText(for valley: ValleySummary) -> String {
        "30분 상승 \(ValleyFormat.waterRise(valley.waterRise30MinM)) · 강수 \(ValleyFormat.rainfall(valley.rainLastHourMM))"
    }

    /// "상류 1시간 강수 18.0mm · 하류 30분 상승 +0.22m" (VoiceOver). Missing values read "-".
    static func observationText(for valley: ValleySummary) -> String {
        let rain = ValleyFormat.rainfall(valley.rainLastHourMM)
        let rise = ValleyFormat.waterRise(valley.waterRise30MinM)
        return "상류 1시간 강수 \(rain) · 하류 30분 상승 \(rise)"
    }
}

#Preview("Mock valleys") {
    ScrollView {
        VStack(spacing: 8) {
            ForEach((try? MockData.valleyList().valleys.sortedForHome()) ?? []) { valley in
                ValleyCard(valley: valley)
            }
        }
        .padding()
    }
    .background(Theme.night)
}
