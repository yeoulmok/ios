import SwiftUI

/// One subscribed valley on the home list (Figma 01 v2 card).
///
///     금대리 계곡                 [위험]
///     원주시 판부면
///     상류 1시간 강수 18.0mm · 하류 수위 +0.22m/30분
///     관측 21:50
struct ValleyCard: View {
    let valley: ValleySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(valley.name)
                    .font(.headline)
                Spacer()
                StatusBadge(level: valley.level)
            }
            Text(valley.region)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(Self.observationText(for: valley))
                .font(.subheadline)
                .padding(.top, 2)
            Text("관측 \(ValleyFormat.observedTime(valley.observedAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
        // VoiceOver reads the whole card at once.
        .accessibilityElement(children: .combine)
    }

    /// "상류 1시간 강수 18.0mm · 하류 수위 +0.22m/30분".
    /// "/30분" is dropped when the rise is missing, so it reads "하류 수위 -".
    static func observationText(for valley: ValleySummary) -> String {
        let rain = ValleyFormat.rainfall(valley.rainLastHourMM)
        let rise = valley.waterRise30MinM == nil
            ? ValleyFormat.missing
            : ValleyFormat.waterRise(valley.waterRise30MinM) + "/30분"
        return "상류 1시간 강수 \(rain) · 하류 수위 \(rise)"
    }
}

#Preview("Mock valleys") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach((try? MockData.valleyList().valleys.sortedForHome()) ?? []) { valley in
                ValleyCard(valley: valley)
            }
        }
        .padding()
    }
}
