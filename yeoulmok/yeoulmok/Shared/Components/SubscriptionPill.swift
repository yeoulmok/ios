import SwiftUI

/// "구독중" / "구독" pill (Figma 02 v2). Shown at the top right of the alert
/// detail, where the subscription is changed (APP-DTL-06, #57).
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
