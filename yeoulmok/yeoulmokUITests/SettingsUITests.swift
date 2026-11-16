import XCTest

/// APP-SET-02: settings opens from home's gear and lists terms, privacy policy, data source,
/// contact and the app version (Figma 06).
final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useMockData"]
        app.launch()
        app.buttons["home.settings"].tap()
        XCTAssertTrue(app.navigationBars["설정"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testListsEveryRowAndTheSource() {
        for id in ["terms", "privacy", "dataSource", "contact", "version"] {
            XCTAssertTrue(app.descendants(matching: .any)["settings.\(id)"].exists, id)
        }
        XCTAssertTrue(app.staticTexts["자료: 한강홍수통제소, 기상청"].exists)
        XCTAssertFalse(app.tabBars.firstMatch.isHittable, "tab bar is hidden, like the detail")
    }

    @MainActor
    func testVersionMatchesTheBuild() throws {
        // The UI test target gets the same MARKETING_VERSION as the app.
        let version = try XCTUnwrap(Bundle(for: Self.self).infoDictionary?["CFBundleShortVersionString"] as? String)
        let row = app.descendants(matching: .any)["settings.version"]
        XCTAssertTrue(app.staticTexts[version].exists || row.label.contains(version),
                      "version row: \(row.label)")
    }

    @MainActor
    func testDataSourceOpensAndComesBack() {
        app.buttons["settings.dataSource"].tap()

        XCTAssertTrue(app.navigationBars["데이터 출처"].waitForExistence(timeout: 3))
        // `LabeledContent` reads as one element ("하천 수위, 한강홍수통제소"), so match a part.
        XCTAssertTrue(element(containing: "한강홍수통제소").exists)
        XCTAssertTrue(element(containing: "기상청").exists)

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["설정"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testBackGoesToHome() {
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["여울목"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["홈"].isHittable)
    }

    private func element(containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}
