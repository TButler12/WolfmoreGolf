import UIKit

final class StablefordRulesSetupViewController: UIViewController {

    var onStart: (() -> Void)?

    private let baselineSegment  = UISegmentedControl(items: ["Par", "Bogey"])
    private let teamCountSegment = UISegmentedControl(items: ["Best 2", "Best 3", "All 4"])
    private let modeSegment      = UISegmentedControl(items: ["Standard", "Modified"])
    private var sfStepperValues  = [0: 8, 1: 4, 2: 2, 3: 0, 4: -1, 5: -3]  // 0=dblEagle,1=eagle,2=birdie,3=par,4=bogey,5=dblBogey
    private weak var modifiedStack: UIStackView?
    private weak var hintLabel: UILabel?
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

        modeSegment.selectedSegmentIndex = 0
        modeSegment.addTarget(self, action: #selector(sfModeChanged), for: .valueChanged)
        let modeRow = makeRow(label: "Scoring Mode", control: modeSegment)

        let modStack = buildModifiedSFStack()
        modifiedStack = modStack
        modStack.isHidden = true
        modStack.translatesAutoresizingMaskIntoConstraints = false

        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let stack = UIStackView(arrangedSubviews: [baselineRow, sep, teamCountRow, modeRow, modStack])
        stack.axis    = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        startButton.configuration = wmStyledButton(title: "Start Tournament", style: .primary)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        let hint = UILabel()
        hint.text          = standardHintText()
        hint.font          = .systemFont(ofSize: 12)
        hint.textColor     = .secondaryLabel
        hint.numberOfLines = 0
        hint.textAlignment = .center
        hint.translatesAutoresizingMaskIntoConstraints = false
        hintLabel = hint

        view.addSubview(card)
        view.addSubview(hint)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),

            hint.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 12),
            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    private func standardHintText() -> String {
        "Par: eagle=3, birdie=2, par=1, bogey=0\nBogey: birdie=3, par=2, bogey=1, double=0"
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
        let isModified = g.stablefordMode == .modified
        modeSegment.selectedSegmentIndex = isModified ? 1 : 0
        if isModified {
            modifiedStack?.isHidden = false
            let t = g.modifiedStablefordTable
            sfStepperValues = [0: t.doubleEagleOrBetter, 1: t.eagleOrBetter, 2: t.birdie, 3: t.par, 4: t.bogey, 5: t.doubleBogeyOrWorse]
            updateStepperUI()
            hintLabel?.text = "Points are fully configurable. Negative values allowed."
        }
    }

    private func updateStepperUI() {
        guard let modStack = modifiedStack else { return }
        for row in modStack.arrangedSubviews {
            guard let rowStack = row as? UIStackView else { continue }
            let steppers = rowStack.arrangedSubviews.compactMap { $0 as? UIStepper }
            let labels   = rowStack.arrangedSubviews.compactMap { $0 as? UILabel }
            for stepper in steppers {
                let v = sfStepperValues[stepper.tag] ?? 0
                stepper.value = Double(v)
                if let lbl = labels.first(where: { $0.tag == stepper.tag + 100 }) {
                    lbl.text = sfPointString(v)
                    lbl.textColor = v >= 0 ? .systemGreen : .systemRed
                }
            }
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
        let mode: StablefordMode = (modeSegment.selectedSegmentIndex == 1) ? .modified : .standard
        let table = ModifiedStablefordTable(
            doubleEagleOrBetter: sfStepperValues[0] ??  8,
            eagleOrBetter:       sfStepperValues[1] ??  4,
            birdie:              sfStepperValues[2] ??  2,
            par:                 sfStepperValues[3] ??  0,
            bogey:               sfStepperValues[4] ?? -1,
            doubleBogeyOrWorse:  sfStepperValues[5] ?? -3
        )
        GameManager.shared.update { g in
            g.stablefordBaseline        = baseline
            g.stablefordCountingPlayers = teamCount
            g.stablefordMode            = mode
            if mode == .modified { g.modifiedStablefordTable = table }
        }
        GameManager.shared.saveCurrent()
        dismiss(animated: true) { [weak self] in self?.onStart?() }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    // MARK: - Modified Stableford helpers

    private func buildModifiedSFStack() -> UIStackView {
        let labels   = ["Double Eagle+", "Eagle", "Birdie", "Par", "Bogey", "Double Bogey+"]
        let defaults = [8, 4, 2, 0, -1, -3]
        let rows = (0..<6).map { i -> UIView in
            sfStepperValues[i] = defaults[i]
            return makeSFStepperRow(label: labels[i], value: defaults[i], tag: i)
        }
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis    = .vertical
        stack.spacing = 10
        return stack
    }

    private func makeSFStepperRow(label text: String, value: Int, tag: Int) -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = text
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.textColor = .secondaryLabel
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = sfPointString(value)
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = value >= 0 ? .systemGreen : .systemRed
        valueLabel.textAlignment = .center
        valueLabel.tag = tag + 100
        valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true

        let stepper = UIStepper()
        stepper.minimumValue = -10
        stepper.maximumValue = 10
        stepper.stepValue = 1
        stepper.value = Double(value)
        stepper.tag = tag
        stepper.addTarget(self, action: #selector(sfStepperChanged(_:)), for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [nameLabel, valueLabel, stepper])
        row.axis      = .horizontal
        row.spacing   = 8
        row.alignment = .center
        return row
    }

    private func sfPointString(_ v: Int) -> String { v > 0 ? "+\(v)" : "\(v)" }

    @objc private func sfModeChanged() {
        let isModified = modeSegment.selectedSegmentIndex == 1
        modifiedStack?.isHidden = !isModified
        hintLabel?.text = isModified
            ? "Points are fully configurable. Negative values allowed."
            : standardHintText()
    }

    @objc private func sfStepperChanged(_ stepper: UIStepper) {
        let v = Int(stepper.value)
        sfStepperValues[stepper.tag] = v
        if let row = stepper.superview as? UIStackView,
           let lbl = row.arrangedSubviews.compactMap({ $0 as? UILabel }).first(where: { $0.tag == stepper.tag + 100 }) {
            lbl.text = sfPointString(v)
            lbl.textColor = v >= 0 ? .systemGreen : .systemRed
        }
    }
}
