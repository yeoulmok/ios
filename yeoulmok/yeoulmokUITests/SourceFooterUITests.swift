import XCTest

/// APP-COM-03: the data source line is required on home and nearby.
/// (The detail screen gets the same check when it is built in #10.)
final class SourceFooterUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testSourceIsShownOnHomeAndNearby() {
        let source = app.staticTexts["자료: 한강홍수통제소, 기상청"]

        XCTAssertTrue(source.waitForExistence(timeout: 2), "home")

        app.tabBars.buttons["근처"].tap()
        XCTAssertTrue(source.waitForExistence(timeout: 2), "nearby")
    }
}
