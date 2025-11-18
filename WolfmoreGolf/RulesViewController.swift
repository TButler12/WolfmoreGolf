//
//  RulesViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/8/25.
//

//
//  RulesViewController.swift
//  Wolfmore-5Man
//
//  Created by Tom BUTLER on 10/19/25.
//

import UIKit

final class RulesViewController: UIViewController {
    private let textView = UITextView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Rules"
        view.backgroundColor = .systemBackground

        // Read-only, Dynamic Type–friendly text view
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        textView.backgroundColor = .clear
        textView.adjustsFontForContentSizeCategory = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.textAlignment = .left
        textView.text = RulesViewController.rulesText
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Show a Close button when presented modally (with or without a nav controller)
        if presentingViewController != nil || navigationController?.presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
            )
        }
    }
}

private extension RulesViewController {
    static let rulesText = """
WOLFMORE • SIX-POINT SCOTCH GAME

SCORING OVERVIEW
• 2 points — Team Total (aggregate best two NET; Lone Wolf uses partner = (player + bogey) ÷ 2).
• 2 points — Team Low Ball (best NET).
• 1 point — Prox (closest to the pin in regulation).
• 1 point — Birdie.
• Sweep rule (Umbrella): if a team wins all 6 points on a hole, points automatically double. This can be deactivated in the game.
• Alone rule: if a player declares “Lone Wolf,” their team total is calculated using a partner score of (player’s score + bogey score) ÷ 2.

GAME
• Track scores and bets using a six-point scotch format, including player handicaps.

COURSE
• Load course stats on the Course Edit page (hole pars and hole handicaps). This data persists until you change it.

PLAYERS & HANDICAPS
• Player names and active players are set on the Player Setup page.
• Enter player handicaps on the Player Setup page.

STROKES / HANDICAPS
• Pops are automatically calculated from player handicaps and course hole handicaps.
• Pops are displayed on each hole.

SCORE ENTRY
• For each hole, enter scores and mark Prox and Wolf selections.
• Totals and standings are available anytime via the Stats button.

STAKES (GAME $)
• Stakes are tracked per hole.
• Roll / Re-Roll doubles the current hole’s stake per your group’s rules.

ALONE DOUBLE (BUTTON)
• Use when a player goes Lone Wolf to double the current hole’s stake.

PRESS
• Starts at the current hole.
• Applies a persistent double for up to nine holes (per your settings).

UMBRELLA (“UMBIE”)
• If a team gets all 6 points, the point value doubles.
• You can deactivate the Umbie double for the game by pushing the Umbie button.

RESET GAME
• Reset clears scores and wagers but preserves course and roster.

START NEW GAME
• Load and activate player names and associated handicaps. These persist until changed by the user.
• Push “Reset Game”.
• Activate up to 7 players.
• Hit “Randomize” to set the first-tee order.
• Push “Go to Game”.
• The game persists until “Reset Game” is pushed.

NOTES
• Use the Game Stats screen for sortable Player / Score / Money / Prox.
• Use the "End Game" to load game data into history storage
• Use the "My Stats" to review last 12-month persoanl history.

"""
}

