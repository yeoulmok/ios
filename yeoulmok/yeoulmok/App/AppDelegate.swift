import UIKit

/// Receives what iOS gives the app outside SwiftUI: the APNs token.
/// Connected with `@UIApplicationDelegateAdaptor` in `YeoulmokApp`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Set by `YeoulmokApp` when the first screen appears, before any token is asked for.
    /// `nil` in mock runs, so tests never send a token to the server.
    var pushTokens: PushTokenReceiver?

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let pushTokens else { return }
        Task { await pushTokens.received(deviceToken) }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        pushTokens?.failed(error)
    }
}
