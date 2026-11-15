import XCTest

/// APP-SRCH-03: "구독" ↔ "구독중" in the search tab, reflected on home at once;
/// on failure the button flips back and the Figma 02b toast appears.
/// Uses the bundled mock data (subscribed: 1 금대리, 2 갑천, 4 위험 예시; not: 3 안전 예시).
final class SubscriptionToggleUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    @MainActor
    func testSubscribeAddsToHomeAndUnsubscribeRemoves() {
        app.launch()
        XCTAssertFalse(homeCard(named: "안전 예시 계곡").waitForExistence(timeout: 2))

        app.tabBars.buttons["검색"].tap()
        let button = subscriptionButton(valleyID: 3)
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        button.tap()
        XCTAssertEqual(button.label, "안전 예시 계곡 구독중")

        app.tabBars.buttons["홈"].tap()
        XCTAssertTrue(homeCard(named: "안전 예시 계곡").waitForExistence(timeout: 3))

        app.tabBars.buttons["검색"].tap()
        subscriptionButton(valleyID: 3).tap()
        XCTAssertEqual(subscriptionButton(valleyID: 3).label, "안전 예시 계곡 구독")

        app.tabBars.buttons["홈"].tap()
        XCTAssertTrue(homeCard(named: "금대리 계곡").waitForExistence(timeout: 3))
        XCTAssertFalse(homeCard(named: "안전 예시 계곡").exists)
    }

    @MainActor
    func testFailureFlipsBackAndShowsToast() {
        app.launchArguments = ["-mockSubscriptionFails"]
        app.launch()
        app.tabBars.buttons["검색"].tap()
        let button = subscriptionButton(valleyID: 1)
        XCTAssertTrue(button.waitForExistence(timeout: 3))

        button.tap()

        let toast = app.staticTexts["toast"]
        XCTAssertTrue(toast.waitForExistence(timeout: 3))
        XCTAssertEqual(toast.label, "구독을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.")
        XCTAssertEqual(button.label, "금대리 계곡 구독중", "button should flip back")

        // The toast hides by itself (Figma 02b: 2~3 seconds).
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: toast)
        wait(for: [gone], timeout: 5)
    }

    private func subscriptionButton(valleyID: Int) -> XCUIElement {
        app.buttons["search.subscription.\(valleyID)"]
    }

    /// A home card is one accessibility element whose label starts with the valley name.
    private func homeCard(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", name))
            .firstMatch
    }
}
