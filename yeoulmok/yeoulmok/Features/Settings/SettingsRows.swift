import Foundation

/// One row in the settings screen's "정보" group (APP-SET-02, Figma 06).
nonisolated struct SettingsRow: Equatable, Identifiable {
    enum Action: Equatable {
        /// Opens outside the app: a web page in Safari, or `mailto:` in the mail app.
        /// `nil` while the link is not set in Config.xcconfig: the row is disabled.
        case open(URL?)
        /// Shows the data source screen inside the app.
        case dataSource
        /// Shows the contact screen inside the app (#92): the app's email and the
        /// agencies behind the data. Always open, even before the email is set.
        case contact
    }

    let id: String
    let title: String
    let action: Action

    var isEnabled: Bool { action != .open(nil) }
}

/// What the settings screen lists, in Figma 06's order.
nonisolated enum SettingsRows {
    static func rows(for info: AppInfo) -> [SettingsRow] {
        [
            SettingsRow(id: "terms", title: "이용약관", action: .open(info.termsURL)),
            SettingsRow(id: "privacy", title: "개인정보처리방침", action: .open(info.privacyURL)),
            SettingsRow(id: "dataSource", title: "데이터 출처", action: .dataSource),
            SettingsRow(id: "contact", title: "문의하기", action: .contact),
        ]
    }

    /// "1.0", or "-" when the build has no version (never happens in a real build).
    static func versionText(for info: AppInfo) -> String {
        info.version ?? "-"
    }
}
