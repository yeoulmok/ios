import XCTest

/// APP-NOTI-02: tapping an alert push opens that valley's detail on the home tab.
/// UI tests cannot send pushes, so `-mockPushValleyID` acts as a tap that launched the app.
/// (Real taps were checked with `xcrun simctl push`.)
final class PushDeepLinkUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    @MainActor
    func testPushOpensDetailAndBackGoesToHome() {
        launch(pushValleyID: 1)

        XCTAssertTrue(app.navigationBars["금대리 계곡"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["detail.summary"].waitForExistence(timeout: 3))

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["여울목"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["홈"].isSelected)
    }

    @MainActor
    func testUnknownValleyShowsErrorScreen() {
        // Feature spec 3-1: the server's VALLEY_NOT_FOUND message on the error screen (#17).
        launch(pushValleyID: 999)

        let title = app.staticTexts["error.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "계곡 정보를 찾을 수 없어요")
        XCTAssertTrue(app.buttons["error.retry"].exists)
    }

    @MainActor
    func testNoPushStartsOnHomeList() {
        app.launchArguments = ["-useMockData"]
        app.launch()

        XCTAssertTrue(app.navigationBars["여울목"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["detail.summary"].exists)
    }

    private func launch(pushValleyID: Int) {
        app.launchArguments = ["-useMockData", "-mockPushValleyID", "\(pushValleyID)"]
        app.launch()
    }
}
