import Foundation
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

    // MARK: Notice (#108)

    /// The confirm popup on screen: a 주의 push that arrived while the app was open.
    /// Not a full-screen alarm; it plays the 주의 sound once.
    private(set) var notice: Notice?

    struct Notice: Equatable, Identifiable {
        let valleyID: Int
        /// The push's own title and body ("금대리 계곡 · 주의", the server's summary).
        let title: String
        let body: String
        var id: Int { valleyID }
    }

    /// When the push has no title of its own. Temporary wording until QA.
    static let noticeFallbackTitle = "구독한 계곡 · 주의"

    func showNotice(valleyID: Int, title: String, body: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        notice = Notice(valleyID: valleyID, title: title.isEmpty ? Self.noticeFallbackTitle : title, body: body)
    }

    /// "확인": closes the popup.
    func dismissNotice() {
        notice = nil
    }

    /// "상세 보기": closes the popup and opens that valley's detail.
    func openNotice() {
        guard let notice else { return }
        self.notice = nil
        open(valleyID: notice.valleyID)
    }

    /// "확인했습니다": closes the alarm and opens that valley's detail.
    func confirmAlarm() {
        guard let alarm else { return }
        self.alarm = nil
        open(valleyID: alarm.valleyID)
    }
}
