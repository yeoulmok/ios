import XCTest

/// APP-HOME-05 (#59): the featured valley card above the subscribed list.
/// Mock subscriptions: 1 금대리 (주의), 2 갑천 (판정 불가), 4 위험 예시 (위험) → 4 is featured.
final class HomeFeaturedUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
    }

    @MainActor
    func testMostUrgentValleyIsFeaturedAboveTheList() {
        let card = app.buttons["home.featured"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("가장 위험한 구독 계곡"), card.label)
        XCTAssertTrue(card.label.contains("위험 예시 계곡"), card.label)
        XCTAssertTrue(card.label.contains("단계 위험"), card.label)

        let listHeader = app.staticTexts["구독한 계곡"]
        XCTAssertTrue(listHeader.exists)
        XCTAssertLessThan(card.frame.minY, listHeader.frame.minY, "card sits above the list")
    }

    @MainActor
    func testCardOpensThatValleysDetail() {
        let card = app.buttons["home.featured"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))

        card.tap()

        XCTAssertTrue(app.navigationBars["위험 예시 계곡"].waitForExistence(timeout: 3))
    }
}
