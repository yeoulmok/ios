import Foundation
import Testing
import UserNotifications
@testable import yeoulmok

@MainActor
struct PushTokenReceiverTests {
    private struct SendFailed: Error {}

    @Test func tokenIsLowercaseHex() {
        let token = Data([0x00, 0x0f, 0xab, 0xff])
        #expect(PushTokenReceiver.hexString(token) == "000fabff")
    }

    @Test func realTokenSizeGives64Characters() {
        let token = Data((0..<32).map { UInt8($0) })
        #expect(PushTokenReceiver.hexString(token).count == 64)
    }

    @Test func launchAsksForTokenWhenAllowed() async {
        let permission = FakeNotificationPermission(allows: true)
        permission.alreadyAllowed = true
        let receiver = PushTokenReceiver(permission: permission) { _ in }

        await receiver.refreshOnLaunch()

        #expect(permission.registerCount == 1)
        #expect(permission.requestCount == 0)   // never shows iOS's question
    }

    @Test func launchDoesNothingWhenNotAllowed() async {
        // Denied, or "나중에 하기" (never asked): no token, no question.
        let permission = FakeNotificationPermission(allows: true)
        let receiver = PushTokenReceiver(permission: permission) { _ in }

        await receiver.refreshOnLaunch()

        #expect(permission.registerCount == 0)
        #expect(permission.requestCount == 0)
    }

    @Test func receivedTokenIsSentAsHex() async {
        var sent: [String] = []
        let receiver = PushTokenReceiver(permission: FakeNotificationPermission(allows: true)) { sent.append($0) }

        await receiver.received(Data([0xde, 0xad, 0xbe, 0xef]))

        #expect(sent == ["deadbeef"])
    }

    @Test func failedSendDoesNotThrowOrRetry() async {
        // The app keeps working; the next launch asks iOS again and resends.
        var attempts = 0
        let receiver = PushTokenReceiver(permission: FakeNotificationPermission(allows: true)) { _ in
            attempts += 1
            throw SendFailed()
        }

        await receiver.received(Data([0x01]))

        #expect(attempts == 1)
    }

    @Test(arguments: [
        (UNAuthorizationStatus.authorized, true),
        (.provisional, true),
        (.ephemeral, true),
        (.denied, false),
        (.notDetermined, false),
    ])
    func allowedStatuses(status: UNAuthorizationStatus, expected: Bool) {
        #expect(SystemNotificationPermission.isAllowed(status) == expected)
    }
}
