import Foundation
import Testing
@testable import yeoulmok

struct AppInfoTests {
    private let filled: [String: Any] = [
        "CFBundleShortVersionString": "1.2",
        "TermsURL": "https://example.com/terms",
        "PrivacyURL": "https://example.com/privacy",
        "ContactEmail": "help@example.com",
    ]

    @Test func readsAllValues() {
        let info = AppInfo(info: filled)
        #expect(info.version == "1.2")
        #expect(info.termsURL == URL(string: "https://example.com/terms"))
        #expect(info.privacyURL == URL(string: "https://example.com/privacy"))
        #expect(info.contactEmail == "help@example.com")
    }

    @Test func contactOpensMail() {
        #expect(AppInfo(info: filled).contactURL == URL(string: "mailto:help@example.com"))
    }

    @Test func missingOrEmptyValuesAreNil() {
        // A build setting that is not defined arrives as "".
        let info = AppInfo(info: ["TermsURL": "", "PrivacyURL": "  ", "ContactEmail": ""])
        #expect(info.version == nil)
        #expect(info.termsURL == nil)
        #expect(info.privacyURL == nil)
        #expect(info.contactEmail == nil)
        #expect(info.contactURL == nil)
    }

    @Test(arguments: ["http://example.com/terms", "example.com/terms", "https://", "not a url", "ftp://example.com"])
    func onlyHttpsPagesAreLinks(value: String) {
        #expect(AppInfo(info: ["TermsURL": value]).termsURL == nil)
    }

    @Test(arguments: ["help", "@example.com", "help@", "help@example", "a@b@example.com", "help @example.com"])
    func invalidEmailIsNil(value: String) {
        #expect(AppInfo(info: ["ContactEmail": value]).contactEmail == nil)
    }

    @Test func valuesAreTrimmed() {
        let info = AppInfo(info: ["CFBundleShortVersionString": " 1.0 ", "ContactEmail": " help@example.com\n"])
        #expect(info.version == "1.0")
        #expect(info.contactEmail == "help@example.com")
    }

    @Test func thisBuildHasAVersion() {
        // The settings screen shows it, so the build must provide it (MARKETING_VERSION).
        #expect(AppInfo.current.version == Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
        #expect(AppInfo.current.version != nil)
    }
}
