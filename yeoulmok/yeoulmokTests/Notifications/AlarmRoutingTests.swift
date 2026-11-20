import Testing
import UserNotifications
@testable import yeoulmok

/// #60: 위험 · 대피 pushes open the full-screen alarm; others open the detail as before.
@MainActor
struct AlarmRoutingTests {
    @Test(arguments: [("danger", true), ("evacuate", true), ("caution", false),
                      ("safe", false), ("unknown", false), ("test", false)])
    func onlyDangerAndEvacuateAreAlarms(level: String, expected: Bool) {
        #expect(PushPayload.isAlarm(["valley_id": 1, "level": level]) == expected)
    }

    @Test func missingLevelIsNotAnAlarm() {
        #expect(PushPayload.level(from: ["valley_id": 1]) == nil)
        #expect(!PushPayload.isAlarm(["valley_id": 1]))
    }

    @Test func confirmClosesTheAlarmAndOpensTheDetail() {
        let router = PushRouter()
        router.raiseAlarm(valleyID: 4, level: .danger, playsSound: true)
        #expect(router.alarm == .init(valleyID: 4, level: .danger, playsSound: true))
        #expect(router.pendingValleyID == nil)

        router.confirmAlarm()

        #expect(router.alarm == nil)
        #expect(router.take() == 4)
    }

    /// #85: each level has the sound a person picked, and the file is in the app bundle
    /// (a push `sound` naming a missing file falls back to the iOS default).
    @Test(arguments: [(ValleyLevel.caution, "caution"), (.danger, "danger"), (.evacuate, "evacuate")])
    func eachLevelHasItsSound(level: ValleyLevel, file: String) {
        #expect(AlarmSound.fileName(for: level) == file)
        #expect(Bundle.main.url(forResource: file, withExtension: "caf") != nil)
    }

    @Test(arguments: [ValleyLevel.safe, .unknown])
    func safeAndUnknownHaveNoSound(level: ValleyLevel) {
        #expect(AlarmSound.fileName(for: level) == nil)
    }

    @Test func alarmWhileOpenOnlyGoesToNotificationCenter() {
        #expect(PushPresentation.alarmWhileOpen == [.list])
    }
}
