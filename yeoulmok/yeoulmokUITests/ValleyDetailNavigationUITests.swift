import XCTest

/// APP-HOME-03: tapping a home card opens that valley's alert detail,
/// and going back shows the same list in the same order.
/// Uses the bundled mock data (subscribed: 1 주의, 2 판정 불가, 4 위험).
final class ValleyDetailNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testCardOpensDetailOfThatValley() {
        // Not the first card, so a "always opens the first valley" bug would fail.
        let card = card(named: "금대리 계곡")
        XCTAssertTrue(card.waitForExistence(timeout: 3))

        card.tap()

        XCTAssertTrue(app.navigationBars["금대리 계곡"].waitForExistence(timeout: 3),
                      "detail title should be the tapped valley's name")
    }

    @MainActor
    func testBackShowsSameListInSameOrder() {
        let names = ["위험 예시 계곡", "금대리 계곡", "갑천 계곡"]
        XCTAssertTrue(card(named: names[0]).waitForExistence(timeout: 3))
        let topsBefore = names.map { card(named: $0).frame.minY }

        card(named: "갑천 계곡").tap()
        XCTAssertTrue(app.navigationBars["갑천 계곡"].waitForExistence(timeout: 3))
        app.navigationBars.buttons["여울목"].tap()

        for name in names {
            XCTAssertTrue(card(named: name).waitForExistence(timeout: 3), "\(name) card after back")
        }
        let topsAfter = names.map { card(named: $0).frame.minY }
        XCTAssertEqual(topsAfter, topsBefore, "list changed after coming back from detail")
    }

    /// A card is one accessibility element whose label starts with the valley name.
    private func card(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", name))
            .firstMatch
    }
}
