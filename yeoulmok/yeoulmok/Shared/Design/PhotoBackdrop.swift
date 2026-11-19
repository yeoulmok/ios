import SwiftUI

/// Full-screen background: the rocky-stream photo fading into the night color (#70).
/// The darker the style, the heavier the situation; nothing on it moves.
struct PhotoBackdrop: View {
    enum Style {
        /// Home, detail, search: the lightest.
        case normal
        /// No subscriptions and other guide screens: one step darker.
        case guide
        /// Cannot reach the server: darker and almost gray.
        case offline
        /// 위험 · 대피 alarm: red tint, the darkest.
        case alarm
        /// No photo (onboarding, settings, nearby map): night color only.
        case plain
    }

    let style: Style

    var body: some View {
        ZStack {
            Theme.night
            if style != .plain {
                GeometryReader { proxy in
                    Image("ValleyPhoto")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .grayscale(grayscale)
                        .brightness(brightness)
                }
                LinearGradient(stops: overlayStops, startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var grayscale: Double {
        switch style {
        case .offline: 0.85
        case .alarm: 0.5
        case .normal, .guide, .plain: 0
        }
    }

    private var brightness: Double {
        switch style {
        case .offline: -0.15
        case .alarm: -0.2
        case .normal, .guide, .plain: 0
        }
    }

    /// Top → bottom overlay; the bottom always ends in the night color so lists stay readable.
    private var overlayStops: [Gradient.Stop] {
        switch style {
        case .normal: Self.nightFade(top: 0.6, middle: 0.4)
        case .guide: Self.nightFade(top: 0.65, middle: 0.58)
        case .offline: Self.nightFade(top: 0.75, middle: 0.7)
        case .alarm: [
            .init(color: Color(red: 120 / 255, green: 24 / 255, blue: 10 / 255).opacity(0.93), location: 0),
            .init(color: Color(red: 64 / 255, green: 14 / 255, blue: 10 / 255).opacity(0.9), location: 0.45),
            .init(color: Color(red: 6 / 255, green: 8 / 255, blue: 12 / 255).opacity(0.98), location: 1),
        ]
        case .plain: []
        }
    }

    private static func nightFade(top: Double, middle: Double) -> [Gradient.Stop] {
        [
            .init(color: Theme.night.opacity(top), location: 0),
            .init(color: Theme.night.opacity(middle), location: 0.4),
            .init(color: Theme.night, location: 1),
        ]
    }
}

#Preview {
    PhotoBackdrop(style: .normal)
}
