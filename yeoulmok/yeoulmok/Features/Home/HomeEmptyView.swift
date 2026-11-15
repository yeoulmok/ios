import SwiftUI

/// Home with no subscribed valleys (APP-HOME-04, Figma 01b).
/// Feature spec 3-1 empty state: icon + message + next-action button.
struct HomeEmptyView: View {
    static let title = "구독한 계곡이 없어요"
    static let message = "관심 있는 계곡을 추가하면\n위험할 때 알림을 보내드려요."
    static let buttonTitle = "계곡 추가하기"

    let source: String
    /// Same as "+ 계곡 추가": RootView switches to the search tab.
    let onAddValley: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "water.waves")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 56, height: 56)
                .background(Color(.systemGray6), in: Circle())
                .accessibilityHidden(true)
            Text(Self.title)
                .font(.headline)
                .padding(.top, 8)
            Text(Self.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onAddValley) {
                Text(Self.buttonTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    // Figma 01b: black button; flips to white in dark mode.
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .accessibilityIdentifier("home.empty.addValley")
            Spacer()
            // Not in Figma 01b, but the home screen must always show the data source (#3).
            SourceFooter(source: source)
        }
    }
}

#Preview {
    HomeEmptyView(source: "자료: 한강홍수통제소, 기상청", onAddValley: {})
        .padding()
}
