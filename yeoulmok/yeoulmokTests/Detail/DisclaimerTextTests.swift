import Foundation
import Testing
@testable import yeoulmok

struct DisclaimerTextTests {
    @Test func serverTextIsShownAsIs() {
        #expect(DisclaimerText.display("판단 보조 정보입니다.") == "판단 보조 정보입니다.")
    }

    @Test(arguments: [nil, "", "   ", "\n"] as [String?])
    func blankFallsBackToRequiredWording(disclaimer: String?) {
        // Legally required: the screen never shows an empty disclaimer.
        #expect(DisclaimerText.display(disclaimer) == "판단 보조 정보이며 공식 재난경보를 대체하지 않습니다.")
    }

    @Test func mockDataSendsTheSameWordingAsTheFallback() throws {
        let details = try MockData.valleyDetails(bundle: .main)
        #expect(details.allSatisfy { $0.disclaimer == DisclaimerText.fallback })
    }
}
