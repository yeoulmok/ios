import XCTest

/// APP-DTL-08 (#64): a suggested question shows the answer with the disclaimer.
/// Uses the bundled mock data (1 금대리 주의); the mock answers after a short wait.
/// Since #100 the first question asks for consent; mock runs start without it.
final class AskUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    @MainActor
    func testSuggestedQuestionShowsAnswerWithDisclaimer() {
        launchAndOpenDetail()

        tapSuggestion()

        XCTAssertTrue(app.staticTexts["ask.answer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ask.answer"].label.contains("금대리 계곡"))
        XCTAssertTrue(app.staticTexts["ask.disclaimer"].exists, "an answer never shows without the disclaimer")
        XCTAssertTrue(app.staticTexts["Q. 여기 들어가도 돼요?"].exists)
    }

    @MainActor
    func testFailureShowsServerMessage() {
        launchAndOpenDetail(extra: ["-mockAskFails"])

        tapSuggestion()

        let error = app.staticTexts["ask.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertEqual(error.label, "질문이 많아요. 잠시 후 다시 물어봐 주세요")
        XCTAssertFalse(app.staticTexts["ask.answer"].exists)
    }

    private func launchAndOpenDetail(extra: [String] = []) {
        app.launchArguments = ["-useMockData"] + extra
        app.launch()
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "금대리 계곡")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()
        XCTAssertTrue(app.staticTexts["detail.summary"].waitForExistence(timeout: 3))
    }

    /// #100: the AI notice is always under the field; the first question asks first,
    /// and "취소" sends nothing.
    @MainActor
    func testFirstQuestionAsksForConsent() {
        launchAndOpenDetail()
        let suggestion = scrollToSuggestion()
        XCTAssertTrue(app.staticTexts["ask.notice"].exists)

        suggestion.tap()
        let consent = app.alerts["AI에 질문을 보낼까요?"]
        XCTAssertTrue(consent.waitForExistence(timeout: 3))
        consent.buttons["취소"].tap()

        XCTAssertFalse(app.staticTexts["ask.answer"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Q. 여기 들어가도 돼요?"].exists)

        // Agreeing sends it; the next question does not ask again.
        suggestion.tap()
        XCTAssertTrue(consent.waitForExistence(timeout: 3))
        consent.buttons["동의하고 보내기"].tap()
        XCTAssertTrue(app.staticTexts["ask.answer"].waitForExistence(timeout: 5))
        app.buttons["ask.suggestion.1"].tap()
        XCTAssertFalse(consent.waitForExistence(timeout: 1))
    }

    private func scrollToSuggestion() -> XCUIElement {
        let suggestion = app.buttons["ask.suggestion.0"]
        for _ in 0..<5 where !suggestion.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(suggestion.isHittable)
        return suggestion
    }

    /// Taps the first suggestion and agrees to the consent popup (#100).
    private func tapSuggestion() {
        scrollToSuggestion().tap()
        let agree = app.alerts["AI에 질문을 보낼까요?"].buttons["동의하고 보내기"]
        XCTAssertTrue(agree.waitForExistence(timeout: 3))
        agree.tap()
    }
}
