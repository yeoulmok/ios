import UIKit
import UserNotifications

/// Receives what iOS gives the app outside SwiftUI: the APNs token, and pushes that
/// arrive while the app is open. Connected with `@UIApplicationDelegateAdaptor` in `YeoulmokApp`.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Set by `YeoulmokApp` when the first screen appears, before any token is asked for.
    /// `nil` in mock runs, so tests never send a token to the server.
    var pushTokens: PushTokenReceiver?
    /// Where a tapped push goes; `RootView` opens the detail from it (#20).
    let pushRouter = PushRouter()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Must be set before launch ends, or a push that opened the app is missed (#20).
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let pushTokens else { return }
        Task { await pushTokens.received(deviceToken) }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        pushTokens?.failed(error)
    }

    /// A push arrived while the app is on screen. iOS shows nothing unless we say so.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        PushPresentation.whileOpen
    }

    /// The user tapped a push: open that valley's alert detail (APP-NOTI-02). Also called
    /// when the tap launched the app, because the delegate is set in `didFinishLaunching`.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        // Only a tap on the notification itself (not, e.g., swiping it away).
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              let valleyID = PushPayload.valleyID(from: response.notification.request.content.userInfo)
        else { return }
        await MainActor.run {
            pushRouter.open(valleyID: valleyID)
        }
    }
}

/// How alert pushes (APP-NOTI-01) appear while the app is open.
nonisolated enum PushPresentation {
    /// Same as when the app is closed: a banner, kept in Notification Center, with sound.
    /// `.sound` only plays when the push has a sound, so the server's silent night-time
    /// `caution` (no `sound` key, API spec 4) stays silent here too. No badge: the app has none.
    static let whileOpen: UNNotificationPresentationOptions = [.banner, .list, .sound]
}
