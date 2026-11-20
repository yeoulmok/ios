import SwiftUI

/// The design set's fixed values (#70). Claude Design canvas › "디자인 시스템" board.
/// Screens use these instead of writing colors and opacities by hand,
/// so the whole app stays one public-alert tone.
enum Theme {
    /// Night background behind every screen and below the photo.
    static let night = Color(hex: 0x0A1018)
    /// Institution navy: logo and icon background.
    static let navy = Color(hex: 0x0B2545)
    /// Water blue: logo waves.
    static let waterBlue = Color(hex: 0x7FB8E8)
    /// Links on the dark background.
    static let link = Color(hex: 0x9CC3FF)
    /// "기준의 ○배" style interpretation tag: text and fill.
    static let tagText = Color(hex: 0xFFD2B0)
    static let tagFill = Color(hex: 0xDD7D33).opacity(0.32)
    /// Data-delay text (stale observation).
    static let stale = Color(hex: 0xFFD58A)

    /// White text in five lightness steps; the step shows how important the text is.
    enum Text {
        /// Numbers and titles.
        static let primary = Color.white
        /// One-line summaries.
        static let summary = Color.white.opacity(0.92)
        /// Body text.
        static let body = Color.white.opacity(0.7)
        /// Labels and section headers.
        static let label = Color.white.opacity(0.55)
        /// Sources and fine print.
        static let source = Color.white.opacity(0.45)
    }

    /// Corner radii: list rows, cards and buttons, large cards.
    enum Radius {
        static let row: CGFloat = 14
        static let card: CGFloat = 16
        static let large: CGFloat = 20
    }
}

extension Color {
    /// `Color(hex: 0x0A1018)`, written like a hex code from a design tool.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Glass card: frosted, see-through surface for cards on top of the photo.
private struct GlassCard: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape.fill(.ultraThinMaterial)
                    .overlay(shape.fill(Color.white.opacity(0.14)))
            }
            .overlay(shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
            .shadow(color: .black.opacity(0.28), radius: 12, y: 8)
    }
}

/// List row: a faint surface for rows in the dark area below the photo.
private struct ListRowSurface: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(shape.fill(Color.white.opacity(0.06)))
            .overlay(shape.strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
    }
}

extension View {
    /// Frosted glass card for content on top of the photo.
    func glassCard(cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    /// Faint row surface for lists on the dark background.
    func listRowSurface(cornerRadius: CGFloat = Theme.Radius.row) -> some View {
        modifier(ListRowSurface(cornerRadius: cornerRadius))
    }
}

/// Main action: solid white with dark text, the one thing to press (#72).
private struct PrimaryButtonLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body.weight(.bold))
            .foregroundStyle(Color(hex: 0x101828))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 12, y: 10)
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

/// Second action next to a primary one: glass with light text (#72).
private struct SecondaryButtonLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundStyle(Color.white.opacity(0.85))
            .frame(maxWidth: .infinity, minHeight: 50)
            .glassCard()
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

extension View {
    /// Label look for the screen's main button (use with `.buttonStyle(.plain)`).
    func primaryButtonLabel() -> some View { modifier(PrimaryButtonLabel()) }

    /// Label look for a second, quieter button (use with `.buttonStyle(.plain)`).
    func secondaryButtonLabel() -> some View { modifier(SecondaryButtonLabel()) }
}

extension View {
    /// Content scrolling under the top bar is blurred out, so it never shows through the
    /// back · subscribe buttons (#78). iOS 26's default soft edge is too faint over the
    /// dark photo; iOS 17–18 show the bar's own background when scrolled.
    @ViewBuilder
    func topBarScrollEdge() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.hard, for: .top)
        } else {
            self
        }
    }
}
