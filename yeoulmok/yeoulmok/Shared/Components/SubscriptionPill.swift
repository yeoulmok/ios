import SwiftUI

/// "구독중" / "구독" pill (Figma 02 v2). Shown at the top right of the alert
/// detail, where the subscription is changed (APP-DTL-06, #57).
struct SubscriptionPill: View {
    let isSubscribed: Bool

    var body: some View {
        // On the glass toolbar (#71): subscribed reads as plain white text,
        // not subscribed as a solid white pill, the one action to take.
        Text(Self.title(isSubscribed: isSubscribed))
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isSubscribed ? Color.white : Color(hex: 0x101828))
            .background(isSubscribed ? Color.clear : Color.white, in: Capsule())
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
    .background(Theme.night)
}
