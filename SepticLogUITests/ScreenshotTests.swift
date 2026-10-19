import XCTest

/// Captures App Store screenshots. Run with scripts/screenshots.sh SepticLog.
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testAppScreens() {
        let app = XCUIApplication()
        app.launchArguments = ["-unlock", "-resetData", "-sampleData", "-skipOnboarding", "-uiTesting"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 15))
        sleep(1)
        snap("01-timeline", app)

        app.buttons["More"].firstMatch.tap()
        app.buttons["Record service"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Record service"].waitForExistence(timeout: 5))
        sleep(1)
        snap("02-record-service", app)
        app.buttons["Cancel"].firstMatch.tap()

        app.buttons["More"].firstMatch.tap()
        app.buttons["System details"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["System details"].waitForExistence(timeout: 5))
        sleep(1)
        snap("03-system", app)
        app.buttons["Done"].firstMatch.tap()

        app.buttons["More"].firstMatch.tap()
        app.buttons["Measure the tank"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Measure the tank"].waitForExistence(timeout: 5))
        sleep(1)
        snap("04-measure", app)
        app.buttons["Cancel"].firstMatch.tap()

        XCTAssertTrue(app.buttons["How do I use this app?"].waitForExistence(timeout: 5))
        app.buttons["How do I use this app?"].tap()
        sleep(1)
        snap("05-how-to", app)
    }

    func testPaywall() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-uiTesting", "-mockPrices"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lifetime"].waitForExistence(timeout: 10))
        snap("paywall", app)
    }

    private func snap(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
