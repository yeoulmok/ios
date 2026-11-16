import Foundation

/// Reads an alert push (API spec 4):
///
///     { "aps": { ... }, "valley_id": 1, "level": "caution" }
nonisolated enum PushPayload {
    static let valleyIDKey = "valley_id"

    /// The valley to open when the push is tapped (APP-NOTI-02), or `nil` when the push
    /// has none or it is not a valley id; then the app just opens, without an error.
    /// Accepts a number, and a number written as text in case the server sends one.
    static func valleyID(from userInfo: [AnyHashable: Any]) -> Int? {
        let id: Int?
        switch userInfo[valleyIDKey] {
        case let number as Int: id = number
        case let text as String: id = Int(text.trimmingCharacters(in: .whitespaces))
        default: id = nil
        }
        guard let id, id > 0 else { return nil }
        return id
    }
}
