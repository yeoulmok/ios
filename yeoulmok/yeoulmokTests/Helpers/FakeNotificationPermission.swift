@testable import yeoulmok

/// `NotificationPermission` whose answer the test chooses.
final class FakeNotificationPermission: NotificationPermission {
    /// What the user answers in iOS's question.
    var allows: Bool
    /// What `isAllowed()` answers (an earlier answer, e.g. on a later launch).
    var alreadyAllowed = false
    private(set) var requestCount = 0
    private(set) var registerCount = 0
    /// Runs while the question is "on screen", before the answer.
    var whileAsking: (() async -> Void)?

    init(allows: Bool) {
        self.allows = allows
    }

    func request() async -> Bool {
        requestCount += 1
        await whileAsking?()
        return allows
    }

    func isAllowed() async -> Bool {
        alreadyAllowed
    }

    func registerForPushToken() {
        registerCount += 1
    }
}
