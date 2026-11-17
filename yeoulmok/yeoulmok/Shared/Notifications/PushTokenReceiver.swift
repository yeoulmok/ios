import Foundation
import os

/// Gets this phone's APNs token to the server (APP-ONB-02, #8).
///
/// iOS gives the token to the app delegate after `registerForPushToken()`, which is called
/// right after the user allows notifications and again on every launch while allowed
/// (Apple: the token can change, so ask each launch). `DeviceRegistrar` sends it only
/// when the server does not have it yet.
final class PushTokenReceiver {
    private let permission: any NotificationPermission
    private let send: (String) async throws -> Void
    private let logger = Logger(subsystem: "yeoulmok", category: "push")

    init(permission: any NotificationPermission, send: @escaping (String) async throws -> Void) {
        self.permission = permission
        self.send = send
    }

    /// On launch: asks iOS for the token again, only when notifications are allowed.
    /// Never shows a question (that is the onboarding screen's job).
    func refreshOnLaunch() async {
        if await permission.isAllowed() {
            permission.registerForPushToken()
        }
    }

    /// The token from `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
    /// A failed send is not retried now: the next launch asks iOS again and resends.
    func received(_ deviceToken: Data) async {
        // Success is logged too (never the token itself), so a real-device check can see
        // in Console that the token reached the server.
        logger.notice("Got a push token")
        do {
            try await send(Self.hexString(deviceToken))
            logger.notice("Push token is on the server")
        } catch {
            logger.error("Push token not sent: \(error.localizedDescription)")
        }
    }

    /// iOS could not give a token (e.g. no network, or push not set up for this build).
    /// The app works without it; there are just no pushes.
    func failed(_ error: any Error) {
        logger.error("No push token: \(error.localizedDescription)")
    }

    /// APNs expects the token as lowercase hex: 32 bytes → 64 characters.
    nonisolated static func hexString(_ deviceToken: Data) -> String {
        deviceToken.map { String(format: "%02x", $0) }.joined()
    }
}
