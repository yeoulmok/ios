import XCTest

/// APP-ONB-02: the first launch asks about notifications (Figma 05b), and the app works
/// whatever the answer. Mock runs skip this screen unless `-notificationOnboarding` is given.
final class NotificationOnboardingUITests: XCTestCase {
    private var app: XCUIApplication!
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // A first launch: the "already shown" mark is cleared.
        app.launchArguments = ["-useMockData", "-notificationOnboarding", "-resetNotificationOnboarding"]
        app.launch()
    }

    @MainActor
    func testLaterGoesToHomeWithoutAskingAndIsNotShownAgain() {
        XCTAssertTrue(app.staticTexts["onboarding.notification.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists)

        app.buttons["onboarding.notification.later"].tap()

        XCTAssertTrue(app.tabBars.buttons["홈"].waitForExistence(timeout: 3))
        XCTAssertFalse(springboard.alerts.firstMatch.waitForExistence(timeout: 2))

        // Next launch: straight to the tabs.
        app.terminate()
        app.launchArguments = ["-useMockData", "-notificationOnboarding"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["홈"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["onboarding.notification.title"].exists)
    }

    @MainActor
    func testAllowAsksIOSThenGoesToHome() {
        XCTAssertTrue(app.staticTexts["onboarding.notification.title"].waitForExistence(timeout: 5))

        app.buttons["onboarding.notification.allow"].tap()

        // iOS asks only once per install and UI tests cannot reset notification permission,
        // so the question appears only on a simulator that has not answered yet.
        let alert = springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: 5) {
            let allow = alert.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Allow", "허용")).firstMatch
            XCTAssertTrue(allow.exists, "alert buttons: \(alert.buttons.allElementsBoundByIndex.map(\.label))")
            allow.tap()
        }

        XCTAssertTrue(app.tabBars.buttons["홈"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["onboarding.notification.title"].exists)
    }

    @MainActor
    func testMockRunsSkipTheScreenByDefault() {
        app.terminate()
        app.launchArguments = ["-useMockData", "-resetNotificationOnboarding"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["홈"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["onboarding.notification.title"].exists)
    }
}
