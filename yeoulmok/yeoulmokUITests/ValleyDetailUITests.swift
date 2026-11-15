import XCTest

/// APP-DTL-01 (Figma 04): the alert detail header shows the name, the level badge
/// and the one-line summary, and the tab bar is hidden.
/// Uses the bundled mock data (home: 4 위험, 1 주의, 2 판정 불가).
final class ValleyDetailUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
    }

    @MainActor
    func testDetailShowsNameBadgeAndSummary() {
        open("금대리 계곡")

        XCTAssertTrue(app.navigationBars["금대리 계곡"].exists)
        XCTAssertTrue(element(labeled: "상태: 주의").exists, "level badge")
        let summary = app.staticTexts["detail.summary"]
        XCTAssertTrue(summary.exists)
        XCTAssertEqual(summary.label, "상류에 비가 많이 오고 있어요")
        XCTAssertTrue(element(labeled: "자료: 한강홍수통제소, 기상청").exists, "data source line")
    }

    @MainActor
    func testUnknownLevelShowsJudgmentUnavailableBadge() {
        open("갑천 계곡")

        // "판정 불가" must never look like "안전" (feature spec 3-1).
        XCTAssertTrue(element(labeled: "상태: 판정 불가").exists)
        XCTAssertFalse(element(labeled: "상태: 안전").exists)
        XCTAssertEqual(app.staticTexts["detail.summary"].label, "관측 자료가 늦거나 없어 판정할 수 없어요")
    }

    @MainActor
    func testTabBarIsHiddenOnDetailAndBackAfterReturning() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 3))

        open("금대리 계곡")
        XCTAssertFalse(app.tabBars.firstMatch.isHittable, "Figma 04 has no tab bar")

        app.navigationBars.buttons["여울목"].tap()
        XCTAssertTrue(app.tabBars.buttons["홈"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["홈"].isHittable)
    }

    /// Taps the home card for `name` and waits for its detail to load.
    private func open(_ name: String) {
        let card = element(labeled: name, beginsWith: true)
        XCTAssertTrue(card.waitForExistence(timeout: 3), "\(name) card")
        card.tap()
        XCTAssertTrue(app.staticTexts["detail.summary"].waitForExistence(timeout: 3), "\(name) detail")
    }

    private func element(labeled label: String, beginsWith: Bool = false) -> XCUIElement {
        let format = beginsWith ? "label BEGINSWITH %@" : "label == %@"
        return app.descendants(matching: .any).matching(NSPredicate(format: format, label)).firstMatch
    }
}
