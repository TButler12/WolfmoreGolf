import UIKit

// Shared by HowToPlayViewController and HowToPlayPageViewController (both fileprivate to this file).
fileprivate struct HowToPlayPage {
    let systemImage: String
    let symbolColor: UIColor
    let title:       String
    let body:        String
    let badges:      [String]
}

// MARK: - HowToPlayViewController
//
// Five-page swipeable walkthrough reachable at any time from the Home "More" menu.
// Each page pairs a large SF Symbol diagram with a short caption — no screenshots,
// so nothing goes stale when screens change.

final class HowToPlayViewController: UIViewController {

    // MARK: - Pages

    private let pages: [HowToPlayPage] = [
        HowToPlayPage(
            systemImage: "mappin.and.ellipse",
            symbolColor: UIColor(red: 0.20, green: 0.44, blue: 0.20, alpha: 1),
            title: "Pick Your Course",
            body: "The course name on your Home screen shows what you're playing — tap it to switch courses, or the ⓘ button for tee and architect details. Every round you play gets tracked against this course.\n\nDon't see your course? Tap the ✏️ pencil on Home to edit course details, or choose \"Add New Course\" from the course picker to enter pars and hole handicaps manually.\n\nPlaying mixed tees? On the Player Setup screen, tap the tee icon next to any player to assign them a different tee set — useful for women's tees or when players are playing from different yardages.",
            badges: ["Change Course", "Add Course", "Mixed Tees", "Women's Tees"]
        ),
        HowToPlayPage(
            systemImage: "person.3.fill",
            symbolColor: UIColor(red: 0.106, green: 0.227, blue: 0.165, alpha: 1),
            title: "Start a Round",
            body: "Quick Start lets you type player names right on the next screen; Play from Loaded Contacts pulls in players you've saved before. Either way, enter each player's handicap and tee — WolfMore uses the gap between players' handicaps to hand out strokes on the hardest holes first.\n\nTap Edit Stake & Format to open Game Settings, where you can set the base dollar stake, switch between Wolf scoring formats, toggle Umbrella, and choose Press and Hammer styles (Doubling ×2/×4/×8 or Additive +$base each tap). Changes save instantly.",
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
            systemImage: "pencil.and.list.clipboard",
            symbolColor: UIColor(red: 0.20, green: 0.44, blue: 0.70, alpha: 1),
            title: "Score Each Hole",
            body: "Enter strokes for every player in the Update Scores grid. Toggle Roll, Press, or Alone to adjust the stake. Tap Prox to award closest-to-pin.\n\nTap the ⓘ button (top-right of the scoring screen) mid-round for quick access to Scoring Tips, Change Course, Change Handicap, Change Base $ Bet, and Pass Game to Another Phone — so you can fix anything without leaving the hole.",
            badges: ["Scores", "Roll / Press / Alone", "Prox", "ⓘ Menu"]
        ),
        HowToPlayPage(
            systemImage: "antenna.radiowaves.left.and.right",
            symbolColor: UIColor(red: 0.10, green: 0.45, blue: 0.30, alpha: 1),
            title: "Share Your Round Live",
            body: "Tap Go Live on the scoring screen to generate a spectator code. Share it with friends at the 19th hole — they open WolfMore, tap Spectate Live Wolf, enter the code, and follow your round hole-by-hole in real time as scores come in.\n\nThe leaderboard shows net totals and match status live. A filled dot ● marks the low-ball leader each hole.",
            badges: ["Go Live", "Spectate", "Share Code", "19th Hole"]
        ),
        HowToPlayPage(
            systemImage: "person.3.sequence.fill",
            symbolColor: UIColor(red: 0.35, green: 0.18, blue: 0.55, alpha: 1),
            title: "Host a Tournament",
            body: "From Home, tap Live & Tournaments → Create Tournament to set up a new event. Choose a format: Wolf (team scoring), Skins (hole-by-hole pot), Stableford (points vs par), or Scramble (best-ball team drive) — then WolfMore generates a join code.\n\nShare that code with your group; they tap Join Tournament and enter it to hop in. Running a big field? Generate a Co-Organizer Code so someone else can help manage scoring and settings alongside you.",
            badges: ["Wolf", "Skins", "Stableford", "Scramble", "Co-Organizer"]
        ),
        HowToPlayPage(
            systemImage: "dot.radiowaves.left.and.right",
            symbolColor: UIColor(red: 0.12, green: 0.47, blue: 0.62, alpha: 1),
            title: "Remote Nassau Match",
            body: "Playing a Nassau against someone who isn't with you today? From Live & Tournaments, tap Join Remote Nassau Match and import their invite to track the same bet remotely — both of your scores sync automatically as you each play your own round.",
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

        // Page dots
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

        // Body
        let bodyLabel = UILabel()
        bodyLabel.text = page.body
        bodyLabel.font = .systemFont(ofSize: 16, weight: .regular)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.textAlignment = .center
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

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 90),
            iconView.widthAnchor.constraint(equalToConstant: 120),

            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28)
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
