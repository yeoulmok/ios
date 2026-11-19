import XCTest

/// APP-HOME-03: tapping a home card opens that valley's alert detail,
/// and going back shows the same list in the same order.
/// Uses the bundled mock data (subscribed: 1 주의, 2 판정 불가, 4 위험).
final class ValleyDetailNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
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
        // Positions relative to the first card: the list may be scrolled when coming back
        // (since #59 the featured card pushes 갑천 below the tab bar, so the tap scrolls).
        let topsBefore = relativeTops(names)

        card(named: "갑천 계곡").tap()
        XCTAssertTrue(app.navigationBars["갑천 계곡"].waitForExistence(timeout: 3))
        app.navigationBars.buttons["여울목"].tap()

        for name in names {
            XCTAssertTrue(card(named: name).waitForExistence(timeout: 3), "\(name) card after back")
        }
        let topsAfter = relativeTops(names)
        XCTAssertEqual(topsAfter, topsBefore, "list changed after coming back from detail")
    }

    private func relativeTops(_ names: [String]) -> [CGFloat] {
        let tops = names.map { card(named: $0).frame.minY }
        return tops.map { ($0 - tops[0]).rounded() }
    }

    /// A card is one accessibility element whose label starts with the valley name.
    private func card(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", name))
            .firstMatch
    }
}
