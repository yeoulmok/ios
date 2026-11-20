import XCTest

/// APP-HOME-01: subscribed valleys appear as cards, most urgent first.
/// Uses the bundled mock data (subscribed: 1 주의, 2 판정 불가, 4 위험).
final class HomeListUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
    }

    @MainActor
    func testCardsAreShownMostUrgentFirst() {
        let names = ["위험 예시 계곡", "금대리 계곡", "갑천 계곡"]
        let cards = names.map(card(named:))
        for (name, card) in zip(names, cards) {
            XCTAssertTrue(card.waitForExistence(timeout: 3), "\(name) card")
        }

        let tops = cards.map(\.frame.minY)
        XCTAssertEqual(tops, tops.sorted(), "cards are not in 위험 › 주의 › 판정 불가 order")
    }

    @MainActor
    func testUnknownCardShowsDashesNotZero() {
        let unknown = card(named: "갑천 계곡")
        XCTAssertTrue(unknown.waitForExistence(timeout: 3))
        XCTAssertTrue(unknown.label.contains("판정 불가"))
        XCTAssertTrue(unknown.label.contains("상류 1시간 강수 - · 하류 30분 상승 -"))
    }

    /// APP-HOME-02: "+ 계곡 추가" takes the user to the search tab.
    @MainActor
    func testAddValleyOpensSearchTab() {
        let addButton = app.buttons["계곡 추가"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["홈"].isSelected)

        addButton.tap()

        XCTAssertTrue(app.tabBars.buttons["검색"].isSelected)
        XCTAssertTrue(app.textFields["search.queryField"].waitForExistence(timeout: 2))
    }

    /// A card is one accessibility element whose label starts with the valley name.
    private func card(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", name))
            .firstMatch
    }
}
