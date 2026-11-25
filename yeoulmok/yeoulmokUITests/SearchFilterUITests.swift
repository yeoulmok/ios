import XCTest

/// APP-SRCH-04 (#96): province · city chips, 20 valleys at a time, and the empty
/// screen with a filter on. Uses the real server's 126 valleys as mock data
/// (`-mockManyValleys`: 강원 111, other provinces 1 each; a page every 0.6 s).
final class SearchFilterUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-mockManyValleys"]
        app.launch()
        app.tabBars.buttons["검색"].tap()
    }

    @MainActor
    func testProvinceChipNarrowsTheListAndShowsCities() {
        let gangwon = app.buttons["search.province.강원"]
        XCTAssertTrue(gangwon.waitForExistence(timeout: 5))
        XCTAssertEqual(gangwon.label, "강원, 111곳")
        XCTAssertFalse(app.buttons["search.city.all"].exists)

        // Chips past the screen edge are reached by swiping the row; 경기 is in view.
        app.buttons["search.province.경기"].tap()

        XCTAssertTrue(row(named: "수동면 구운천").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1곳 모두 봤어요"].waitForExistence(timeout: 3))
        // 경기 has one city: no city row.
        XCTAssertFalse(app.buttons["search.city.all"].exists)

        app.buttons["search.province.강원"].tap()

        XCTAssertTrue(app.buttons["search.city.횡성군"].waitForExistence(timeout: 5))
        app.buttons["search.city.횡성군"].tap()
        XCTAssertTrue(app.staticTexts["횡성군"].waitForExistence(timeout: 5))
        XCTAssertFalse(row(named: "수동면 구운천").exists)
    }

    @MainActor
    func testScrollingToTheEndLoadsEveryPage() {
        app.buttons["search.province.강원"].tap()
        XCTAssertTrue(app.buttons["search.city.횡성군"].waitForExistence(timeout: 5))
        // 강원 111 = 6 pages; the end row loads the next one each time it shows.
        let end = app.staticTexts["111곳 모두 봤어요"]
        for _ in 0..<30 where !end.exists {
            app.swipeUp(velocity: .fast)
        }

        XCTAssertTrue(end.waitForExistence(timeout: 5))
    }

    @MainActor
    func testEmptyWithFilterOffersToSearchEverywhere() {
        app.buttons["search.province.경기"].tap()
        XCTAssertTrue(row(named: "수동면 구운천").waitForExistence(timeout: 5))

        search("도림천")

        XCTAssertTrue(app.staticTexts["경기에는 '도림천' 계곡이 없어요"].waitForExistence(timeout: 5))
        app.buttons["search.clearFilter"].tap()

        XCTAssertTrue(row(named: "신림동 도림천").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["search.province.all"].isSelected)
    }

    private func search(_ text: String) {
        let field = app.textFields["search.queryField"]
        field.tap()
        field.typeText(text + "\n")
    }

    /// A row: its label starts with the valley name (see SearchResultRow).
    private func row(named name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'search.row.' AND label BEGINSWITH %@", name))
            .firstMatch
    }
}
