import XCTest

/// APP-SRCH-02: the search tab lists valleys, filters by name, shows 02a when
/// nothing matches, and opens detail from a row.
/// Uses the bundled mock data (5 valleys; subscribed: 1 금대리, 2 갑천, 4 위험 예시).
final class SearchResultsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["검색"].tap()
    }

    @MainActor
    func testRowsShowNameRegionAndSubscription() {
        let subscribed = row(named: "금대리 계곡")
        XCTAssertTrue(subscribed.waitForExistence(timeout: 3))
        XCTAssertTrue(subscribed.label.contains("원주시 판부면"))
        XCTAssertTrue(subscribed.label.hasSuffix("구독중"))

        let notSubscribed = row(named: "안전 예시 계곡")
        XCTAssertTrue(notSubscribed.exists)
        XCTAssertTrue(notSubscribed.label.hasSuffix("구독"))
        XCTAssertFalse(notSubscribed.label.hasSuffix("구독중"))
    }

    @MainActor
    func testSearchShowsOnlyMatchingValleys() {
        XCTAssertTrue(row(named: "갑천 계곡").waitForExistence(timeout: 3))

        search("금대리")

        XCTAssertTrue(row(named: "금대리 계곡").waitForExistence(timeout: 3))
        XCTAssertFalse(row(named: "갑천 계곡").exists)
    }

    @MainActor
    func testNoMatchShowsEmptyStateWithQuery() {
        XCTAssertTrue(row(named: "금대리 계곡").waitForExistence(timeout: 3))

        search("없는계곡")

        XCTAssertTrue(app.staticTexts["'없는계곡'에 해당하는 계곡이 없어요"].waitForExistence(timeout: 3))
        XCTAssertFalse(row(named: "금대리 계곡").exists)
    }

    @MainActor
    func testRowOpensDetailOfThatValley() {
        let gapcheon = row(named: "갑천 계곡")
        XCTAssertTrue(gapcheon.waitForExistence(timeout: 3))

        gapcheon.tap()

        XCTAssertTrue(app.navigationBars["갑천 계곡"].waitForExistence(timeout: 3))
    }

    private func search(_ text: String) {
        let field = app.textFields["search.queryField"]
        field.tap()
        field.typeText(text + "\n")
    }

    /// A row is one accessibility element whose label starts with the valley name.
    private func row(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", name))
            .firstMatch
    }
}
