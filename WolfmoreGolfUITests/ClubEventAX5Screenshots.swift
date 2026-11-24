import XCTest

/// Navigates every club-event screen at AX5 text size and attaches screenshots
/// to the XCResult bundle (extracted afterwards).
final class ClubEventAX5Screenshots: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()
    }
    override func tearDownWithError() throws { app = nil }

    // MARK: - Helpers

    private func shot(_ name: String) {
        let ss = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: ss)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    private func tapIfExists(_ element: XCUIElement, timeout: TimeInterval = 4) -> Bool {
        guard element.waitForExistence(timeout: timeout) else { return false }
        guard element.isHittable else { return false }
        element.tap()
        return true
    }

    private func back() {
        let btn = app.navigationBars.buttons.firstMatch
        if btn.exists && btn.isHittable { btn.tap(); sleep(1) }
    }

    // MARK: - Single test

    func testScreenshotAllClubEventScreensAtAX5() throws {
        sleep(2)
        shot("01_home")

        // ---- Live & Tournaments ----
        let liveCell = app.cells.containing(
            NSPredicate(format: "label CONTAINS[c] 'Live'")).firstMatch
        let liveBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Live'")).firstMatch
        let liveTap: XCUIElement = liveCell.waitForExistence(timeout: 3) ? liveCell : liveBtn
        guard tapIfExists(liveTap) else { throw XCTSkip("Live & Tournaments not reachable") }
        sleep(2)
        shot("02_live_and_tournaments")

        // ---- Club Events section visible? ----
        let clubHeading = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Club Event'")).firstMatch
        if clubHeading.waitForExistence(timeout: 3) { shot("03_club_events_section") }

        // ---- CREATE event ----
        let createBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'CREATE' OR label CONTAINS[c] 'Create'")).firstMatch
        if tapIfExists(createBtn) {
            sleep(2); shot("04_create_event"); back()
        }

        // ---- Roster screen (tap an existing event row) ----
        let eventRow = app.cells.containing(
            NSPredicate(format: "label CONTAINS[c] 'Anne' OR label CONTAINS[c] 'Manage'")).firstMatch
        if tapIfExists(eventRow) {
            sleep(2); shot("05_roster")

            // Paste roster
            let pasteBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Paste'")).firstMatch
            if tapIfExists(pasteBtn) { sleep(2); shot("06_paste_roster"); back() }

            back()
        }

        // ---- JOIN / group setup ----
        let joinBtn = app.buttons["JOIN"]
        if tapIfExists(joinBtn) {
            sleep(2); shot("07_join_or_group_setup")

            let confirm = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH[c] 'Confirm' OR label BEGINSWITH[c] 'Next' OR label BEGINSWITH[c] 'Start'")).firstMatch
            if confirm.waitForExistence(timeout: 5) { shot("08_group_setup_confirm_visible") }
            back()
        }

        // ---- Scoring screen ----
        let scoringCell = app.cells.containing(
            NSPredicate(format: "label CONTAINS[c] 'scoring' OR label CONTAINS[c] 'Hole'")).firstMatch
        if tapIfExists(scoringCell) {
            sleep(2); shot("09_scoring")

            // Pick-up and toast
            let pickUp = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH[c] 'Pick up'")).firstMatch
            if tapIfExists(pickUp, timeout: 3) {
                sleep(1); shot("10_pickup_toast")
                let undo = app.buttons["pickUpUndoButton"]
                if undo.exists { undo.tap(); sleep(1) }
            }

            // Review & Submit
            let reviewBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Review' OR label CONTAINS[c] 'Submit Card'")).firstMatch
            if tapIfExists(reviewBtn) { sleep(2); shot("11_review_submit"); back() }

            // Leaderboard
            let lbBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Leaderboard'")).firstMatch
            if tapIfExists(lbBtn) {
                sleep(2); shot("12_leaderboard_teams")

                // Skins tab
                let skinsTab = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS[c] 'Skins'")).firstMatch
                if tapIfExists(skinsTab, timeout: 2) {
                    sleep(1); shot("13_leaderboard_skins")
                    app.swipeUp(); sleep(1); shot("13b_leaderboard_skins_holes")
                }
                back()
            }

            back()
        }

        // ---- Dashboard ----
        let dashBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Dashboard' OR label CONTAINS[c] 'Manage'")).firstMatch
        if tapIfExists(dashBtn) { sleep(2); shot("14_dashboard"); back() }
    }
}
