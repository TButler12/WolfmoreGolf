import UIKit

// Shared by HowToPlayViewController and HowToPlayPageViewController (both fileprivate to this file).
fileprivate struct HowToPlayPage {
    let systemImage: String
    let symbolColor: UIColor
    let title:       String
    let body:        String
    let badges:      [String]
    var attributedBody: NSAttributedString? = nil
}

// Build the "Which One Do I Need?" attributed body (three bold-label + detail rows, center-aligned).
fileprivate func makeWhichOneAttributedBody() -> NSAttributedString {
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.paragraphSpacing = 4

    let boldAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 17, weight: .bold),
        .foregroundColor: UIColor.label,
        .paragraphStyle: para
    ]
    let regularAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15, weight: .regular),
        .foregroundColor: UIColor.secondaryLabel,
        .paragraphStyle: para
    ]
    let gapAttrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10, weight: .regular),
        .paragraphStyle: para
    ]

    let rows: [(String, String)] = [
        ("Go Live",       "Let friends follow your group"),
        ("Event Board",   "See all groups at a casual outing"),
        ("Tournament",    "Run an official competition with one set of rules and standings")
    ]

    let result = NSMutableAttributedString()
    for (i, (label, detail)) in rows.enumerated() {
        if i > 0 { result.append(NSAttributedString(string: "\n\n", attributes: gapAttrs)) }
        result.append(NSAttributedString(string: label,         attributes: boldAttrs))
        result.append(NSAttributedString(string: "\n" + detail, attributes: regularAttrs))
    }
    return result
}

// MARK: - HowToPlayViewController
//
// Swipeable walkthrough reachable at any time from the Home "More" menu.
// Each page pairs a large SF Symbol diagram with a short caption — no screenshots,
// so nothing goes stale when screens change.

final class HowToPlayViewController: UIViewController {

    // MARK: - Pages

