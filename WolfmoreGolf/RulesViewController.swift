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


WOLFMORE · GAME RULES
Six-Point Scotch • Wolf • Wolf Low Ball • Hammer

GETTING STARTED

Set the Course
Go to the Course Edit page.
Enter hole pars and hole handicaps.
Save the course. These settings persist until you change them.
Pick a Home Course ⭐ (for tracking & stats)
On Course Edit / Course Library, choose a saved course and set it as Home.
Home Course is used for long-term tracking so stats stay grouped correctly by course.

Set Up Players
Go to the Player Setup page.
Enter player names and handicaps.
Toggle which players are Active for today’s round.
Track Players & Friends
Use the Players / Friends screens to:
Keep a roster of regular playing partners.
Mark friends you want to track over time.
Each finished round is stored so you can review results by player and friend later.

Start a New Game
Confirm course, active players, and handicaps are correct.
Press Reset Game (clears scores and wagers but keeps course and roster).
Set stakes and options (Umbie, Press, Hammer, etc.).
Hit Randomize if you want to shuffle tee order.

Press Go to Game to begin scoring.
The game persists until you press Reset Game.

GAME MODES (CAN SWITCH MID-ROUND)
WolfMore supports multiple scoring modes. You can switch modes any time, even mid-round. The hole will score using whichever mode is selected at the time you press Update Scores.
1) Six-Point Scotch (default)
This is the full 6-point format (Team Total + Low Ball + Prox + Birdie + Umbie sweep).
2) Wolf 2-Point (Low Ball + Team Total)
3) Wolf 1-Point (Low Ball)


SCORING OVERVIEW (SIX-POINT SCOTCH)
2 points — Team Total
Aggregate best two NET scores.
Lone Wolf uses a partner score = (player + bogey) ÷ 2.
2 points — Team Low Ball
Best NET score on the hole.
1 point — Prox
Closest to the pin in regulation.
1 point — Birdie
If your team makes a birdie on the hole.
Sweep Rule (Umbrella / “Umbie”)
If a team wins all 6 points, the points automatically double.
This can be deactivated in game settings by pushing the Umbie button.
Alone Rule (Lone Wolf)
If a player declares Lone Wolf, their Team Total is calculated using a partner score of:
(player’s score + bogey score) ÷ 2

HAMMER (OPTIONAL)
Hammer is a multiplier to the hole stake.
Each Hammer doubles the hole stake (1× → 2× → 4× → 8×…).
Hammer changes the hole dollars immediately.
Reject Hammer
Use Reject Hammer to back out / undo the most recent hammer (based on your rules).
Reject affects the hole stake, and the payout reflects that when scores are updated.
Player money will only update when you press Update Scores.

GAME PLAY
Score Entry
For each hole:
Enter scores
Mark Wolf selections (Wolf modes)
Mark Prox (Six-Point only)
Press Update Scores to lock the hole and apply payouts.
Stakes (Game $)
Stakes are tracked per hole.
Roll / Re-Roll doubles the current hole’s stake according to your rules.
Alone Double doubles the current hole’s stake when someone goes Lone Wolf.
Press starts at the current hole and applies a persistent double up to nine holes (per your settings).
Hammer multiplies the hole stake (can be combined with Six-Point or Wolf modes).
Strokes / Handicaps (Pops)
Pops are automatically calculated from player handicaps and course hole handicaps.
Pops are displayed on each hole.
RESET GAME
Reset Game clears scores and wagers but preserves course and roster.

TRACKING & STATS (THE “WOLF MORE” PART)

Hole Tracking
Every hole stores score, stake, and results.

Use Stats to see which holes you play best or worst on each course.

Player & Friend Tracking
Completed rounds are stored in history.

Game Stats lets you sort by Player / Score / Money / Prox and compare vs friends over time.

Personal History
Use Load To History to save the round into history.
Use My Stats to review your last 12-month history and trends.

"""
}

