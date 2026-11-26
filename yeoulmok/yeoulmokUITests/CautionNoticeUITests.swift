import XCTest

/// #108: a 주의 push while the app is open shows "(계곡) · 주의" with [확인] [상세 보기].
/// `-mockCautionValleyID 1` acts as if that push arrived (UI tests cannot send pushes).
final class CautionNoticeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData", "-mockCautionValleyID", "1"]
        app.launch()
    }

    @MainActor
    func testOpenDetailFromThePopup() {
        let popup = app.alerts["금대리 계곡 · 주의"]
        XCTAssertTrue(popup.waitForExistence(timeout: 5))
        XCTAssertTrue(popup.staticTexts["상류에 비가 많이 오고 있어요"].exists)

        popup.buttons["상세 보기"].tap()

        XCTAssertTrue(app.staticTexts["detail.summary"].waitForExistence(timeout: 5))
        XCTAssertFalse(popup.exists)
    }

    @MainActor
    func testConfirmStaysWhereTheUserWas() {
        let popup = app.alerts["금대리 계곡 · 주의"]
        XCTAssertTrue(popup.waitForExistence(timeout: 5))

        popup.buttons["확인"].tap()

        XCTAssertFalse(popup.waitForExistence(timeout: 1))
        XCTAssertFalse(app.staticTexts["detail.summary"].exists)
        XCTAssertTrue(app.tabBars.buttons["홈"].isSelected)
    }
}
