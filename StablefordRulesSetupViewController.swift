import UIKit

final class StablefordRulesSetupViewController: UIViewController {

    var onStart: (() -> Void)?

    private let baselineSegment  = UISegmentedControl(items: ["Par", "Bogey"])
    private let teamCountSegment = UISegmentedControl(items: ["Best 2", "Best 3", "All 4"])
    private let startButton      = UIButton(type: .system)

    private let tint = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stableford Rules"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
        )
        setupUI()
        loadCurrentSettings()
    }

    private func setupUI() {
        let card = UIView()
        card.backgroundColor    = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 14
        card.layer.shadowColor  = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset  = CGSize(width: 0, height: 2)
        card.layer.shadowRadius  = 6
        card.translatesAutoresizingMaskIntoConstraints = false

        let baselineRow  = makeRow(label: "Scoring Baseline", control: baselineSegment)
        let teamCountRow = makeRow(label: "Scores That Count Per Hole", control: teamCountSegment)

        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let stack = UIStackView(arrangedSubviews: [baselineRow, sep, teamCountRow])
        stack.axis    = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        startButton.configuration = wmStyledButton(title: "Start Tournament", style: .primary)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        let hintLabel = UILabel()
        hintLabel.text          = "Par: eagle=3, birdie=2, par=1, bogey=0\nBogey: birdie=3, par=2, bogey=1, double=0"
        hintLabel.font          = .systemFont(ofSize: 12)
        hintLabel.textColor     = .secondaryLabel
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(card)
        view.addSubview(hintLabel)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),

            hintLabel.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 12),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    private func makeRow(label text: String, control: UISegmentedControl) -> UIView {
        let label = UILabel()
        label.text      = text
        label.font      = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis    = .vertical
        stack.spacing = 10
        return stack
    }

    private func loadCurrentSettings() {
        guard let g = GameManager.shared.currentGame else { return }
        baselineSegment.selectedSegmentIndex = (g.stablefordBaseline == .bogey) ? 1 : 0
        switch g.stablefordCountingPlayers {
        case 2:  teamCountSegment.selectedSegmentIndex = 0
        case 4:  teamCountSegment.selectedSegmentIndex = 2
        default: teamCountSegment.selectedSegmentIndex = 1
        }
    }

    @objc private func startTapped() {
        let baseline: StablefordBaseline = (baselineSegment.selectedSegmentIndex == 1) ? .bogey : .par
        let teamCount: Int
        switch teamCountSegment.selectedSegmentIndex {
        case 0:  teamCount = 2
        case 2:  teamCount = 4
        default: teamCount = 3
        }
        GameManager.shared.update { g in
            g.stablefordBaseline        = baseline
            g.stablefordCountingPlayers = teamCount
        }
        GameManager.shared.saveCurrent()
        dismiss(animated: true) { [weak self] in self?.onStart?() }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
