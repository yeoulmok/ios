import Foundation

/// The data source line shown at the bottom of screens (APP-COM-03).
/// Showing it is a condition of using the public data, so it must never be blank.
nonisolated enum SourceText {
    /// Used when the server sends nothing usable.
    static let fallback = "자료: 한강홍수통제소, 기상청"

    private static let prefix = "자료:"

    /// Text to show for the server's `source` value.
    ///
    /// Falls back when the value is `nil`, blank, or only the prefix. The server
    /// builds `source` from the stations it used, so an empty list (for example
    /// `GET /me/valleys` with no subscriptions) comes back as `"자료: "`.
    static func display(_ source: String?) -> String {
        guard let text = source?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return fallback
        }
        let names = text.hasPrefix(prefix)
            ? text.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
            : text
        return names.isEmpty ? fallback : text
    }
}
