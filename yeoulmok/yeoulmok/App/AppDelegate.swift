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

    // The two methods below use the completion-handler versions, not `async`. With `async`,
    // Swift calls iOS's completion handler off the main thread, and UIKit stops the app
    // (seen when tapping a push while the app was in the background). Here the handlers
    // are called right away, on the thread iOS called us on.

    /// A push arrived while the app is on screen. iOS shows nothing unless we say so.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        // #60: a 위험 · 대피 push while the app is open shows the full-screen alarm with
        // its sound right away; iOS only files it in Notification Center.
        if PushPayload.isAlarm(userInfo), let valleyID = PushPayload.valleyID(from: userInfo),
           let level = PushPayload.level(from: userInfo) {
            Task { @MainActor in
                pushRouter.raiseAlarm(valleyID: valleyID, level: level, playsSound: true)
            }
            completionHandler(PushPresentation.alarmWhileOpen)
            return
        }
        completionHandler(PushPresentation.whileOpen)
    }

    /// The user tapped a push: open that valley's alert detail (APP-NOTI-02). Also called
    /// when the tap launched the app, because the delegate is set in `didFinishLaunching`.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Only a tap on the notification itself (not, e.g., swiping it away).
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
           let valleyID = PushPayload.valleyID(from: response.notification.request.content.userInfo) {
            let userInfo = response.notification.request.content.userInfo
            let level = PushPayload.level(from: userInfo)
            // The router lives on the main actor; RootView opens the detail (or, for
            // 위험 · 대피, the full-screen alarm first, #60) when it changes.
            Task { @MainActor in
                if let level, level.isUrgent {
                    pushRouter.raiseAlarm(valleyID: valleyID, level: level, playsSound: false)
                } else {
                    pushRouter.open(valleyID: valleyID)
                }
            }
        }
        completionHandler()
    }
}

/// How alert pushes (APP-NOTI-01) appear while the app is open.
nonisolated enum PushPresentation {
    /// Same as when the app is closed: a banner, kept in Notification Center, with sound.
    /// `.sound` only plays when the push has a sound, so the server's silent night-time
    /// `caution` (no `sound` key, API spec 4) stays silent here too. No badge: the app has none.
    static let whileOpen: UNNotificationPresentationOptions = [.banner, .list, .sound]
    /// 위험 · 대피 while open (#60): the app shows its own alarm screen and sound,
    /// so iOS only keeps it in Notification Center.
    static let alarmWhileOpen: UNNotificationPresentationOptions = [.list]
}
