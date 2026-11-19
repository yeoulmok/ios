import XCTest

/// APP-DTL-06 (#57): "구독" ↔ "구독중" on the alert detail, reflected on home at once;
/// on failure the button flips back and the Figma 02b toast appears. Before #57 this
/// button was in the search list (APP-SRCH-03); the flow is now search → detail → button.
/// Uses the bundled mock data (subscribed: 1 금대리, 2 갑천, 4 위험 예시; not: 3 안전 예시).
final class SubscriptionToggleUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
    }

    @MainActor
    func testSubscribeAddsToHomeAndUnsubscribeRemoves() {
        app.launch()
        XCTAssertFalse(homeCard(named: "안전 예시 계곡").waitForExistence(timeout: 2))

        openDetailFromSearch(valleyID: 3)
        let button = subscriptionButton
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        XCTAssertEqual(button.label, "안전 예시 계곡 구독")
        button.tap()
        XCTAssertEqual(button.label, "안전 예시 계곡 구독중")

        // The detail has no tab bar (Figma 04): back to the list, then home.
        goBack()
        app.tabBars.buttons["홈"].tap()
        XCTAssertTrue(homeCard(named: "안전 예시 계곡").waitForExistence(timeout: 3))

        openDetailFromSearch(valleyID: 3)
        XCTAssertTrue(subscriptionButton.waitForExistence(timeout: 3))
        subscriptionButton.tap()
        XCTAssertEqual(subscriptionButton.label, "안전 예시 계곡 구독")

        goBack()
        app.tabBars.buttons["홈"].tap()
        XCTAssertTrue(homeCard(named: "금대리 계곡").waitForExistence(timeout: 3))
        XCTAssertFalse(homeCard(named: "안전 예시 계곡").exists)
    }

    /// Unsubscribing from a detail opened on home: back on home, the card is gone.
    @MainActor
    func testUnsubscribeFromHomeDetailUpdatesHomeOnBack() {
        app.launch()
        let card = homeCard(named: "금대리 계곡")
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()
        XCTAssertTrue(subscriptionButton.waitForExistence(timeout: 3))
        subscriptionButton.tap()
        XCTAssertEqual(subscriptionButton.label, "금대리 계곡 구독")

        goBack()

        XCTAssertTrue(homeCard(named: "갑천 계곡").waitForExistence(timeout: 3))
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: homeCard(named: "금대리 계곡"))
        wait(for: [gone], timeout: 3)
    }

    @MainActor
    func testFailureFlipsBackAndShowsToast() {
        app.launchArguments += ["-mockSubscriptionFails"]
        app.launch()
        openDetailFromSearch(valleyID: 1)
        let button = subscriptionButton
        XCTAssertTrue(button.waitForExistence(timeout: 3))

        button.tap()

        let toast = app.staticTexts["toast"]
        XCTAssertTrue(toast.waitForExistence(timeout: 3))
        XCTAssertEqual(toast.label, "구독을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.")
        XCTAssertEqual(button.label, "금대리 계곡 구독중", "button should flip back")

        // The toast hides by itself (Figma 02b: 2~3 seconds).
        let hidden = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: toast)
        wait(for: [hidden], timeout: 5)
    }

    private func openDetailFromSearch(valleyID: Int) {
        app.tabBars.buttons["검색"].tap()
        let row = app.buttons["search.row.\(valleyID)"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()
    }

    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    private var subscriptionButton: XCUIElement {
        app.buttons["detail.subscription"]
    }

    /// A home card is one accessibility element whose label starts with the valley name.
    private func homeCard(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", name))
            .firstMatch
    }
}
