import AVFoundation
import Testing
import UserNotifications
@testable import yeoulmok

/// #108: a 주의 push while the app is open shows a confirm popup with its sound once.
@MainActor
struct CautionNoticeTests {
    @Test(arguments: [("caution", true), ("danger", false), ("evacuate", false),
                      ("safe", false), ("unknown", false), ("test", false)])
    func onlyCautionIsANotice(level: String, expected: Bool) {
        #expect(PushPayload.isNotice(["valley_id": 1, "level": level]) == expected)
    }

    @Test func detailOpensFromThePopup() {
        let router = PushRouter()
        router.showNotice(valleyID: 1, title: "금대리 계곡 · 주의", body: "상류에 비가 많이 오고 있어요")
        #expect(router.notice == .init(valleyID: 1, title: "금대리 계곡 · 주의", body: "상류에 비가 많이 오고 있어요"))
        #expect(router.pendingValleyID == nil)

        router.openNotice()

        #expect(router.notice == nil)
        #expect(router.take() == 1)
    }

    @Test func confirmOnlyCloses() {
        let router = PushRouter()
        router.showNotice(valleyID: 1, title: "금대리 계곡 · 주의", body: "")

        router.dismissNotice()

        #expect(router.notice == nil)
        #expect(router.take() == nil)
    }

    @Test(arguments: ["", "   "])
    func pushWithoutTitleGetsOne(title: String) {
        let router = PushRouter()
        router.showNotice(valleyID: 1, title: title, body: "")
        #expect(router.notice?.title == PushRouter.noticeFallbackTitle)
    }

    /// iOS only files it: the app's popup plays the sound, so it never sounds twice.
    @Test func noticeWhileOpenOnlyGoesToNotificationCenter() {
        #expect(PushPresentation.noticeWhileOpen == [.list])
    }

    /// Decided 2026-11-26: the 주의 sound follows the silent switch (위험 · 대피 do not).
    @Test func noticeSoundFollowsTheSilentSwitch() {
        #expect(NoticeSound.category == .ambient)
        #expect(Bundle.main.url(forResource: "caution", withExtension: "caf") != nil)
    }
}
