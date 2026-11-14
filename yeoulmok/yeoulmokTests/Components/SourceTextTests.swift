import Testing
@testable import yeoulmok

struct SourceTextTests {
    @Test(arguments: [
        "자료: 한강홍수통제소, 기상청",
        "자료: 기상청",
        "자료: 한강홍수통제소",
    ])
    func keepsServerText(source: String) {
        #expect(SourceText.display(source) == source)
    }

    @Test(arguments: [nil, "", "   ", "\n", "자료:", "자료: ", "  자료:  "] as [String?])
    func fallsBackWhenNothingUsable(source: String?) {
        #expect(SourceText.display(source) == SourceText.fallback)
    }

    @Test func trimsSurroundingSpaces() {
        #expect(SourceText.display("  자료: 기상청 \n") == "자료: 기상청")
    }

    @Test func fallbackNamesBothAgencies() {
        // Required wording from the feature spec.
        #expect(SourceText.fallback == "자료: 한강홍수통제소, 기상청")
    }
}
