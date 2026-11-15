import XCTest

/// APP-DTL-04 (Figma 04): "행동 요령" lists the server's `actions` as they are, in order.
/// Uses the bundled mock data (1 금대리 주의: 2 actions).
final class ActionListUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
    }

    @MainActor
    func testShowsServerActionsInOrder() {
        open("금대리 계곡")

        let title = app.staticTexts["행동 요령"]
        XCTAssertTrue(title.exists)
        XCTAssertEqual(app.staticTexts["detail.action.0"].label, "물가에서 떨어지기")
        XCTAssertEqual(app.staticTexts["detail.action.1"].label, "높은 곳으로 이동 준비")
        XCTAssertFalse(app.staticTexts["detail.action.2"].exists, "no action the server did not send")
        XCTAssertLessThan(app.staticTexts["detail.action.0"].frame.minY,
                          app.staticTexts["detail.action.1"].frame.minY, "server order")
    }

    /// Taps the home card for `name` and waits for its detail to load.
    private func open(_ name: String) {
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3), "\(name) card")
        card.tap()
        XCTAssertTrue(app.staticTexts["detail.summary"].waitForExistence(timeout: 3), "\(name) detail")
    }
}
