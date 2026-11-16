import Foundation
import Testing
@testable import yeoulmok

struct SettingsRowsTests {
    private let filled = AppInfo(info: [
        "CFBundleShortVersionString": "1.0",
        "TermsURL": "https://example.com/terms",
        "PrivacyURL": "https://example.com/privacy",
        "ContactEmail": "help@example.com",
    ])
    private let empty = AppInfo(info: [:])

    @Test func figmaOrder() {
        #expect(SettingsRows.rows(for: filled).map(\.title) == ["이용약관", "개인정보처리방침", "데이터 출처", "문의하기"])
    }

    @Test func linksOpenTheConfiguredPages() {
        let rows = SettingsRows.rows(for: filled)
        #expect(rows[0].action == .open(URL(string: "https://example.com/terms")))
        #expect(rows[1].action == .open(URL(string: "https://example.com/privacy")))
        #expect(rows[2].action == .dataSource)
        #expect(rows[3].action == .open(URL(string: "mailto:help@example.com")))
        let allEnabled = rows.allSatisfy(\.isEnabled)
        #expect(allEnabled)
    }

    @Test func missingLinksAreShownDisabled() {
        // Still listed, so it is clear the row exists; it just cannot be tapped yet.
        let rows = SettingsRows.rows(for: empty)
        #expect(rows.count == 4)
        let enabled = rows.filter(\.isEnabled).map(\.id)
        #expect(enabled == ["dataSource"])
    }

    @Test func versionText() {
        #expect(SettingsRows.versionText(for: filled) == "1.0")
        #expect(SettingsRows.versionText(for: empty) == "-")
    }
}
