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

    /// APP-DTL-09 (#90): the "최근 3시간" card with rain and water, and level marks.
    @MainActor
    func testDangerShowsHistoryCardAndLevelMarks() {
        openDetail(4)
        let history = app.descendants(matching: .any)["detail.history"]
        XCTAssertTrue(history.waitForExistence(timeout: 3))
        XCTAssertEqual(history.label, "최근 3시간, 강수 1시간 0.0mm에서 32.5mm, 수위 0.21m에서 0.61m")
        let rain = app.descendants(matching: .any)["detail.observation.0"]
        XCTAssertEqual(rain.value as? String, "24시간 강수 58.5mm")
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