    private let pages: [HowToPlayPage] = [
        HowToPlayPage(
            systemImage: "mappin.and.ellipse",
            symbolColor: UIColor(red: 0.20, green: 0.44, blue: 0.20, alpha: 1),
            title: "Pick Your Course",
            body: "The course name on your Home screen shows what you're playing — tap it to switch courses, or the ⓘ button for tee and architect details. Every round you play gets tracked against this course.\n\nDon't see your course? Tap the ✏️ pencil on Home to edit course details, or choose \"Add New Course\" from the course picker to enter pars and hole handicaps manually.\n\nMixed tees in the same group? This is common when men and women play together, when one player is a senior, junior, or adaptive golfer playing shorter yardages, Each tee box has its own pars and stroke index ratings — WolfMore tracks every player against the correct par and handicap for their tee, so the scoring and strokes are always fair regardless of where each person tees it up.\n\nTo set it up: open Course Setup (✏️ pencil on Home), tap \"Tee Sets\" in the top-left, then \"+ Add Tee Set\". Enter the alternate pars and stroke indexes for that tee. Then on Player Setup, tap the tee button next to any player to assign them to it. Each tee set is saved to that course only.",
            badges: ["Change Course", "Add Course", "Mixed Tees", "Add Tee Set"]
        ),
        HowToPlayPage(
            systemImage: "person.3.fill",
            symbolColor: UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1),
            title: "Start a Round",
            body: "Quick Start lets you type player names right on the next screen; Play from Loaded Contacts pulls in players you've saved before. Either way, enter each player's handicap and tee — WolfMore uses the gap between players' handicaps to hand out strokes on the hardest holes first.\n\nTap Edit Stake & Format to open Game Settings, where you can set the base dollar stake, switch between Wolf scoring formats, toggle Umbrella, choose Press and Hammer styles (Doubling ×2/×4/×8 or Additive +$base each tap), and set Lone Wolf Team Score. Changes save instantly.\n\nLone Wolf Team Score sets how a player's team total is calculated when they go alone. Ghost Partner (default): score plus an imaginary partner halfway between that score and bogey — a 3 on a par 3 gives a team total of 6.5. Double Score: the lone score simply counts twice — a 3 gives 6.",
            badges: ["Quick Start", "Loaded Contacts", "Edit Stake & Format", "Game Settings"]
        ),
        HowToPlayPage(
            systemImage: "checklist",
            symbolColor: UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1),
            title: "Choose Your Format",
            body: "Under Wolf Scoring Options pick 6-Point Scotch, Wolf 2-Pt, LowBall, or Match Play.\n\nMatch Play adds sub-options: Individual, Fourball, 1 vs 1, and 9-Hole Match.\n\nWhichever format you pick, WolfMore automatically tracks Wolf, Skins, and Nassau side-games in the background — no extra setup needed.",
            badges: ["6-Point", "Wolf 2pt", "LowBall", "Match Play"]
        ),
        HowToPlayPage(
            systemImage: "person.badge.plus",
            symbolColor: UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1),
            title: "6 & 7-Player Wolf",
            body: "6-Point, Wolf 2pt, and LowBall support up to 7 active players — add a 6th or 7th name on the Player Setup screen and they slot straight in.\n\nWith 6 or 7 players, Skins, Nassau, and Go Live are off for the round. Those side games are designed for groups of 5 — Results will show a note explaining why. Match Play is also blocked at more than 5 players; the app will tell you if you try to switch.\n\nStandings holes: players rotate as wolf for as many full rotations as fit in the round (4 players: holes 1–16, 5 players: holes 1–15, 7 players: holes 1–14). On the remaining holes, whoever is down the most money at that point goes first — giving the person who's behind the best chance to earn it back.",
            badges: ["6-Point", "Wolf 2pt", "LowBall", "Up to 7 Players"]
        ),
        HowToPlayPage(
            systemImage: "pencil.and.list.clipboard",
            symbolColor: UIColor(red: 0.20, green: 0.44, blue: 0.70, alpha: 1),
            title: "Score Each Hole",
            body: "Enter strokes for every player in the Update Scores grid. Toggle Roll, Press, or Alone to adjust the stake. Tap Prox to award closest-to-pin.\n\nStroke dots next to each score show exactly how many handicap strokes that player earned on the hole, so it's clear at a glance why net differs from gross. A filled dot ● next to a name marks the low-ball leader on that hole.\n\nTap the ⓘ button (top-right of the scoring screen) mid-round for quick access to Scoring Tips, Change Course, Change Handicap, Change Base $ Bet, and Pass Game to Another Phone — so you can fix anything without leaving the hole.",
            badges: ["Scores", "Roll / Press / Alone", "Prox", "ⓘ Menu"]
        ),
        HowToPlayPage(
            systemImage: "info.circle.fill",
            symbolColor: UIColor(red: 0.18, green: 0.38, blue: 0.58, alpha: 1),
            title: "Mid-Round Adjustments",
            body: "Tap the ⓘ button in the top-right corner of the scoring screen any time during your round to open a menu of quick adjustments — no need to back out to the Home screen.\n\n• How to Play — opens this walkthrough.\n• Scoring Tips — reminders on entering scores, handicap strokes, and committing holes.\n• Change Course — switch to a different course if the group moved or the wrong one was set at the start. Pars and hole handicaps update immediately; scores already entered are kept.\n• Change Handicap — adjust any player's handicap mid-round. Stroke allocation updates from the current hole forward.\n• Change Base $ Bet — raise or lower the base dollar stake for the rest of the round.\n• Pass Game to Another Phone — hand off the live round to another device so a different player can keep score.",
            badges: ["ⓘ Button", "Change Course", "Change Handicap", "Change $ Bet", "Pass Game"]
        ),
        HowToPlayPage(
            systemImage: "chart.bar.fill",
            symbolColor: UIColor(red: 0.25, green: 0.45, blue: 0.70, alpha: 1),
            title: "Stats & Hole Tracking",
            body: "After entering scores, tap Hole Stats on the scoring screen to log Fairways in Regulation (FIR), Greens in Regulation (GIR), and total putts for that hole. WolfMore will prompt you automatically after each hole — or tap the Hole Stats button any time to fill it in.\n\nTo review your stats, tap Stats on the Home screen. Select a past round to see a full scorecard plus your FIR %, GIR %, and total putts broken out per player. Your lifetime averages accumulate across all saved rounds.",
            badges: ["Hole Stats", "FIR", "GIR", "Putts", "Past Games"]
        ),
        HowToPlayPage(
            systemImage: "antenna.radiowaves.left.and.right",
            symbolColor: UIColor(red: 0.10, green: 0.45, blue: 0.30, alpha: 1),
            title: "Share Your Round Live",
            body: "For friends who want to follow your group.\n\nTap Go Live on the scoring screen to get a spectator code. Anyone with WolfMore taps Watch, enters the code, and sees your group's scores hole-by-hole as you play.\n\nOne group, no setup. It ends when you tap Stop Live.",
            badges: ["Go Live", "Watch", "Share Code", "Stop Live"]
        ),
        HowToPlayPage(
            systemImage: "rectangle.3.group",
            symbolColor: UIColor(red: 0.10, green: 0.45, blue: 0.30, alpha: 1),
            title: "Event Board",
            body: "For a casual outing with several groups.\n\nStart an Event Board and share its code. Each group goes live and taps Join an Event Board. Then everyone, players and spectators alike, sees every group on one screen.\n\nEach group keeps its own game and settings. It's great for a men's day or a buddies' trip where you just want to see how the other groups are doing.",
            badges: ["Start an Event Board", "Join an Event Board", "Go Live"]
        ),
        HowToPlayPage(
            systemImage: "person.3.sequence.fill",
            symbolColor: UIColor(red: 0.35, green: 0.18, blue: 0.55, alpha: 1),
            title: "Host a Tournament",
            body: "For an organized event with one set of rules.\n\nFrom Home, tap Live & Tournaments → Create Tournament. Pick the course and format (Wolf, Skins, Stableford or Scramble). Players join with your code, and everyone plays under the same locked settings, so results are truly comparable.\n\nYou get an official Leaderboard across all groups, multi-day events, and the option to add a co-organizer to help run it.",
            badges: ["Wolf", "Skins", "Stableford", "Scramble", "Co-Organizer"]
        ),
        HowToPlayPage(
            systemImage: "questionmark.circle",
            symbolColor: UIColor(red: 0.35, green: 0.18, blue: 0.55, alpha: 1),
            title: "Which One Do I Need?",
            body: "",
            badges: ["Go Live", "Event Board", "Tournament"],
            attributedBody: makeWhichOneAttributedBody()
        ),
        HowToPlayPage(
            systemImage: "slider.horizontal.3",
            symbolColor: UIColor(red: 0.18, green: 0.42, blue: 0.52, alpha: 1),
            title: "Tournament Scoring Options",
            body: "Wolf and Skins tournaments can add Team Scoring, a team net competition across every group. Choose a fixed team size, or 4-3-2 by par. Results appear on the Leaderboard under Team Scoring.\n\nStableford tournaments can use Standard points or Modified Stableford with your own point values.",
            badges: ["Team Scoring", "Team Net", "Stableford", "Modified Points"]
        ),
        HowToPlayPage(
            systemImage: "dot.radiowaves.left.and.right",
            symbolColor: UIColor(red: 0.12, green: 0.47, blue: 0.62, alpha: 1),
            title: "Remote Nassau Match",
            body: "Remote Nassau is a 1v1 Nassau bet — front 9, back 9, and total — between two players playing separate rounds, even on different courses. To start a match, tap the Remote Nassau button on the scoring screen (or go to Live & Tournaments → Create Remote Nassau Match), then share the invite code with your opponent. Your opponent joins from Live & Tournaments → Join Remote Nassau Match and pastes the code. Scores sync automatically as you each play. When both rounds are done, tap View Matches to see who won each bet.",
            badges: ["Remote Nassau", "Join Match", "Sync Scores"]
        ),
        HowToPlayPage(
            systemImage: "trophy.fill",
            symbolColor: UIColor(red: 0.75, green: 0.55, blue: 0.00, alpha: 1),
            title: "Wrap Up",
            body: "After the last hole, tap Game Results for a full payout breakdown. Share the Scorecard image, run an AI Round Summary, or Add to History to track your stats over time.\n\nEvery completed round is saved automatically — revisit any past round's full summary anytime from Stats or More → Past Games.",
            badges: ["Results", "Scorecard", "AI Summary", "Past Games"]
        )
    ]

    // MARK: - Child page VCs

    private var pageVCs: [HowToPlayPageViewController] = []
    private var pageVC: UIPageViewController!

    // MARK: - UI

    private let pageControl = UIPageControl()
    private let nextButton  = UIButton(type: .system)
    private let backButton  = UIButton(type: .system)
    private let skipButton  = UIButton(type: .system)

    private var currentIndex = 0 {
        didSet { updateControls() }
    }

    // MARK: - Colors (same palette as HomeViewController)

    private let forestGreen = UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1)
    private let goldColor   = UIColor(red: 0.910, green: 0.851, blue: 0.541, alpha: 1)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        buildPageVCs()
        buildPageViewController()
        buildBottomBar()
        updateControls()
    }

    // MARK: - Build

    private func buildPageVCs() {
        pageVCs = pages.map { HowToPlayPageViewController(page: $0) }
    }

    private func buildPageViewController() {
        pageVC = UIPageViewController(transitionStyle: .scroll,
                                      navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate   = self

        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)

        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -110)
        ])

        pageVC.setViewControllers([pageVCs[0]], direction: .forward, animated: false)
    }

    private func buildBottomBar() {
        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)

        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: 100)
        ])

        // Page dots — driven by pages.count so adding/removing pages keeps every dot in sync
        pageControl.numberOfPages = pages.count
        pageControl.currentPage   = 0
        pageControl.currentPageIndicatorTintColor = forestGreen
        pageControl.pageIndicatorTintColor = forestGreen.withAlphaComponent(0.25)
        pageControl.addTarget(self, action: #selector(dotTapped(_:)), for: .valueChanged)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(pageControl)

        // Skip / Done — top-right of bar
        skipButton.setTitle("Skip", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        skipButton.tintColor = .secondaryLabel
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(skipButton)

        // Back
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        backButton.tintColor = forestGreen
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(backButton)

        // Next / Done
        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = forestGreen
        cfg.baseForegroundColor = goldColor
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var a = a; a.font = UIFont.systemFont(ofSize: 16, weight: .semibold); return a
        }
        cfg.title = "Next →"
        nextButton.configuration = cfg
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(nextButton)

        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
            pageControl.topAnchor.constraint(equalTo: bar.topAnchor, constant: 8),

            skipButton.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -20),
            skipButton.topAnchor.constraint(equalTo: bar.topAnchor, constant: 8),

            backButton.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 20),
            backButton.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -16),

            nextButton.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Navigation

    @objc private func nextTapped() {
        if currentIndex < pages.count - 1 {
            currentIndex += 1
            pageVC.setViewControllers([pageVCs[currentIndex]], direction: .forward, animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func backTapped() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        pageVC.setViewControllers([pageVCs[currentIndex]], direction: .reverse, animated: true)
    }

    @objc private func skipTapped() {
        dismiss(animated: true)
    }

    @objc private func dotTapped(_ sender: UIPageControl) {
        let target = sender.currentPage
        let direction: UIPageViewController.NavigationDirection = target > currentIndex ? .forward : .reverse
        currentIndex = target
        pageVC.setViewControllers([pageVCs[currentIndex]], direction: direction, animated: true)
    }

    private func updateControls() {
        let isLast = currentIndex == pages.count - 1
        var cfg = nextButton.configuration ?? UIButton.Configuration.filled()
        cfg.title = isLast ? "Done ✓" : "Next →"
        nextButton.configuration = cfg

        skipButton.setTitle(isLast ? "Done" : "Skip", for: .normal)
        backButton.isHidden = currentIndex == 0
        pageControl.currentPage = currentIndex
    }
}

// MARK: - UIPageViewControllerDataSource

extension HowToPlayViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pvc: UIPageViewController,
                            viewControllerBefore vc: UIViewController) -> UIViewController? {
        guard let typed = vc as? HowToPlayPageViewController,
              let idx = pageVCs.firstIndex(of: typed), idx > 0 else { return nil }
        return pageVCs[idx - 1]
    }

    func pageViewController(_ pvc: UIPageViewController,
                            viewControllerAfter vc: UIViewController) -> UIViewController? {
        guard let typed = vc as? HowToPlayPageViewController,
              let idx = pageVCs.firstIndex(of: typed), idx < pageVCs.count - 1 else { return nil }
        return pageVCs[idx + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension HowToPlayViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pvc: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let shown = pvc.viewControllers?.first as? HowToPlayPageViewController,
              let idx   = pageVCs.firstIndex(of: shown) else { return }
        currentIndex = idx
    }
}

