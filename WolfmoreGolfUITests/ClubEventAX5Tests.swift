import XCTest

final class ClubEventAX5Tests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // Navigates from the Club Events tab to the Group Setup screen and verifies
    // that the Confirm (or Next) button is reachable at AX5 text size.
    func testGroupSetupConfirmHittableAtAX5() throws {
        app.launch()

        // Tap the Club Events tab
        let clubEventsTab = app.tabBars.buttons["Club Events"]
        guard clubEventsTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("Club Events tab not visible — login required")
        }
        clubEventsTab.tap()

        // Look for a JOIN button to enter the group setup flow
        let joinButton = app.buttons["JOIN"]
        guard joinButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("No active Club Event with JOIN visible")
        }
        joinButton.tap()

        // After joining, the group setup screen appears.
        // The Confirm / Next / Start Scoring button must be reachable.
        let confirm = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH[c] 'Confirm' OR label BEGINSWITH[c] 'Next' OR label BEGINSWITH[c] 'Start Scoring'")
        ).firstMatch

        XCTAssertTrue(
            confirm.waitForExistence(timeout: 10),
            "Confirm/Next/Start Scoring button not found at AX5 text size"
        )
        XCTAssertTrue(confirm.isHittable, "Confirm/Next/Start Scoring button is not hittable at AX5")
    }

    // Verifies that the scoring screen's +/− buttons are at least 44pt at AX5.
    func testScoringButtonsMinimumTouchTargetAtAX5() throws {
        app.launch()

        let clubEventsTab = app.tabBars.buttons["Club Events"]
        guard clubEventsTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("Club Events tab not visible — login required")
        }
        clubEventsTab.tap()

        let scoringCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] 'scoring'")).firstMatch
        guard scoringCell.waitForExistence(timeout: 3) else {
            throw XCTSkip("No scoring session in progress")
        }
        scoringCell.tap()

        let plusButtons = app.buttons.matching(NSPredicate(format: "label == '+'"))
        if plusButtons.count > 0 {
            let btn = plusButtons.firstMatch
            XCTAssertGreaterThanOrEqual(btn.frame.width, 44, "+ button width < 44pt at AX5")
            XCTAssertGreaterThanOrEqual(btn.frame.height, 44, "+ button height < 44pt at AX5")
        }

        let minusButtons = app.buttons.matching(NSPredicate(format: "label == '−' OR label == '-'"))
        if minusButtons.count > 0 {
            let btn = minusButtons.firstMatch
            XCTAssertGreaterThanOrEqual(btn.frame.width, 44, "− button width < 44pt at AX5")
            XCTAssertGreaterThanOrEqual(btn.frame.height, 44, "− button height < 44pt at AX5")
        }
    }

    // Verifies the "Pick up" button is ≥44pt tall at AX5 text size.
    func testPickUpButtonMinimumTouchTargetAtAX5() throws {
        app.launch()

        let clubEventsTab = app.tabBars.buttons["Club Events"]
        guard clubEventsTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("Club Events tab not visible — login required")
        }
        clubEventsTab.tap()

        let scoringCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] 'scoring'")).firstMatch
        guard scoringCell.waitForExistence(timeout: 3) else {
            throw XCTSkip("No scoring session in progress")
        }
        scoringCell.tap()

        // "Pick up" button lives inside each score cell; find the first one
        let pickUpBtn = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'Pick up'")).firstMatch
        guard pickUpBtn.waitForExistence(timeout: 5) else {
            throw XCTSkip("No 'Pick up' button found on scoring screen")
        }
        XCTAssertGreaterThanOrEqual(pickUpBtn.frame.height, 44,
            "'Pick up' button height < 44pt at AX5")
    }

    // Verifies that after tapping "Pick up" the Undo toast appears and
    // the bottom-bar buttons (Submit Card / Leaderboard) remain hittable.
    func testPickUpToastDoesNotCoverBottomButtonsAtAX5() throws {
        app.launch()

        let clubEventsTab = app.tabBars.buttons["Club Events"]
        guard clubEventsTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("Club Events tab not visible — login required")
        }
        clubEventsTab.tap()

        let scoringCell = app.cells.containing(NSPredicate(format: "label CONTAINS[c] 'scoring'")).firstMatch
        guard scoringCell.waitForExistence(timeout: 3) else {
            throw XCTSkip("No scoring session in progress")
        }
        scoringCell.tap()

        let pickUpBtn = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'Pick up'")).firstMatch
        guard pickUpBtn.waitForExistence(timeout: 5) else {
            throw XCTSkip("No 'Pick up' button found on scoring screen")
        }
        pickUpBtn.tap()

        // Toast must appear with Undo button
        let undoBtn = app.buttons["pickUpUndoButton"]
        XCTAssertTrue(undoBtn.waitForExistence(timeout: 2), "Undo toast did not appear after tapping Pick up")

        // Bottom-bar buttons must remain hittable despite the toast
        let bottomButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Submit' OR label CONTAINS[c] 'Leaderboard'")
        ).firstMatch
        if bottomButton.exists {
            XCTAssertTrue(bottomButton.isHittable,
                "Bottom bar button is obscured by the Undo toast at AX5 text size")
        }
    }
}
