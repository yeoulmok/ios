import Observation

/// Hands a tapped push from the app delegate (outside SwiftUI) to `RootView`, which
/// opens the valley's alert detail (APP-NOTI-02).
///
/// The tap can arrive before any screen exists (the push launched the app), so it waits
/// here until `RootView` takes it.
@Observable
final class PushRouter {
    /// The valley whose detail should open next, if any.
    private(set) var pendingValleyID: Int?

    func open(valleyID: Int) {
        pendingValleyID = valleyID
    }

    /// Returns the waiting valley once, and forgets it.
    func take() -> Int? {
        defer { pendingValleyID = nil }
        return pendingValleyID
    }
}
