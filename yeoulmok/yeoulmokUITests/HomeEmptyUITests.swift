import XCTest

/// APP-HOME-04 (Figma 01b): with no subscriptions, home shows the empty state,
/// and "계곡 추가하기" opens the search tab.
/// Uses the bundled mock data (subscribed: 1, 2, 4; unsubscribed here through search).
final class HomeEmptyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
    }

    @MainActor
    func testNoSubscriptionsShowsEmptyStateAndButtonOpensSearch() {
        unsubscribeAll()
        app.tabBars.buttons["홈"].tap()

        let button = app.buttons["home.empty.addValley"]
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        XCTAssertEqual(button.label, "계곡 추가하기")
        XCTAssertTrue(app.staticTexts["구독한 계곡이 없어요"].exists)
        XCTAssertTrue(app.staticTexts["관심 있는 계곡을 추가하면\n위험할 때 알림을 보내드려요."].exists)
        XCTAssertTrue(app.staticTexts["자료: 한강홍수통제소, 기상청"].exists, "data source stays on home")

        button.tap()

        XCTAssertTrue(app.textFields["search.queryField"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["검색"].isSelected)
    }

    @MainActor
    func testSubscribedHomeHasNoEmptyState() {
        XCTAssertTrue(app.staticTexts["구독한 계곡"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["home.empty.addValley"].exists)
    }

    /// Mock subscriptions are 1, 2 and 4. Unsubscribes on each detail (#57: the
    /// button moved there from the search list), going back to the list each time.
    private func unsubscribeAll() {
        app.tabBars.buttons["검색"].tap()
        for id in [1, 2, 4] {
            let row = app.buttons["search.row.\(id)"]
            XCTAssertTrue(row.waitForExistence(timeout: 3))
            row.tap()
            let button = app.buttons["detail.subscription"]
            XCTAssertTrue(button.waitForExistence(timeout: 3))
            button.tap()
            XCTAssertTrue(button.label.hasSuffix(" 구독"), "valley \(id) unsubscribed")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
}
