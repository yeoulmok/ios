import XCTest

/// APP-NEAR-02: the nearby tab lists the closest valleys with distance and status,
/// and a row opens that valley's alert detail.
/// `-mockLocation` puts the user in downtown Wonju (`SystemLocationPermission.mockLocation`),
/// so with the mock valleys the order is 3 · 1 · 4 · 2 · 5.
final class NearbyListUITests: XCTestCase {
    private var app: XCUIApplication!
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    private func launch(_ arguments: [String] = []) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData", "-mockLocation"] + arguments
        // Same as NearbyPermissionUITests: launch, reset (iOS ends the app), launch again.
        app.launch()
        app.resetAuthorizationStatus(for: .location)
        app.launch()
        app.tabBars.buttons["근처"].tap()
        allowLocation()
    }

    @MainActor
    func testClosestFirstWithDistanceAndStatus() {
        launch()
        XCTAssertTrue(row(1).waitForExistence(timeout: 5))

        let order = [3, 1, 4, 2, 5]
        let tops = order.map { row($0).frame.minY }
        XCTAssertEqual(tops, tops.sorted(), "rows should be closest first: \(order)")

        let label = row(1).label
        XCTAssertTrue(label.contains("금대리 계곡"), label)
        XCTAssertTrue(label.contains("km"), label)
        XCTAssertTrue(label.contains("주의"), label)
        XCTAssertTrue(row(4).label.contains("자료 지연"), "stale valley: \(row(4).label)")
        XCTAssertTrue(app.staticTexts["자료: 한강홍수통제소, 기상청"].exists)
    }

    @MainActor
    func testRowOpensDetailOfThatValley() {
        launch()
        XCTAssertTrue(row(1).waitForExistence(timeout: 5))

        // Not the first row, so an "always opens the first valley" bug would fail.
        row(1).tap()

        XCTAssertTrue(app.navigationBars["금대리 계곡"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testRefreshFailureKeepsListWithBanner() {
        launch(["-mockOfflineAfterFirstLoad"])
        let header = app.staticTexts["nearby.allowed"]
        XCTAssertTrue(row(1).waitForExistence(timeout: 5))
        XCTAssertFalse(banner.exists, "fresh data: no banner")

        let start = header.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 400)),
                    withVelocity: .slow, thenHoldForDuration: 0.5)

        XCTAssertTrue(banner.waitForExistence(timeout: 3))
        XCTAssertTrue(row(1).exists, "list stays")
    }

    private var banner: XCUIElement { app.descendants(matching: .any)["offlineBanner"] }

    private func row(_ id: Int) -> XCUIElement {
        app.descendants(matching: .any)["nearby.row.\(id)"].firstMatch
    }

    private func allowLocation() {
        let alert = springboard.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "location alert")
        let button = alert.buttons.matching(NSPredicate(format: "label == %@ OR label == %@",
                                                        "Allow While Using App", "앱을 사용하는 동안 허용")).firstMatch
        XCTAssertTrue(button.exists, "buttons: \(alert.buttons.allElementsBoundByIndex.map(\.label))")
        button.tap()
    }
}
