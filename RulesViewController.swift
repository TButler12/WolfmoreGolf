//
//  RulesViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/8/25.
//

import UIKit

final class RulesViewController: UIViewController {

    // MARK: - UI
    private let textView = UITextView(frame: .zero)
    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Data
    private lazy var baseAttributedText: NSAttributedString = makeRulesText()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Rules"
        view.backgroundColor = .systemBackground

        configureTextView()
        configureSearch()
        configureCloseIfModal()

        // Initial content
        textView.attributedText = baseAttributedText
    }
}

// MARK: - Setup
private extension RulesViewController {

    func configureTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.backgroundColor = .clear

        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        textView.adjustsFontForContentSizeCategory = true

        // Default alignment for everything
        textView.textAlignment = .left

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func configureSearch() {
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search rules"
        definesPresentationContext = true
    }

    func configureCloseIfModal() {
        // Show Close button when presented modally (with or without nav controller)
        if presentingViewController != nil || navigationController?.presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
            )
        }
    }
}

// MARK: - Search updating + highlight
extension RulesViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let query = (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            // Reset to full styled rules
            textView.attributedText = baseAttributedText
            return
        }

        // Highlight matches on a mutable copy
        let highlighted = NSMutableAttributedString(attributedString: baseAttributedText)

        let fullString = highlighted.string
        let fullNSString = fullString as NSString
        let lowerFull = fullString.lowercased()
        let lowerQuery = query.lowercased()

        var firstMatch: NSRange?

        var searchRange = NSRange(location: 0, length: fullNSString.length)
        while true {
            let foundRange = (lowerFull as NSString).range(of: lowerQuery, options: [], range: searchRange)
            if foundRange.location == NSNotFound { break }

            // record first match
            if firstMatch == nil { firstMatch = foundRange }

            // highlight
            highlighted.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.35), range: foundRange)
            highlighted.addAttribute(.foregroundColor, value: UIColor.label, range: foundRange)

            // move forward
            let nextLoc = foundRange.location + max(foundRange.length, 1)
            if nextLoc >= fullNSString.length { break }
            searchRange = NSRange(location: nextLoc, length: fullNSString.length - nextLoc)
        }

        textView.attributedText = highlighted

        // Scroll to first match
        if let r = firstMatch {
            textView.scrollRangeToVisible(r)
        }
    }
}

// MARK: - Rules content builder
private extension RulesViewController {
    
