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

        Hover or long press over most buttons for a description of that button.

        WolfMore Pro unlocks premium stat tracking including full history, friend comparisons, home course summaries, and by-hole summaries.

        Play up to 5 players. Yes, 5 players — and 3 vs 2 Wolf can be the most fun.

        Set your course, add players through the New Game button, and start scoring.

        Supports Wolf, Six-Point Scotch, Hammer, Nassau, and Skins — all running together.

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

        header("COURSES")
        body("""
        • WolfMore includes built-in courses plus any custom courses you add
        • Built-in courses help you get started quickly and may include phone, website, address, and other course details
        • On the course picker, swipe left to mark a course as your Home Course
        • Swipe right on a course for more information including phone, website, address, and available details
        • Your Home Course is used for personal stats, comparisons, and tracking over time
        """)

        header("SCORING")
        body("""
        Enter scores → Select options → Update Scores

        • All scoring happens from one screen
        • Results update instantly across all games

        W = Wolf partners
        P = Prox (closest to pin)
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

        • Nassau and Skins run automatically as side games
        • You can change game modes mid-round if you want to mix it up
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
        • Hammer doubles the hole wager
        • Each additional tap doubles again (2× → 4× → 8×)
        • Reject removes the last hammer
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

        header("TRACKING")
        body("""
        Your personal stat tracking.

        • View stats by player, course, and hole
        • Access tracking from the player activation screen
        • Home Course tracking helps compare performance for you and your friends over time
        """)

        header("WOLFMORE PRO — PREMIUM STATS")
        body("""
        Join WolfMore Pro to unlock premium stat tracking:

        • Full history (no limits)
        • Friend tracking and comparisons
        • Home Course summaries
        • By-hole summaries and trends over time

        Pro is an optional subscription. You can cancel anytime in your Apple ID subscriptions.

        If you already joined Pro on this device, tap "Restore Purchases" to re-enable access.
        """)
        return text
    }
}
