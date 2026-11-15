import Foundation

/// Turns a failed request into the sentence shown on screen (feature spec 3-1).
/// Every screen uses this, so the same error always reads the same way.
nonisolated enum ErrorMessage {
    /// Shown when the error does not come from the server (e.g. no network).
    /// Same wording as the common error screen in Figma.
    static let connection = "연결할 수 없어요"

    /// The server's own `message` for server errors, `connection` for everything else.
    static func text(for error: any Error) -> String {
        (error as? APIError)?.message ?? connection
    }
}
