import XCTest

/// APP-NOTI-04 (#60): a tapped 위험 · 대피 push shows the full-screen alarm;
/// "확인했습니다" opens that valley's detail.
final class AlarmUITests: XCTestCase {
    @MainActor
    func testAlarmThenConfirmOpensDetail() {
        let app = XCUIApplication()
        app.launchArguments = ["-useMockData", "-mockAlarmValleyID", "4"]
        app.launch()

        XCTAssertTrue(app.staticTexts["alarm.summary"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["alarm.summary"].label, "물이 빠르게 불어날 수 있어요")
        XCTAssertTrue(app.staticTexts["즉시 물에서 나오기"].exists, "server actions are shown")

        app.buttons["alarm.confirm"].tap()

        XCTAssertTrue(app.navigationBars["위험 예시 계곡"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["alarm.confirm"].exists)
    }
}
