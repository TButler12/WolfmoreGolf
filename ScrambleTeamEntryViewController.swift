import UIKit

final class ScrambleTeamEntryViewController: UIViewController {

    var allowSkip = false
    /// Called when the user taps Continue with a valid team name.
    /// The VC does not dismiss itself — the caller handles async work and navigation.
    var submit: ((_ vc: ScrambleTeamEntryViewController, _ teamName: String, _ playerNames: [String], _ startingHole: Int) -> Void)?
    var onSkip: (() -> Void)?

    private let teamNameField = UITextField()
    private let playerFields  = (0..<4).map { _ in UITextField() }

    private var startingHoleValue: Int = 1
    private let startingHoleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Your Team"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        if allowSkip {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Skip", style: .plain, target: self, action: #selector(skipTapped))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        teamNameField.becomeFirstResponder()
    }

    private func setupLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
        ])

        let intro = UILabel()
        intro.text = "Enter your team name and optionally list the players."
        intro.font = .preferredFont(forTextStyle: .subheadline)
        intro.textColor = .secondaryLabel
        intro.numberOfLines = 0
        stack.addArrangedSubview(intro)

        stack.addArrangedSubview(makeRow("Team Name", field: teamNameField, placeholder: "e.g. Team Alpha"))
        stack.addArrangedSubview(makeStartingHoleRow())

        let playersHeader = UILabel()
        playersHeader.text = "PLAYERS (OPTIONAL)"
        playersHeader.font = .systemFont(ofSize: 12, weight: .semibold)
        playersHeader.textColor = .secondaryLabel
        stack.addArrangedSubview(playersHeader)

        for (i, field) in playerFields.enumerated() {
            stack.addArrangedSubview(makeRow("Player \(i + 1)", field: field, placeholder: "Player name"))
        }

        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor(red: 0.22, green: 0.62, blue: 0.34, alpha: 1.0)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            return a
        }
        cfg.title = "Continue"
        let continueButton = UIButton(type: .system)
        continueButton.configuration = cfg
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        stack.addArrangedSubview(continueButton)

        let allFields = [teamNameField] + playerFields
        for field in allFields {
            field.autocapitalizationType = .words
            field.autocorrectionType = .no
            field.borderStyle = .roundedRect
            field.returnKeyType = .next
            field.addTarget(self, action: #selector(fieldReturn(_:)), for: .editingDidEndOnExit)
        }
        playerFields.last?.returnKeyType = .done
        playerFields.last?.addTarget(self, action: #selector(continueTapped), for: .editingDidEndOnExit)
    }

    private func makeStartingHoleRow() -> UIView {
        let label = UILabel()
        label.text = "Starting Hole"
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel

        let minusBtn = UIButton(type: .system)
        minusBtn.setTitle("−", for: .normal)
        minusBtn.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        minusBtn.addTarget(self, action: #selector(holeDecrement), for: .touchUpInside)

        startingHoleLabel.text = "1"
        startingHoleLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        startingHoleLabel.textAlignment = .center
        startingHoleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let plusBtn = UIButton(type: .system)
        plusBtn.setTitle("+", for: .normal)
        plusBtn.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        plusBtn.addTarget(self, action: #selector(holeIncrement), for: .touchUpInside)

        let stepperRow = UIStackView(arrangedSubviews: [minusBtn, startingHoleLabel, plusBtn])
        stepperRow.axis = .horizontal
        stepperRow.alignment = .center
        stepperRow.distribution = .fill
        stepperRow.spacing = 12

        let outer = UIStackView(arrangedSubviews: [label, stepperRow])
        outer.axis = .vertical
        outer.spacing = 6
        return outer
    }

    private func makeRow(_ title: String, field: UITextField, placeholder: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        field.placeholder = placeholder
        let stack = UIStackView(arrangedSubviews: [label, field])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    @objc private func holeDecrement() {
        if startingHoleValue > 1 { startingHoleValue -= 1 }
        startingHoleLabel.text = "\(startingHoleValue)"
    }

    @objc private func holeIncrement() {
        if startingHoleValue < 18 { startingHoleValue += 1 }
        startingHoleLabel.text = "\(startingHoleValue)"
    }

    @objc private func fieldReturn(_ sender: UITextField) {
        let all = [teamNameField] + playerFields
        if let idx = all.firstIndex(of: sender), idx + 1 < all.count {
            all[idx + 1].becomeFirstResponder()
        }
    }

    @objc private func continueTapped() {
        let teamName = (teamNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teamName.isEmpty else {
            let ac = UIAlertController(title: "Team Name Required",
                message: "Please enter your team name to continue.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        let playerNames = playerFields
            .compactMap { $0.text?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        view.endEditing(true)
        submit?(self, teamName, playerNames, startingHoleValue)
    }

    @objc private func skipTapped() {
        onSkip?()
    }

    @objc private func cancelTapped() {
        if navigationController?.viewControllers.first === self {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
