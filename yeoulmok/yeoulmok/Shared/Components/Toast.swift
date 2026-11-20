import SwiftUI

/// Short message above the tab bar (Figma 02b, `앱 / 공통 · 컴포넌트` Toast).
/// The screen stays as it is; the toast hides by itself after `duration`.
struct Toast: View {
    /// Figma 02b memo: "2~3초".
    static let duration: Duration = .seconds(2.5)

    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.Text.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            // Glass like every card (#72); stands out over the dark screens.
            .glassCard(cornerRadius: Theme.Radius.row)
            .accessibilityIdentifier("toast")
    }
}

extension View {
    /// Shows `message` as a toast at the bottom of this view, then sets it back to `nil`.
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Toast(message: message)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
            // Restarts whenever the message changes; the old timer is cancelled.
            .task(id: message) {
                guard let shown = message else { return }
                // VoiceOver users hear the message even though focus does not move.
                AccessibilityNotification.Announcement(shown).post()
                do {
                    try await Task.sleep(for: Toast.duration)
                } catch {
                    return  // Cancelled: a newer message took over, leave it alone.
                }
                message = nil
            }
    }
}

#Preview {
    Color.clear
        .toast(message: .constant("구독을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요."))
}
