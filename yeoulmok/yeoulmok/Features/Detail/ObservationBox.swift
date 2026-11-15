import SwiftUI

/// Evidence for the level on the alert detail screen (APP-DTL-03, Figma 04):
/// one bordered box per observation, in the server's order.
struct ObservationSection: View {
    /// Shown when the valley has no linked station. Temporary wording.
    static let emptyMessage = "연결된 관측소가 없어요"

    let observations: [ValleyObservation]

    var body: some View {
        if observations.isEmpty {
            // Saying so, so "no evidence" never looks like "not drawn yet".
            Text(Self.emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("detail.observations.empty")
        } else {
            VStack(spacing: 8) {
                ForEach(Array(observations.enumerated()), id: \.offset) { index, observation in
                    ObservationBox(observation: observation)
                        .accessibilityIdentifier("detail.observation.\(index)")
                }
            }
        }
    }
}

/// One observation: 관측소 · 관측 시각 · 실측값 · 기준값 (text from `ObservationFormat`).
struct ObservationBox: View {
    let observation: ValleyObservation

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
            row("관측소", ObservationFormat.station(observation))
            row("관측 시각", ObservationFormat.time(observation))
            row("실측값", ObservationFormat.value(observation))
            row("기준값", ObservationFormat.threshold(observation))
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.systemGray4))
        }
        // VoiceOver reads the box as one sentence instead of eight separate texts.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ObservationFormat.accessibilityLabel(observation))
    }

    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
        }
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
