import Testing
import UIKit
import UserNotifications
@testable import yeoulmok

@MainActor
struct PushPresentationTests {
    @Test func openAppShowsBannerListAndSound() {
        // An alert must not be missed because the app happens to be open.
        #expect(PushPresentation.whileOpen.contains(.banner))
        #expect(PushPresentation.whileOpen.contains(.list))
        #expect(PushPresentation.whileOpen.contains(.sound))
    }

    @Test func noBadge() {
        #expect(!PushPresentation.whileOpen.contains(.badge))
    }

    @Test func appDelegateHandlesPushesFromLaunch() {
        // The unit tests' host app has launched, so the delegate is already set.
        #expect(UNUserNotificationCenter.current().delegate is AppDelegate)
    }
}
