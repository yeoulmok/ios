import Foundation

/// What the settings screen shows about the app (APP-SET-02): the version from the build,
/// and the terms, privacy and contact links from Config.xcconfig (through Info.plist).
/// A link that is not set yet is `nil`, and its row is shown disabled.
nonisolated struct AppInfo: Equatable {
    /// `MARKETING_VERSION` of this build, e.g. "1.0". Never typed by hand, so it always
    /// matches the build.
    let version: String?
    let termsURL: URL?
    let privacyURL: URL?
    let contactEmail: String?

    /// The values of this build.
    static let current = AppInfo(info: Bundle.main.infoDictionary ?? [:])

    /// Info.plist keys. Their values come from build settings of the same idea:
    /// `TermsURL` ← `TERMS_URL`, `PrivacyURL` ← `PRIVACY_URL`, `ContactEmail` ← `CONTACT_EMAIL`.
    enum Key {
        static let version = "CFBundleShortVersionString"
        static let termsURL = "TermsURL"
        static let privacyURL = "PrivacyURL"
        static let contactEmail = "ContactEmail"
    }

    init(info: [String: Any]) {
        version = Self.text(info[Key.version])
        termsURL = Self.webURL(info[Key.termsURL])
        privacyURL = Self.webURL(info[Key.privacyURL])
        contactEmail = Self.email(info[Key.contactEmail])
    }

    /// Opens the mail app with the address filled in.
    var contactURL: URL? {
        guard let contactEmail else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = contactEmail
        return components.url
    }

    /// A trimmed, non-empty string. A build setting that is not defined arrives as "".
    private static func text(_ value: Any?) -> String? {
        guard let string = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty else { return nil }
        return string
    }

    /// Only `https` pages: the documents are public web pages.
    private static func webURL(_ value: Any?) -> URL? {
        guard let text = text(value), let url = URL(string: text),
              url.scheme == "https", url.host() != nil else { return nil }
        return url
    }

    /// A plain check (one "@", text on both sides, no spaces). The mail app does the rest.
    private static func email(_ value: Any?) -> String? {
        guard let text = text(value) else { return nil }
        let parts = text.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains("."),
              !text.contains(where: \.isWhitespace) else { return nil }
        return text
    }
}
