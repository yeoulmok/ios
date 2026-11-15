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
        // The row is two parts: name · region (opens detail) and the subscription button.
        let geumdaeri = row(named: "금대리 계곡")
        XCTAssertTrue(geumdaeri.waitForExistence(timeout: 3))
        XCTAssertTrue(geumdaeri.label.contains("원주시 판부면"))

        XCTAssertEqual(subscriptionButton(valleyID: 1).label, "금대리 계곡 구독중")
        XCTAssertEqual(subscriptionButton(valleyID: 3).label, "안전 예시 계곡 구독")
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

    /// "구독" / "구독중" button of a row (see SearchResultRow).
    private func subscriptionButton(valleyID: Int) -> XCUIElement {
        app.buttons["search.subscription.\(valleyID)"]
    }

    /// The name · region part of a row: its label starts with the valley name.
    /// The subscription button's label also starts with the name, so it is excluded.
    private func row(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(
                format: "label BEGINSWITH %@ AND NOT (identifier BEGINSWITH 'search.subscription')", name
            ))
            .firstMatch
    }
}
