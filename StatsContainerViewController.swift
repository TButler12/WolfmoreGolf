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
        title = "Results and Game Settings"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(close)
        )

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

    @objc private func settingsTapped() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        switch statsSegment.selectedSegmentIndex {
        case 0:
            let vc = sb.instantiateViewController(withIdentifier: "GameSettingsViewController") as! GameSettingsViewController
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            nassauVC.presentSettingsFromContainer()
        case 2:
            let vc = SkinsSettingsViewController()
            vc.gameData = GameManager.shared.currentGame
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }

    private func switchTo(index: Int) {
        let newVC: UIViewController
        switch index {
        case 0: newVC = gameVC
        case 1: newVC = nassauVC
        case 2: newVC = skinsVC
        default: return
        }
        transition(to: newVC)
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
