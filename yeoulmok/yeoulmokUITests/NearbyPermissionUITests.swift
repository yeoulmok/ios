import XCTest

/// APP-NEAR-01: the nearby tab asks for location once, and a "no" shows how to turn it on
/// (Figma 03b). Answers the real iOS permission alert, so each test resets the permission first.
final class NearbyPermissionUITests: XCTestCase {
    private var app: XCUIApplication!
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        // Back to "never asked", so the iOS alert shows again. Resetting before the first
        // launch was sometimes ignored, so launch, reset (iOS ends the app), then launch again.
        app.launch()
        app.resetAuthorizationStatus(for: .location)
        app.launch()
    }

    @MainActor
    func testDenyingShowsHowToTurnItOn() {
        app.tabBars.buttons["근처"].tap()
        answerAlert(english: "Don’t Allow", korean: "허용 안 함")

        XCTAssertTrue(app.staticTexts["위치 권한이 필요해요"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["nearby.openSettings"].exists)
        XCTAssertTrue(app.staticTexts["자료: 한강홍수통제소, 기상청"].exists)
    }

    @MainActor
    func testAllowingShowsNearbyScreen() {
        app.tabBars.buttons["근처"].tap()
        answerAlert(english: "Allow While Using App", korean: "앱을 사용하는 동안 허용")

        XCTAssertTrue(app.staticTexts["nearby.allowed"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["위치 권한이 필요해요"].exists)
    }

    @MainActor
    func testAlertIsNotAskedAgainAfterAnswer() {
        app.tabBars.buttons["근처"].tap()
        answerAlert(english: "Don’t Allow", korean: "허용 안 함")
        XCTAssertTrue(app.staticTexts["위치 권한이 필요해요"].waitForExistence(timeout: 3))

        app.tabBars.buttons["홈"].tap()
        app.tabBars.buttons["근처"].tap()

        XCTAssertFalse(springboard.alerts.firstMatch.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["위치 권한이 필요해요"].exists)
    }

    /// Taps a button on the iOS alert. The simulator may be in English or Korean.
    /// iOS writes "Don’t" with a curly apostrophe.
    private func answerAlert(english: String, korean: String) {
        let alert = springboard.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "location alert")
        let button = alert.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", english, korean)).firstMatch
        XCTAssertTrue(button.exists, "alert button \(english); buttons: \(alert.buttons.allElementsBoundByIndex.map(\.label))")
        button.tap()
    }
}
