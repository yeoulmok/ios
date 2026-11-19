import SwiftUI

extension ValleyLevel {
    /// 위험 · 대피: the levels whose badge is gently emphasized (#59, #63).
    nonisolated var isUrgent: Bool { self == .danger || self == .evacuate }

    /// Background and border color of a card about this level. 판정 불가 gets gray,
    /// never the 안전 green.
    var cardTint: Color {
        self == .unknown ? Color(.systemGray) : badgeBackground
    }
}

extension View {
    /// Gently grows and shrinks the view while `level` is 위험 or 대피 (home card #59,
    /// detail #63). Does nothing for other levels or when Reduce Motion is on.
    func urgentPulse(_ level: ValleyLevel) -> some View {
        modifier(UrgentPulse(level: level))
    }
}

private struct UrgentPulse: ViewModifier {
    let level: ValleyLevel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pulsing ? 1.08 : 1)
            .onAppear(perform: update)
            .onChange(of: level) { update() }
            .onChange(of: reduceMotion) { update() }
    }

    private func update() {
        guard level.isUrgent, !reduceMotion else {
            withAnimation(.default) { pulsing = false }
            return
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulsing = true
        }
    }
}
