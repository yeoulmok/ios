import XCTest

/// APP-NEAR-02 · 03: the nearby tab shows the closest valleys on a map and as a list
/// with distance and status; a row or a map card opens that valley's alert detail.
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

    /// APP-NEAR-03 (#58): the map shows "내 위치" and the same valleys as the list.
    @MainActor
    func testMapShowsUserAndEveryListedValley() {
        launch()
        XCTAssertTrue(app.descendants(matching: .any)["nearby.map"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["nearby.map.user"].waitForExistence(timeout: 3))
        for id in [3, 1, 4, 2, 5] {
            XCTAssertTrue(pin(id).waitForExistence(timeout: 3), "pin \(id)")
        }
        XCTAssertEqual(pin(1).label, "금대리 계곡 주의")
        XCTAssertEqual(pin(2).label, "갑천 계곡 판정 불가")
    }

    // #58 pin → card → detail is checked by hand (PR screenshots): XCUITest taps on
    // MapKit annotations do not reach MapKit's selection, while real taps do.

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

    private func pin(_ id: Int) -> XCUIElement {
        app.descendants(matching: .any)["nearby.map.pin.\(id)"]
    }

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
