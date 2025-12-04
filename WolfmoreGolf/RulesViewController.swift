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


WOLF MORE · SIX-POINT SCOTCH GAME

GETTING STARTED

Set the Course
Go to the Course Edit page.
Enter hole pars and hole handicaps.
Save the course. These settings persist until you change them.

Set Up Players
Go to the Player Setup page.
Enter player names and handicaps.
Toggle which players are Active for today’s game (up to 7 players).
Track Players & Friends
Use the Players / Friends screens to:
Keep a roster of regular playing partners.
Mark friends you want to track over time.
Each finished round is stored so you can review results by player and friend later.

Start a New Game
Confirm course, active players, and handicaps are correct.
Press “Reset Game” (clears scores and wagers but keeps course and roster).
Set stakes and options (Umbie, Press, etc.).
Hit “Randomize” if you want to shuffle the tee order.
Press “Go to Game” to begin scoring.
The game persists until you press “Reset Game.”

SCORING OVERVIEW
2 points — Team Total
Aggregate best two NET scores.
Lone Wolf uses a partner score = (player+bogey)÷2
2 points — Team Low Ball
Best NET score on the hole.
1 point — Prox
Closest to the pin in regulation.
1 point — Birdie
Sweep rule (Umbrella)
If a team wins all 6 points on a hole, points automatically double.
This can be deactivated in the game settings.
Alone rule
If a player declares “Lone Wolf,” their team total is calculated using a partner score of:
(player’s score + bogey score) ÷ 2.

GAME
Track scores and bets using a six-point scotch format, including player handicaps.
Per-hole scoring, stakes, and presses are handled automatically once you enter scores.

COURSE
Load course stats on the Course Edit page (pars and hole handicaps).
Course data is saved and reused until you change it.

PLAYERS, FRIENDS & HANDICAPS
Player names and active players are managed on the Player Setup page.
Enter player handicaps on the Player Setup page.
Maintain a Friends / Roster list so you can:
See who played in each round.
Track long-term performance versus specific friends.

STROKES / HANDICAPS
Pops are automatically calculated from player handicaps and course hole handicaps.
Pops are displayed on each hole.

SCORE ENTRY
For each hole, enter scores and mark Prox and Wolf selections.
Totals and standings are available anytime via the Stats button.
STAKES (GAME $)
Stakes are tracked per hole.
Roll / Re-Roll doubles the current hole’s stake according to your group’s rules.
ALONE DOUBLE (BUTTON)
Use when a player goes Lone Wolf to double the current hole’s stake.
PRESS
Starts at the current hole.
Applies a persistent double for up to nine holes (per your settings).
UMBRELLA (“UMBIE”)
If a team gets all 6 points, the point value doubles.
You can deactivate the Umbie double for the game by pushing the Umbie button.

RESET GAME
Reset Game clears scores and wagers but preserves course and roster.


TRACKING & STATS

Hole Tracking
Every hole stores score, Prox, and stake results.
Use Stats to see which holes you play best or worst on each course.

Player & Friend Tracking
Completed rounds are stored in history.
The Game Stats screen shows sortable Player / Score / Money / Prox results.
You can review performance by player and by friend over time.

Personal History
Use “End Game” to save the round into history.
Use “My Stats” to review your last 12-month personal history and trends.

"""
}

