import XCTest

/// APP-DTL-03 (Figma 04): the alert detail shows one box per observation with
/// station, time, measured value and limit; a missing value is "-", never 0.
/// Uses the bundled mock data (1 금대리: values, 2 갑천: values missing).
final class ObservationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
    }

    @MainActor
    func testEachObservationShowsValueAndLimit() {
        open("금대리 계곡")

        let rain = app.descendants(matching: .any)["detail.observation.0"]
        let water = app.descendants(matching: .any)["detail.observation.1"]
        XCTAssertTrue(rain.exists)
        XCTAssertTrue(water.exists)
        XCTAssertTrue(rain.label.hasPrefix("강수, 원주 신림(AWS), 관측 시각 "), rain.label)
        XCTAssertTrue(rain.label.hasSuffix("실측값 18.0mm / 1시간, 기준값 15.0mm / 1시간"), rain.label)
        XCTAssertTrue(water.label.hasSuffix("실측값 +0.06m / 30분, 기준값 0.10m / 30분"), water.label)
    }

    @MainActor
    func testMissingValuesShowDashAndReasonNeverZero() {
        open("갑천 계곡")

        let rain = app.descendants(matching: .any)["detail.observation.0"]
        let water = app.descendants(matching: .any)["detail.observation.1"]
        XCTAssertTrue(rain.exists)
        XCTAssertTrue(rain.label.contains("관측 시각 -, 실측값 - (강수 자료 지연)"), rain.label)
        XCTAssertTrue(water.label.contains("실측값 - (수위 결측)"), water.label)
        for label in [rain.label, water.label] {
            XCTAssertFalse(label.contains("실측값 0"), "a missing value must not show as 0: \(label)")
        }
    }

    /// Taps the home card for `name` and waits for its detail to load.
    private func open(_ name: String) {
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3), "\(name) card")
        card.tap()
        XCTAssertTrue(app.staticTexts["detail.summary"].waitForExistence(timeout: 3), "\(name) detail")
    }
}
