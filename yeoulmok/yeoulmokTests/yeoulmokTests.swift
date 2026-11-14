import Foundation
import Testing
@testable import yeoulmok

struct AppConfigTests {
    @Test func apiBaseURLIsLoadedFromConfig() {
        #expect(AppConfig.apiBaseURL.scheme == "https")
        #expect(AppConfig.apiBaseURL.host() != "example.com")
    }
}
