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
        textView.adjustsFontForContentSizeCategory = true
        textView.textAlignment = .left

        // Nice reading insets
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

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
            textView.attributedText = baseAttributedText
            return
        }

        // Highlight matches on a mutable copy
        let highlighted = NSMutableAttributedString(attributedString: baseAttributedText)

        let full = highlighted.string as NSString
        let lowerFull = full.lowercased
        let lowerQuery = query.lowercased()

        var firstMatch: NSRange?
        var searchRange = NSRange(location: 0, length: full.length)

        while true {
            let found = (lowerFull as NSString).range(of: lowerQuery, options: [], range: searchRange)
            if found.location == NSNotFound { break }
            if firstMatch == nil { firstMatch = found }

            highlighted.addAttribute(.backgroundColor,
                                    value: UIColor.systemYellow.withAlphaComponent(0.35),
                                    range: found)

            let nextLoc = found.location + max(found.length, 1)
            if nextLoc >= full.length { break }
            searchRange = NSRange(location: nextLoc, length: full.length - nextLoc)
        }

        textView.attributedText = highlighted

        if let r = firstMatch {
            // Ensure layout exists before scrolling (reduces occasional “miss”)
            textView.layoutManager.ensureLayout(for: textView.textContainer)
            textView.scrollRangeToVisible(r)
        }
    }
}

// MARK: - Rules content builder
private extension RulesViewController {

    func makeRulesText() -> NSAttributedString {
        let text = NSMutableAttributedString()

        // Dynamic Type friendly header font
        let headerBase = UIFont.preferredFont(forTextStyle: .title2)
        let headerFont = UIFontMetrics(forTextStyle: .title2)
            .scaledFont(for: UIFont.boldSystemFont(ofSize: headerBase.pointSize))

        let bodyFont = UIFont.preferredFont(forTextStyle: .body)

        func header(_ str: String) {
            text.append(NSAttributedString(
                string: "\(str)\n",
                attributes: [
                    .font: headerFont,
                    .foregroundColor: UIColor.label
                ]
            ))
            text.append(NSAttributedString(
                string: "────────────────────\n",
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .footnote),
                    .foregroundColor: UIColor.tertiaryLabel
                ]
            ))
        }

        func body(_ str: String) {
            text.append(NSAttributedString(
                string: "\(str)\n\n",
                attributes: [
                    .font: bodyFont,
                    .foregroundColor: UIColor.secondaryLabel
                ]
            ))
        }

        // =============== CONTENT ===============

        header("WOLFMORE — HOW TO PLAY")
        body("""
Scoring and bet tracking made easy!

Hover or long press over most buttons for a description of that button.

Play up to 5 players (yes 5 players — 3 vs 2 Wolf is the most fun!).

Set your course, add players through “New Game”, and start scoring.

Supports Wolf, Six-Point Scotch, and Hammer play.

WolfMore is perfect for home-course competition with course stat tracking, away-course games, and indoor simulator rounds.
""")

        header("HIGHLIGHTS")
        body("""
• Contacts: import friends from your iPhone contacts (or add players manually).
• Texting Hub: send a round summary or quick messages to today’s group, Pro Shop, Drink Cart, or Coordinator.
• Preloaded Courses: pick built-in courses (pars + handicaps included) and start playing fast.
• WolfMore Pro (optional): unlock premium stats + custom text groups.
""")

        header("GETTING STARTED")
        body("""
• Choose a course:
   – Select a Preloaded Course (fastest)
   – Or create a new course by entering pars + handicaps
• Select a Home Course if you want personal stat tracking (saved on your phone)
• Press “New Game” and select up to 5 players
• Add players by importing from Contacts or entering names manually
""")

        header("CONTACTS")
        body("""
• Import players from your iPhone contacts
• You can also add players manually if you don’t want to import
• Tracking (optional): mark friends as “tracked” to include them in your stats and comparisons
""")

        header("TEXTING HUB")
        body("""
Texting is built into WolfMore so your group stays synced.

Available to all users:
• Send a round summary to today’s group
• Quick text buttons for Pro Shop, Drink Cart, and Coordinator
• Jump right back to scoring after sending

WolfMore Pro unlocks:
• Custom text groups (save groups and message them anytime)
""")

        header("WAGERS")
        body("""
• Default wager is $2.00
• Use + / – to adjust for the current hole or the entire game
• Tap $ to apply the wager to the entire game
""")

        header("HAMMER")
        body("""
• Doubles the hole wager
• Each tap doubles again (2× → 4× → 8×)
• Reject removes the last hammer
""")

        header("GAME MODES — all modes accessed on the scoring page")
        body("""
• Six-Point Scotch (default)
• Wolf (2 Point)
• Wolf (1 Point)
• You can change game modes mid-round if you want to mix it up
""")

        header("LONE WOLF")
        body("""
• Player goes solo (Lone Wolf)
• Lone Wolf doubles the hole wager
•  Player goes solo (no partner).
    Doubles the stake for this hole.
    Only tap if you want Lone Wolf wager to double. Otherwise. Alone calculation will be the same but without the double.
* Note: Alone Team Total calculation uses a ghost partner score: (player score + bogey) ÷ 2.
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

        header("WOLFMORE PRO — PREMIUM FEATURES")
        body("""
Join WolfMore Pro to unlock premium features:

• Full history (no limits)
• Friend tracking and comparisons
• Home Course summaries
• By-hole summaries and trends over time
• Custom text groups (save groups and message them anytime)

Pro is an optional subscription. You can cancel anytime in your Apple ID subscriptions.
If you already joined Pro on this device, tap “Restore Purchases” on the Pro screen to re-enable access.
""")

 

        return text
    }
}
