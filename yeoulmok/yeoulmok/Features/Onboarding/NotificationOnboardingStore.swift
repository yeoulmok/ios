import Foundation

/// Remembers on the phone that the notification screen (APP-ONB-02) was shown,
/// so it appears only on the first launch, whichever button was pressed.
nonisolated struct NotificationOnboardingStore {
    static let key = "notificationOnboardingDone"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isDone: Bool { defaults.bool(forKey: Self.key) }

    func markDone() {
        defaults.set(true, forKey: Self.key)
    }

    /// Shows the screen again on the next launch (DEBUG `-resetNotificationOnboarding`).
    func reset() {
        defaults.removeObject(forKey: Self.key)
    }
}
