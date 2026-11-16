import Observation

/// First-launch notification screen (APP-ONB-02, Figma 05b).
///
/// - "알림 허용": shows iOS's question; when allowed, asks iOS for the push token
///   (the app delegate sends it to the server). Either answer goes on to the app.
/// - "나중에 하기": goes on without asking, so iOS's one question is kept for later.
/// - Both remember that the screen was shown, so it does not appear again.
@Observable
final class NotificationOnboardingViewModel {
    /// True while iOS's question is on screen; the buttons are disabled.
    private(set) var isRequesting = false

    private let permission: any NotificationPermission
    private let store: NotificationOnboardingStore
    private let onFinish: () -> Void

    init(permission: any NotificationPermission, store: NotificationOnboardingStore,
         onFinish: @escaping () -> Void) {
        self.permission = permission
        self.store = store
        self.onFinish = onFinish
    }

    func allow() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }

        if await permission.request() {
            permission.registerForPushToken()
        }
        finish()
    }

    func later() {
        guard !isRequesting else { return }
        finish()
    }

    private func finish() {
        store.markDone()
        onFinish()
    }
}
