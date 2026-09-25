import XCTest

final class DrawryUITests: XCTestCase {
  func testColdLaunchHasOnboardingOrPrivateHome() {
    let app = XCUIApplication()
    app.launch()
    let start = app.buttons["내 기록 시작하기"]
    if start.waitForExistence(timeout: 10) { start.tap() }
    XCTAssertTrue(app.tabBars.buttons["기록"].waitForExistence(timeout: 10))
    app.buttons["일기 작성"].tap()
    XCTAssertTrue(app.buttons["보관함"].waitForExistence(timeout: 5))
  }
}