// MARK: - HowToPlayPageViewController

fileprivate final class HowToPlayPageViewController: UIViewController {

    private let page: HowToPlayPage

    init(page: HowToPlayPage) {
        self.page = page
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()
    }

    private func buildLayout() {
        // Large SF Symbol icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 72, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: page.systemImage, withConfiguration: iconConfig))
        iconView.tintColor = page.symbolColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        let titleLabel = UILabel()
        titleLabel.text = page.title
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Body — uses NSAttributedString when set, otherwise plain string
        let bodyLabel = UILabel()
        if let attr = page.attributedBody {
            bodyLabel.attributedText = attr
        } else {
            bodyLabel.text = page.body
            bodyLabel.font = .systemFont(ofSize: 16, weight: .regular)
            bodyLabel.textColor = .secondaryLabel
            bodyLabel.textAlignment = .center
        }
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        // Badge pills
        let badgeStack = makeBadgeStack()
        badgeStack.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, bodyLabel, badgeStack])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.setCustomSpacing(28, after: iconView)
        stack.setCustomSpacing(12, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Wrap in a scroll view so large Dynamic Type sizes don't overflow
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 90),
            iconView.widthAnchor.constraint(equalToConstant: 120),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -28),
        ])
    }

    private func makeBadgeStack() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        row.distribution = .equalSpacing

        for label in page.badges {
            let pill = UILabel()
            pill.text = label
            pill.font = .systemFont(ofSize: 12, weight: .semibold)
            pill.textColor = page.symbolColor
            pill.backgroundColor = page.symbolColor.withAlphaComponent(0.10)
            pill.layer.cornerRadius = 10
            pill.layer.masksToBounds = true
            pill.textAlignment = .center
            pill.translatesAutoresizingMaskIntoConstraints = false

            let hPad: CGFloat = 10
            pill.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            pill.heightAnchor.constraint(equalToConstant: 26).isActive = true

            // Add horizontal padding via insets using a container view
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(pill)
            NSLayoutConstraint.activate([
                pill.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: hPad),
                pill.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -hPad),
                pill.topAnchor.constraint(equalTo: container.topAnchor),
                pill.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            container.layer.cornerRadius = 10
            container.backgroundColor = page.symbolColor.withAlphaComponent(0.10)
            pill.backgroundColor = .clear

            row.addArrangedSubview(container)
        }

        // Wrap in a horizontal scroll for tight screens
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        row.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.topAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            row.heightAnchor.constraint(equalTo: scroll.heightAnchor)
        ])
        scroll.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let wrapper = UIStackView(arrangedSubviews: [scroll])
        wrapper.axis = .vertical
        return wrapper
    }
}
