import XCTest

/// APP-COM-01: the three bottom tabs switch, and each tab keeps its state.
final class TabNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testTabsAppearInOrderAndHomeIsSelected() {
        let buttons = app.tabBars.buttons
        XCTAssertEqual(buttons.count, 3)
        XCTAssertEqual((0..<3).map { buttons.element(boundBy: $0).label }, ["홈", "근처", "검색"])
        XCTAssertTrue(buttons["홈"].isSelected)
    }

    @MainActor
    func testSelectingTabHighlightsIt() {
        app.tabBars.buttons["근처"].tap()

        XCTAssertTrue(app.tabBars.buttons["근처"].isSelected)
        XCTAssertFalse(app.tabBars.buttons["홈"].isSelected)
    }

    @MainActor
    func testSearchTextSurvivesTabSwitch() {
        app.tabBars.buttons["검색"].tap()
        let field = app.textFields["search.queryField"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        field.typeText("금대")

        app.tabBars.buttons["홈"].tap()
        app.tabBars.buttons["검색"].tap()

        XCTAssertEqual(app.textFields["search.queryField"].value as? String, "금대")
    }
}
