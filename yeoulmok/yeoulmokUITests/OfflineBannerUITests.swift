import XCTest

/// APP-COM-07: when a refresh fails, the last data stays with "○월 ○일 ○○:○○ 기준".
/// `-mockOfflineAfterFirstLoad`: each request works once, then fails like no network.
/// Mock data `updated_at` is 2026-11-07T22:00.
final class OfflineBannerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData", "-mockOfflineAfterFirstLoad"]
        app.launch()
    }

    @MainActor
    func testHomeRefreshFailureKeepsListWithBanner() {
        let header = app.staticTexts["구독한 계곡"]
        XCTAssertTrue(header.waitForExistence(timeout: 3))
        XCTAssertFalse(banner.exists, "fresh data: no banner")

        pull(from: header)

        XCTAssertTrue(banner.waitForExistence(timeout: 3))
        XCTAssertTrue(banner.label.contains("연결할 수 없어 11월 7일 22:00 기준 정보를 보여드려요"), banner.label)
        XCTAssertTrue(card("금대리 계곡").exists, "list stays")
        XCTAssertFalse(app.buttons["error.retry"].exists, "not the error screen")
    }

    @MainActor
    func testDetailRefreshFailureKeepsDetailWithBanner() {
        XCTAssertTrue(card("금대리 계곡").waitForExistence(timeout: 3))
        card("금대리 계곡").tap()
        let summary = app.staticTexts["detail.summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 3))

        pull(from: summary)

        XCTAssertTrue(banner.waitForExistence(timeout: 3))
        XCTAssertTrue(summary.exists, "detail stays")
    }

    private var banner: XCUIElement { app.descendants(matching: .any)["offlineBanner"] }

    private func card(_ name: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    private func pull(from element: XCUIElement) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 400)),
                    withVelocity: .slow, thenHoldForDuration: 0.5)
    }
}
