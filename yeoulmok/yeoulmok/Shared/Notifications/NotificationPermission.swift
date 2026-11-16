import UIKit
import UserNotifications

/// Push notification permission, behind a protocol so view models can be tested without iOS.
protocol NotificationPermission: AnyObject {
    /// Shows iOS's notification question. iOS shows it only once per install; after
    /// that it answers right away with the user's earlier choice.
    /// True when notifications are allowed.
    func request() async -> Bool
    /// Asks iOS for this phone's APNs token. The token arrives in the app delegate.
    func registerForPushToken()
}

/// `NotificationPermission` backed by `UNUserNotificationCenter`.
final class SystemNotificationPermission: NotificationPermission {
    /// Banners and sound only: the app has no badge count, and critical or
    /// time-sensitive alerts need extra approval from Apple.
    static let options: UNAuthorizationOptions = [.alert, .sound]

    func request() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: Self.options)
        } catch {
            // iOS could not ask (rare). Treat it as "not allowed"; the app still works.
            return false
        }
    }

    func registerForPushToken() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
