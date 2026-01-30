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
        
        Hover or long press over most buttos for decription of that button.

        WolfMore Pro: unlock premium stat tracking (full history, friend comparisons, home course summaries).

        Play up to 5 players (yes 5 players, 3 against 2 wolf is the most fun!)
        Set your course, add players through new game button, and start scoring.
        Supports Wolf, Six-Point Scotch, and Hammer play.
        """)

        header("GETTING STARTED")
        body("""
        • Set your course and handicaps
        • Select a Home Course if you want personal stat tracking of you and your friends. This is your personal data on your phone only.
        • Press "New Game" and select up to 5 players. If you're new to WolfMore, first add players and activate players through "New Game" button.
        """)

        header("WAGERS")
        body("""
        • Default wager is $2.00
        • Use + / – to adjust for the present hole or the game
        • Tap $ to apply wager to entire game
        """)

        header("HAMMER")
        body("""
        • Doubles the hole wager
        • Each tap doubles again (2× → 4× → 8×)
        • Reject removes last hammer
        """)

        header("GAME MODES - All modes accessed in game scorng page")
        body("""
        • Six-Point Scotch (default)
        • Wolf (2 Point)
        • Wolf (1 Point)
        • Modes can change mid-round.
        """)

        header("LONE WOLF")
        body("""
        • Player goes solo
        • Lone Wolf Total Score = (Lone Wolf Score + ((Lone Wolf Score + Bogey) ÷ 2)
        • Doubles hole wager
        """)

        header("UMBIE")
        body("""
        • Sweep rule for Six-Point
        • Winning all 6 points doubles the hole
        • Can be toggled on/off
        """)

        header("SCORING")
        body("""
        Enter scores → Select options → Update Scores
        W = Wolf partners
        P = Prox
        """)

        header("TRACKING")
        body("""
        Your personal stat tracking.
        View stats by player, course, and hole.
        Access and select tracking from the player activation screen.
        """)

        // ✅ Added Pro section (matches your screenshot content)
        header("WOLFMORE PRO — PREMIUM STATS")
        body("""
        Join WolfMore Pro to unlock premium stat tracking:

        • Full history (no limits)
        • Friend tracking and comparisons
        • Home Course summaries
        • By-hole summaries and trends over time

        Pro is an optional subscription. You can cancel anytime in your Apple ID subscriptions.
        If you already joined Pro on this device, tap "Restore Purchases" on the Pro screen to re-enable access.
        """)

        return text
    }
}
