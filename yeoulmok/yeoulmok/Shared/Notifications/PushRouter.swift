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

    // MARK: Alarm (#60)

    /// The full-screen alarm on screen: a 위험 · 대피 push. Stays until confirmed.
    private(set) var alarm: Alarm?

    struct Alarm: Equatable, Identifiable {
        let valleyID: Int
        /// The pushed level (위험 or 대피); picks the alarm sound (#85).
        let level: ValleyLevel
        /// `true` when the push arrived while the app was open: the app plays the
        /// alarm sound itself. `false` after a tapped push (iOS already alerted).
        let playsSound: Bool
        var id: Int { valleyID }
    }

    func raiseAlarm(valleyID: Int, level: ValleyLevel, playsSound: Bool) {
        alarm = Alarm(valleyID: valleyID, level: level, playsSound: playsSound)
    }

    /// "확인했습니다": closes the alarm and opens that valley's detail.
    func confirmAlarm() {
        guard let alarm else { return }
        self.alarm = nil
        open(valleyID: alarm.valleyID)
    }
}
