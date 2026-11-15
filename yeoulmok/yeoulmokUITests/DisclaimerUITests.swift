import XCTest

/// APP-DTL-05 (Figma 04): the alert detail always shows the disclaimer,
/// right above the data source line.
final class DisclaimerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
    }

    @MainActor
    func testDisclaimerIsShownAboveSource() {
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "금대리 계곡")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()

        let disclaimer = app.staticTexts["detail.disclaimer"]
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 3))
        XCTAssertEqual(disclaimer.label, "판단 보조 정보이며 공식 재난경보를 대체하지 않습니다.")
        let source = app.staticTexts["자료: 한강홍수통제소, 기상청"]
        XCTAssertTrue(source.exists)
        XCTAssertLessThan(disclaimer.frame.minY, source.frame.minY, "Figma 04: disclaimer, then source")
    }
}