    func makeRulesText() -> NSAttributedString {
        let text = NSMutableAttributedString()
        
        func header(_ str: String) {
            text.append(NSAttributedString(
                string: "\(str)\n",
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 22),
                    .foregroundColor: UIColor.label
                ]
            ))
            text.append(NSAttributedString(string: "────────────────────\n",
                                           attributes: [
                                            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                                            .foregroundColor: UIColor.tertiaryLabel
                                           ]))
        }
        
        func body(_ str: String) {
            text.append(NSAttributedString(
                string: "\(str)\n\n",
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.secondaryLabel
                ]
            ))
        }
        
        header("WOLFMORE — HOW TO PLAY")
        body("""
        Scoring and bet tracking made easy!

        Play multiple games at the same time, including Remote Nassau.

        Remote Nassau allows play between players at different courses!

        Hover or long press over most buttons for a description of that button.

        Play up to 5 players. Yes, 5 players — and 3 vs 2 Wolf can be the most fun.

        Set your course, add players through the New Game button, and start scoring.

        Supports Wolf, Six-Point Scotch, Hammer, Nassau, and Skins — all running together.

        Live & Tournaments lets you run live tournaments, spectate Wolf games in real time, and challenge friends to Remote Nassau.

        WolfMore is perfect for competing on your home course, tracking stats with friends, playing away-course games, and even indoor simulator golf.

        Enter scores once. Play every game.
        """)

        header("GETTING STARTED")
        body("""
        • Set your course pars and handicaps
        • Select a Home Course if you want personal stat tracking for you and your friends. This data stays on your phone
        • Press "New Game" and select up to 5 players
        • If you're new to WolfMore, first add players and activate them through the New Game screen
        • Add new players using the New Game button
        """)

        header("GAME SETUP")
        body("""
        Access game settings before or during a round to customize your game.

        • Tap "Edit stake & format" on the pre-round screen to open Game Settings
        • Adjust Wolf scoring style: 6-Point Scotch, Wolf 2pt, Wolf LowBall
        • Set Hammer style: Doubling (2× → 4× → 8×) or Additive (2× → 3× → 4×)
        • Toggle Umbrella (sweep rule) on or off
        • Change base stake amount
        • During a round: tap ⓘ on the scoring screen to change course, adjust handicaps, or get scoring tips

        Nassau Settings:
        • Set Nassau stake independently from main game
        • Configure auto-press rules (holes down trigger)
        • Select which players are included in Nassau matches

        Skins Settings:
        • Set skin value (bet per skin)
        • Toggle carryovers on or off
        • Select which players are included in Skins

        Changes to game settings take effect immediately and apply to remaining holes.
        """)

        header("COURSES")
        body("""
        • WolfMore includes built-in courses plus any custom courses you add
        • Built-in courses help you get started quickly and may include phone, website, address, and other course details
        • On the course picker, swipe left to mark a course as your Home Course
        • Swipe right on a course for more information including phone, website, address, and available details
        • Your Home Course is used for personal stats, comparisons, and tracking over time
        • To add a custom course: tap the course picker, then tap 'Add Course' — enter the course name, then set par and handicap for each hole. Custom courses are saved and available for all future rounds.
        """)

        header("TEE SELECTION")
        body("""
        Players in the same group can play from different tees — WolfMore scores each player against their own tee's pars and handicap ratings.

        • On the pre-round player setup screen, tap "Default" next to any player's name to choose their tee
        • Available tees are pulled from the selected course (e.g. Blue, White, Red)
        • "Default" means the course's standard tee is used for that player
        • Each player's tee choice is saved and remembered for future rounds on that course

        How it affects scoring:
        • Handicap strokes are allocated based on each player's tee stroke index, not a shared index
        • In Stableford tournaments, points are calculated against that player's tee pars
        • Wolf, Nassau, and Skins all honor per-player tee pars and handicaps automatically

        Tee selection is optional — if everyone plays the same tee, leave all players set to Default.
        """)

        header("SCORING")
        body("""
        Enter scores → Select options → Update Scores

        • All scoring happens from one screen
        • Results update instantly across all games
        • Alone, Re-Roll, Roll buttons assign wolf decision for each hole
        • Press and Hammer steppers show current multiplier

        W = Wolf partners
        P = Prox (closest to pin)

        • To mute a player mid-round (e.g. they leave early), long press their name on the scoring page. Their scores from holes already played are kept.
        """)

        header("PASS GAME TO ANOTHER PHONE")
        body("""
        Hand off the scorecard mid-round so someone else can keep score.

        • Tap the ⓘ info button on the scoring screen and choose "Pass Game to Another Phone"
        • Share via AirDrop or iMessage — the recipient taps the link and WolfMore opens directly with the game loaded and ready to continue
        • The game transfers at the current hole so no scores are lost
        """)

        header("WAGERS")
        body("""
        • Default wager is $2.00
        • Use + / – to adjust for the current hole or the entire game
        • Tap $ to apply wager across all holes

        Wagers affect your main game (Wolf / Scotch / Hammer)
        """)

        header("GAME MODES — ALL MODES ARE ACCESSED FROM THE IN-GAME SCORING PAGE")
        body("""
        • Six-Point Scotch (default)
        • Wolf (2 Point)
        • Wolf (1 Point)
        • Hammer
        • Wolf Live (real-time spectator mode)
        • Match Play
        • Best Ball
        • Scramble (tournament format — see SCRAMBLE below)

        • Nassau and Skins run automatically as side games
        • You can change game modes mid-round if you want to mix it up

        From the scoring page, two buttons give direct access to live features:
        • Live Wolf — start or share a live spectator session (replaces the old Game Settings flow)
        • Tournament — join or view the current tournament leaderboard
        """)

        header("MATCH PLAY")
        body("""
        • Fixed teams assigned before the round
        • Each hole is won, lost, or halved
        • The team that wins more holes wins the match
        • A stake is paid per hole — no accumulation
        • The match ends when one team leads by more holes than remain
        • Handicap strokes apply on the holes with the lowest stroke index
        • Supports 36-hole rounds (same course played twice back-to-back)
        • Dual Match: two simultaneous 1v1 matches within the group
        """)

        header("BEST BALL")
        body("""
        • Fixed teams assigned before the round
        • Each player plays their own ball every hole
        • The best net score on each team counts for that hole
        • Running totals accumulate across all 18 holes — no per-hole stake
        • The team with the lowest cumulative best-net total wins
        • Handicap strokes apply using each player's index vs the field's lowest
        • Needs 2+ players per team (Dual Match not available)
        """)

        header("SCRAMBLE")
        body("""
        Team format where all players tee off, the best shot is chosen, and everyone plays from that spot.

        • Start a Scramble tournament via Live & Tournaments → Create Tournament → Scramble
        • All groups join with the same 6-character code
        • Scores submit to a shared real-time leaderboard automatically when Update Scores is tapped

        How scoring works:
        • Each group plays as a team — enter the team's score for each hole
        • Net scoring: team handicap is applied automatically based on the players in the group
        • The leaderboard ranks teams by cumulative score across all holes

        Starting hole:
        • If your group starts on a hole other than 1 (e.g. a shotgun start), set Starting Hole when entering your team name
        • Scoring and the leaderboard will track from your starting hole forward

        Scramble is a tournament-only format — it requires creating or joining a tournament via Live & Tournaments before starting a round.
        """)

        header("SIDE GAMES (AUTOMATIC)")
        body("""
        • Nassau and Skins run automatically alongside your main game
        • No extra score entry is required
        • All side games use the same scores and handicaps

        Think of side games as additional bets running in parallel with your round

        • Results update instantly as scores are entered
        • Access Nassau and Skins anytime from the game screen
        """)

        header("NASSAU")
        body("""
        • Nassau runs automatically in parallel with your round
        • WolfMore creates matches based on the active players
        • Front 9, Back 9, and Overall 18 are tracked automatically
        • Results update hole-by-hole as scores are entered

        • Nassau can be played alongside Wolf, Six-Point, or Hammer — no separate scoring needed
        • Nassau results and presses update automatically as holes are committed

        • Nassau settings allow you to control stake, matches, and press behavior
        """)

        header("AUTO PRESS")
        body("""
        • Auto Press applies to Nassau
        • When enabled, a new press is created when a side reaches the set number of holes down
        • Presses run in parallel with the main Nassau bet
        • All press results update automatically as scores are entered
        """)

        header("SKINS")
        body("""
        • Skins runs automatically alongside your round
        • Each hole is worth one skin

        • Lowest net score wins the skin
        • If players tie, the skin carries to the next hole (if enabled)
        • Carryovers continue until a single winner

        • Skins always uses net scoring (handicap adjusted)
        • Only players included in Skins are considered
        • Handicaps are calculated relative to players in the skins game

        • You can adjust:
          • Skin value (bet amount)
          • Carryovers on or off
          • Which players are included

        • All Skins results update automatically as scores are entered
        """)

        header("HAMMER")
        body("""
        Hammer raises the hole bet. Tap + to hammer, − to undo the last hammer on this hole only.
        Two styles available (set in Game Settings):
        • Doubling: each hammer doubles — 1× → 2× → 4× → 8×
        • Additive: each hammer adds the base stake — 1× → 2× → 3× → 4×
        """)

        header("PRESS")
        body("""
        Press doubles the bet for all remaining holes in the half. Tap + to add a press, − to undo the last press on this hole only. Multiple presses stack: 1× → 2× → 4× → 8×. Press carries forward through remaining holes automatically.
        """)

        header("LONE WOLF")
        body("""
        • Player goes solo (Lone Wolf)
        • Lone Wolf doubles the hole wager
        • Special scoring applies for Lone Wolf situations
        """)

        header("UMBIE")
        body("""
        • Sweep rule for Six-Point Scotch
        • Winning all 6 points doubles the hole
        • Can be toggled on or off
        """)

        header("REMOTE NASSAU")
        body("""
        Challenge a friend to Nassau even when you're at different courses.
        Remote Nassau runs separately from your regular round, so both can be played at once.
        Results include both players' course names, compare mode, and hole-by-hole breakdown.

        How it works:
        - Tap Remote Nassau from the scoring screen
        - Tap "Send Invite" — this generates an invite code and opens Messages
        - Send the code to your opponent via text
        - Your opponent opens WolfMore, taps Remote Nassau → Import Invite, and pastes the code
        - Each player plays their own round normally
        - When finished, tap Remote Nassau → View Matches to see results
        - Tap "Send Results" to text the outcome back to your opponent

        Three ways to compare holes across different courses:
        - Hole by Hole — Hole 1 vs Hole 1, Hole 2 vs Hole 2
        - Front/Back 9 by HC — matches holes by handicap rating within each 9
        - 18 Holes by HC — matches all 18 holes by handicap rating across the full round

        - Results show Front 9, Back 9, Overall, and total dollar amount owed
        - Matches are saved until you delete them
        """)

        header("WOLF LIVE")
        body("""
        Wolf Live lets spectators watch a Wolf game in real time from their own phone.
        • Scorer taps the Live Wolf button on the scoring page to start a session and get a 6-character code
        • Spectators tap Live & Tournaments → Watch Live and enter the code
        • Scores, wolf assignments, press indicators, money, and roll decisions update in real time
        • Tap the refresh button to manually sync the latest scores
        • Watch up to 10 live matches simultaneously in the spectator view
        • Orange scores = wolf player, green = won money, red = lost money
        • Boxed hole numbers = press is active on that hole
        """)

        header("LIVE & TOURNAMENTS")
        body("""
        Run a live tournament across multiple groups with a real-time leaderboard. Both Wolf and Skins are fully tracked — all groups submit scores to a shared live leaderboard in real time.

        Quick start:
        • Organizer creates a tournament via Live & Tournaments → Create Tournament
        • Share the 6-character code with all groups
        • Each group joins via Live & Tournaments → Join Tournament and enters the code
        • Scores appear on the leaderboard automatically every time Update Scores is pressed

        Leaderboard tabs:
        • Money — Wolf money standings for the current day
        • Score — cumulative net score
        • Groups — each group's hole-by-hole breakdown
        • Tournament — multi-day aggregate including carry-over amounts
        • Net Skins / Gross Skins — skins won across all groups (tap a player to see which holes)

        Full setup:
        • Set tournament name and format (Wolf or Skins) when creating
        • The organizer can edit scoring mode and pot settings any time via Live & Tournaments → Manage Tournament → Edit Settings

        Multi-day tournaments:
        • The organizer advances to the next day via Live & Tournaments → Manage Tournament
        • Each day's standings are preserved and accessible via the day picker on the leaderboard
        • The organizer can enter carry-over dollar amounts for each player on the Tournament tab

        Skins in tournament mode:
        • The organizer chooses a skins scoring mode in Edit Tournament Settings:
          • Net — skins awarded on handicap-adjusted score (default)
          • Gross — skins awarded on raw score, no handicap
          • Both — pot is split between net and gross skins each day

        • When "Both" is selected the organizer can configure how the pot is divided:
          • 50/50 Split — half the pot to net, half to gross
          • Custom % — e.g. 75% gross / 25% net
          • Combined Pool — every skin (net or gross) has equal value; the full pot is divided by the total number of skins won across both types

        • The leaderboard has two skins tabs: Net Skins and Gross Skins
        • Each day tab shows only that day's skins with its own independent pot
        • The Tournament tab shows the cumulative total across all days

        • Tournament Skins always plays without carryovers regardless of your in-game Skins settings — each hole stands alone for fair cross-group comparison
        • Skins leaderboard ranks by skins won, not dollars, so group size does not affect standings
        • Tap any player row on the skins leaderboard to see exactly which holes they won

        • Player names must be entered consistently across all groups for the leaderboard to aggregate correctly
        """)

        header("STABLEFORD")
        body("""
        Points-based scoring format used in WolfMore Tournaments.

        • Start a Stableford tournament via Live & Tournaments → Create Tournament → Stableford
        • All groups join with the same 6-character code and submit scores in real time

        Scoring baselines (set by the organizer):
        • Par baseline: Eagle = 3 pts, Birdie = 2 pts, Par = 1 pt, Bogey = 0 pts
        • Bogey baseline: Birdie = 3 pts, Par = 2 pts, Bogey = 1 pt, Double Bogey = 0 pts

        Team scoring:
        • Organizer selects how many scores count per hole: Best 2, Best 3, or All 4
        • Handicaps are applied automatically based on each player's stroke index
        • The real-time leaderboard shows hole-by-hole points, front/back 9 totals, and overall standings

        Tee selection:
        • Each player can play from a different set of tees (see TEE SELECTION)
        • Points are calculated against that player's tee pars — a player on Women's Red is scored against Red pars, not the default tee
        • Set each player's tee on the pre-round player setup screen before starting

        The scorecard highlights each gross score with a color — gold for eagle, green for birdie, pink for bogey, and red for double bogey or worse.
        """)

        header("CALCUTTA")
        body("""
        Auction-based tournament format where teams are bid on before play begins.

        • Access Calcutta via Tee Games on the home screen
        • Create an event, enter team rosters, and record the bid amount won at auction for each team
        • The total pot is the sum of all bids

        Payout setup:
        • Add payout rows (e.g. 1st place = 60%, 2nd = 25%, 3rd = 15%) — WolfMore calculates the dollar amounts automatically
        • Ties split the combined payout evenly

        Leaderboard:
        • Supports two-day scoring — enter points for Day 1 and Day 2 separately
        • Teams are ranked by combined points across both days
        • BOW (Best of Week) winner can be recorded on the event

        • Each team can list a captain and up to three additional players
        • Use "Captain Only" mode to score on one player per team, or track the full roster
        • Tap Share to send a summary of bids, payouts, and standings
        """)

        header("TRACKING")
        body("""
        Your personal stat tracking.

        • View stats by player, course, and hole
        • Full history — all rounds saved with no limits
        • Access tracking from the player activation screen
        • Home Course tracking helps compare performance for you and your friends over time
        • Friend comparisons and home course summaries available from the home screen
        """)
        return text
    }
}
