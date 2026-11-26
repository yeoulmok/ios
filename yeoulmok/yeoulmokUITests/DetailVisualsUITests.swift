import XCTest

/// APP-DTL-07 (#63): level card, gauge cards, AI estimate and AI explanation on the detail.
/// Opens a detail directly with `-mockPushValleyID` (as if its push was tapped).
final class DetailVisualsUITests: XCTestCase {
    private var app: XCUIApplication!

    private func openDetail(_ valleyID: Int) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData", "-mockPushValleyID", "\(valleyID)"]
        app.launch()
        XCTAssertTrue(app.staticTexts["detail.summary"].waitForExistence(timeout: 5))
    }

    /// 위험 예시 계곡: level scale on 위험, AI explanation shown, no AI estimate.
    @MainActor
    func testDangerShowsScaleAndAIExplanation() {
        openDetail(4)
        let scale = app.descendants(matching: .any)["levelScale"]
        XCTAssertTrue(scale.exists)
        XCTAssertEqual(scale.label, "단계 위험")
        XCTAssertTrue(app.descendants(matching: .any)["detail.aiExplanation"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["detail.estimated"].exists)
    }

    /// APP-DTL-09 (#90): "최근 3시간" for rain and water. Since #107 each chart sits in
    /// its own card, so each card reads its range after the 24-hour rain.
    @MainActor
    func testDangerShowsHistoryInsideTheCards() {
        openDetail(4)
        let rain = app.descendants(matching: .any)["detail.observation.0"]
        XCTAssertTrue(rain.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForValue(rain, "24시간 강수 58.5mm, 최근 3시간 0.0mm에서 32.5mm"))
        let water = app.descendants(matching: .any)["detail.observation.1"]
        XCTAssertEqual(water.value as? String, "최근 3시간 수위 0.21m에서 0.61m")
        XCTAssertFalse(app.descendants(matching: .any)["detail.history"].exists)
    }

    /// The history arrives a moment after the detail.
    private func waitForValue(_ element: XCUIElement, _ value: String) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: element)
        return XCTWaiter.wait(for: [expectation], timeout: 3) == .completed
    }

    /// 갑천 계곡 (판정 불가, no water gauge): AI estimate card, no AI explanation.
    @MainActor
    func testUnknownWithAIEstimate() {
        openDetail(2)
        XCTAssertEqual(app.descendants(matching: .any)["levelScale"].label, "단계 판정 불가")
        XCTAssertTrue(app.descendants(matching: .any)["detail.estimated"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["detail.aiExplanation"].exists)

        let estimate = app.descendants(matching: .any)["detail.observation.2"]
        XCTAssertTrue(estimate.waitForExistence(timeout: 3))
        XCTAssertTrue(estimate.label.hasPrefix("AI 추정 수위, "), estimate.label)
        XCTAssertTrue(estimate.label.contains("실측값 +0.04m / 3시간"), estimate.label)
    }
}
