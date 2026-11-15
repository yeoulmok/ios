import SwiftUI

/// "구독중" / "구독" pill on the right of a search row (Figma 02 v2).
/// Display only for now; #7 (APP-SRCH-03) makes it a toggle button.
struct SubscriptionPill: View {
    let isSubscribed: Bool

    var body: some View {
        Text(Self.title(isSubscribed: isSubscribed))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(isSubscribed ? Color.primary : Color(.systemBackground))
            .background(isSubscribed ? Color(.systemGray6) : Color.primary, in: Capsule())
            .overlay(Capsule().stroke(isSubscribed ? Color(.systemGray3) : .clear))
    }

    /// Already subscribed reads as a state ("구독중"), not subscribed as the action ("구독").
    static func title(isSubscribed: Bool) -> String {
        isSubscribed ? "구독중" : "구독"
    }
}

#Preview {
    HStack {
        SubscriptionPill(isSubscribed: true)
        SubscriptionPill(isSubscribed: false)
    }
    .padding()
}
