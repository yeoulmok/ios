import XCTest

/// APP-COM-05: "자료 지연" for late observations, and pull to refresh keeps the list.
/// Uses the bundled mock data (home: 4 위험 stale, 1 주의 fresh, 2 판정 불가 stale).
final class StaleRefreshUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
    }

    @MainActor
    func testStaleLabelOnlyOnLateCards() {
        XCTAssertTrue(card("금대리 계곡").waitForExistence(timeout: 3))

        XCTAssertTrue(card("위험 예시 계곡").label.contains("자료 지연"))
        XCTAssertFalse(card("금대리 계곡").label.contains("자료 지연"))
        // Late and unknown: both shown, and "판정 불가" is not "안전".
        let unknown = card("갑천 계곡").label
        XCTAssertTrue(unknown.contains("자료 지연"), unknown)
        XCTAssertTrue(unknown.contains("판정 불가"), unknown)
        XCTAssertFalse(unknown.contains("안전"), unknown)
    }

    @MainActor
    func testDetailShowsStaleOnlyWhenLate() {
        open("위험 예시 계곡")
        XCTAssertTrue(app.descendants(matching: .any)["staleLabel"].exists)
        app.navigationBars.buttons["여울목"].tap()

        open("금대리 계곡")
        XCTAssertFalse(app.descendants(matching: .any)["staleLabel"].exists)
    }

    @MainActor
    func testPullToRefreshKeepsTheList() {
        let names = ["위험 예시 계곡", "금대리 계곡", "갑천 계곡"]
        XCTAssertTrue(card(names[0]).waitForExistence(timeout: 3))

        let header = app.staticTexts["구독한 계곡"]
        let start = header.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 400)),
                    withVelocity: .slow, thenHoldForDuration: 0.5)

        for name in names {
            XCTAssertTrue(card(name).waitForExistence(timeout: 3), "\(name) after refresh")
        }
        let tops = names.map { card($0).frame.minY }
        XCTAssertEqual(tops, tops.sorted(), "same order after refresh")
    }

    private func card(_ name: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    private func open(_ name: String) {
        XCTAssertTrue(card(name).waitForExistence(timeout: 3), "\(name) card")
        card(name).tap()
        XCTAssertTrue(app.staticTexts["detail.summary"].waitForExistence(timeout: 3), "\(name) detail")
    }
}
