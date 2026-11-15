import Testing
@testable import yeoulmok

@MainActor
struct SubscriptionPillTests {
    @Test func subscribedReadsAsState() {
        #expect(SubscriptionPill.title(isSubscribed: true) == "구독중")
    }

    @Test func notSubscribedReadsAsAction() {
        #expect(SubscriptionPill.title(isSubscribed: false) == "구독")
    }
}
