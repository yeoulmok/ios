import SwiftUI

/// Evidence for the level on the alert detail screen (APP-DTL-03, Figma 04):
/// one bordered box per observation, in the server's order.
struct ObservationSection: View {
    /// Shown when the valley has no linked station. Temporary wording.
    static let emptyMessage = "연결된 관측소가 없어요"

    let observations: [ValleyObservation]
    /// Rain over 24 hours (API spec v0.6), added under the 1-hour rain card. `nil`: no line.
    var rainLast24hMM: Double?

    var body: some View {
        if observations.isEmpty {
            // Saying so, so "no evidence" never looks like "not drawn yet".
            Text(Self.emptyMessage)
                .font(.subheadline)
                .foregroundStyle(Theme.Text.body)
                .accessibilityIdentifier("detail.observations.empty")
        } else {
            VStack(spacing: 8) {
                ForEach(Array(observations.enumerated()), id: \.offset) { index, observation in
                    ObservationBox(observation: observation,
                                   rainLast24hMM: observation.kind == .rainLastHour ? rainLast24hMM : nil)
                        .accessibilityIdentifier("detail.observation.\(index)")
                }
            }
        }
    }
}

/// One observation as a gauge card (#63; before it was the Figma 04 four-line table):
///
///     강수 1시간                      18.0mm / 기준 15.0mm
///     ███████████▌|·····
///     원주 신림(AWS) · 21:50
///
/// AI estimates carry an "AI 추정" tag and say they were estimated. A missing value
/// draws a dashed outline instead of a bar, with the reason in the small line.
/// VoiceOver still reads the same sentence as before (`ObservationFormat.accessibilityLabel`).
struct ObservationBox: View {
    /// Temporary wording until QA.
    static let estimatedTag = "AI 추정"

    let observation: ValleyObservation
    /// Shown as "24시간 강수 31.0mm" under the gauge (#90). `nil`: no line.
    var rainLast24hMM: Double?

    /// "24시간 강수 31.0mm". Temporary wording until QA.
    static func rain24hText(_ mm: Double) -> String { "24시간 강수 \(ValleyFormat.rainfall(mm))" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if observation.isEstimated {
                Label(Self.estimatedTag, systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.14), in: Capsule())
            }
            ThresholdGauge(
                title: ObservationFormat.title(observation),
                valueText: ObservationFormat.shortValue(observation),
                thresholdText: ObservationFormat.shortThreshold(observation),
                value: observation.value,
                threshold: observation.threshold,
                change: observation.kind == .rainLastHour ? nil : observation.value,
                stages: observation.thresholds?.steps ?? [])
            if let rainLast24hMM {
                Text(Self.rain24hText(rainLast24hMM))
                    .font(.footnote)
                    .foregroundStyle(Theme.Text.body)
            }
            Text(ObservationFormat.footnote(observation))
                .font(.caption)
                .foregroundStyle(Theme.Text.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
        // AI estimates keep a dashed outline, so they never look measured.
        .overlay {
            if observation.isEstimated {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
        // VoiceOver reads the card as one sentence, the same as the old table.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ObservationFormat.accessibilityLabel(observation))
        // Read after the sentence above; the sentence itself stays as before (#11).
        .accessibilityValue(rainLast24hMM.map(Self.rain24hText) ?? "")
    }
}

/// AI-written reason for the level (APP-DTL-02, in #63). Only when the server sends one.
struct AIExplanationBox: View {
    /// Temporary wording until QA.
    static let title = "AI 설명"
    static let fallbackNote = "AI 대신 정해진 문구예요"

    let text: String
    let isFallback: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(Self.title, systemImage: "sparkles")
                .font(.headline)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.Text.summary)
            if isFallback {
                Text(Self.fallbackNote)
                    .font(.caption)
                    .foregroundStyle(Theme.Text.label)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .listRowSurface(cornerRadius: Theme.Radius.card)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("detail.aiExplanation")
    }
}

#Preview("주의 · 판정 불가") {
    let details = try! MockData.valleyDetails(bundle: .main)
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ObservationSection(observations: details[0].observations)
            ObservationSection(observations: details[1].observations)
            ObservationSection(observations: [])
        }
        .padding()
    }
}
