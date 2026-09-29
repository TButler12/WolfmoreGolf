import UIKit

final class StatsContainerViewController: UIViewController {

    // MARK: - UI
    private let statsSegment = UISegmentedControl(items: ["Wolf", "Nassau", "Skins"])
    private let containerView = UIView()

    // MARK: - Child VCs
    private let gameVC = GameStatsViewController()
    private let nassauVC = NassauViewController()
    private let skinsVC = SkinsViewController()

    private var currentVC: UIViewController?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Today's Results"

        var doneCfg = UIButton.Configuration.filled()
        doneCfg.title = "Done"
        doneCfg.baseBackgroundColor = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)
        doneCfg.baseForegroundColor = .white
        doneCfg.cornerStyle = .capsule
        doneCfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        doneCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return a
        }
        let doneBtn = UIButton(configuration: doneCfg)
        doneBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneBtn)

        setupUI()
        setupChildren()
        switchTo(index: 0)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    // MARK: - Setup
    private func setupUI() {
        statsSegment.selectedSegmentIndex = 0
        statsSegment.selectedSegmentTintColor = UIColor(red: 0.10, green: 0.35, blue: 0.20, alpha: 1.0)
        statsSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        statsSegment.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        statsSegment.translatesAutoresizingMaskIntoConstraints = false

        containerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(statsSegment)
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            statsSegment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statsSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            containerView.topAnchor.constraint(equalTo: statsSegment.bottomAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupChildren() {
        nassauVC.gameData = GameManager.shared.currentGame
        skinsVC.gameData = GameManager.shared.currentGame
    }

    // MARK: - Stats tab switching
    @objc private func segChanged() {
        switchTo(index: statsSegment.selectedSegmentIndex)
    }

    private func switchTo(index: Int) {
        let newVC: UIViewController
        switch index {
        case 0:
            newVC = gameVC
        case 1:
            newVC = isSideGameOverLimit ? makeSideGamePlaceholder() : nassauVC
        case 2:
            newVC = isSideGameOverLimit ? makeSideGamePlaceholder() : skinsVC
        default:
            return
        }
        transition(to: newVC)
    }

    // True when the active player count exceeds what Skins/Nassau support.
    private var isSideGameOverLimit: Bool {
        guard let g = GameManager.shared.currentGame else { return false }
        let active = (0..<g.activePlayerLimit).filter {
            (g.playerActivated[safe: $0] ?? false) &&
            !(g.playerNames[safe: $0] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        return active > MAX_PLAYERS
    }

    private func makeSideGamePlaceholder() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "Skins and Nassau support up to 5 players"
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor, constant: -40),
            label.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),
        ])
        return vc
    }

    private func transition(to newVC: UIViewController) {
        if let currentVC {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        addChild(newVC)
        newVC.view.frame = containerView.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(newVC.view)
        newVC.didMove(toParent: self)
        currentVC = newVC
    }
}
