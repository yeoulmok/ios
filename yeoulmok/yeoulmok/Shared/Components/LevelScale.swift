import SwiftUI

/// 안전 › 주의 › 위험 › 대피 as four segments, with the current level marked
/// (APP-HOME-05 #59, reused by the detail in #63). `.unknown` marks no segment and
/// says "판정 불가" instead, so it never looks like 안전.
struct LevelScale: View {
    let level: ValleyLevel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Starts unmarked and fills in once, when the scale appears.
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                ForEach(LevelScaleSteps.steps, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(fill(for: step))
                        .frame(height: LevelScaleSteps.isCurrent(step, level) && shown ? 10 : 6)
                }
            }
            .frame(height: 10, alignment: .bottom)
            HStack(spacing: 3) {
                ForEach(LevelScaleSteps.steps, id: \.self) { step in
                    Text(step.title)
                        .font(.caption2.weight(LevelScaleSteps.isCurrent(step, level) ? .bold : .regular))
                        .foregroundStyle(LevelScaleSteps.isCurrent(step, level) ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .overlay {
            if level == .unknown {
                Label(ValleyLevel.unknown.title, systemImage: "questionmark.circle")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
            }
        }
        .onAppear {
            if reduceMotion { shown = true } else {
                withAnimation(.spring(duration: 0.6).delay(0.1)) { shown = true }
            }
        }
        // VoiceOver: "단계 위험" or "단계 판정 불가".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("단계 \(level.title)")
        .accessibilityIdentifier("levelScale")
    }

    private func fill(for step: ValleyLevel) -> Color {
        guard level != .unknown else { return Color(.systemGray5) }
        if LevelScaleSteps.isCurrent(step, level) && shown { return step.badgeBackground }
        return step.badgeBackground.opacity(LevelScaleSteps.isPassed(step, level) && shown ? 0.45 : 0.15)
    }
}

/// The order of the scale, kept apart from the view so it can be tested.
nonisolated enum LevelScaleSteps {
    static let steps: [ValleyLevel] = [.safe, .caution, .danger, .evacuate]

    /// Position of `level` on the scale, or `nil` for `.unknown` (not on the scale).
    static func index(of level: ValleyLevel) -> Int? {
        steps.firstIndex(of: level)
    }

    static func isCurrent(_ step: ValleyLevel, _ level: ValleyLevel) -> Bool {
        step == level && index(of: level) != nil
    }

    /// Steps below the current level, drawn a little darker so the scale reads as "how far up".
    static func isPassed(_ step: ValleyLevel, _ level: ValleyLevel) -> Bool {
        guard let current = index(of: level), let position = index(of: step) else { return false }
        return position < current
    }
}

#Preview {
    VStack(spacing: 24) {
        ForEach(ValleyLevel.allCases, id: \.self) { LevelScale(level: $0) }
    }
    .padding()
}
