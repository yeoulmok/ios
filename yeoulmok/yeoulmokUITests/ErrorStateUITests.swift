import XCTest

/// APP-COM-06: with nothing received yet, a failed request shows the common error
/// screen, and "다시 시도" sends the same request again.
/// `-mockLoadFailsOnce` makes only the first load fail (bundled mock data).
final class ErrorStateUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData", "-mockLoadFailsOnce"]
        app.launch()
    }

    @MainActor
    func testHomeErrorThenRetryShowsTheList() {
        let title = app.staticTexts["error.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        XCTAssertEqual(title.label, "연결할 수 없어요")
        XCTAssertTrue(app.staticTexts["인터넷 연결을 확인해 주세요."].exists)
        XCTAssertTrue(app.staticTexts["자료: 한강홍수통제소, 기상청"].exists, "data source stays on home")

        app.buttons["error.retry"].tap()

        XCTAssertTrue(app.staticTexts["구독한 계곡"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["error.retry"].exists)
    }
}
