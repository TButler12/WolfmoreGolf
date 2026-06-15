import UIKit

final class TeeGameSetupViewController: UIViewController {

    // MARK: - UI

    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    private let nameField        = UITextField()
    private let gameTypeControl  = UISegmentedControl(items: ["Wolf", "Skins", "Stableford"])
    private let scoringControl   = UISegmentedControl(items: ["Gross", "Net"])
    private let stakeField       = UITextField()
    private let carryTiesControl = UISegmentedControl(items: ["No Carry", "Carry Ties"])
    private let createButton     = UIButton(type: .system)

    private let stakeRow  = UIView()
    private let carryRow  = UIView()

    private let stakeLabel = UILabel()
    private let carryLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Tee Game"
        view.backgroundColor = .systemBackground
        setupTapToDismiss()
        setupScrollView()
        setupFields()
        setupCreateButton()
        gameTypeChanged()
    }

    // MARK: - Keyboard dismissal

    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func makeNumberPadToolbar() -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done   = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [spacer, done]
        return toolbar
    }

    // MARK: - Layout

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    private func setupFields() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])

        // Tournament name
        stack.addArrangedSubview(labeled("Tournament Name", field: nameField))
        nameField.placeholder = "e.g. Saturday Skins"
        nameField.borderStyle = .roundedRect
        nameField.autocapitalizationType = .words
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .done
        nameField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)

        // Game type — Wolf (0), Skins (1), Stableford (2)
        stack.addArrangedSubview(labeled("Format", control: gameTypeControl))
        gameTypeControl.selectedSegmentIndex = 0
        gameTypeControl.addTarget(self, action: #selector(gameTypeChanged), for: .valueChanged)

        // Scoring type (shown for all formats)
        stack.addArrangedSubview(labeled("Scoring", control: scoringControl))
        scoringControl.selectedSegmentIndex = 0

        // Stake (Skins only)
        stakeLabel.text = "Stake ($ per hole)"
        stakeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        stakeLabel.textColor = .secondaryLabel
        stakeField.placeholder = "e.g. 5"
        stakeField.borderStyle = .roundedRect
        stakeField.keyboardType = .numberPad
        stakeField.inputAccessoryView = makeNumberPadToolbar()
        let stakeStack = UIStackView(arrangedSubviews: [stakeLabel, stakeField])
        stakeStack.axis = .vertical
        stakeStack.spacing = 6
        stakeRow.translatesAutoresizingMaskIntoConstraints = false
        stakeRow.addSubview(stakeStack)
        stakeStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stakeStack.topAnchor.constraint(equalTo: stakeRow.topAnchor),
            stakeStack.leadingAnchor.constraint(equalTo: stakeRow.leadingAnchor),
            stakeStack.trailingAnchor.constraint(equalTo: stakeRow.trailingAnchor),
            stakeStack.bottomAnchor.constraint(equalTo: stakeRow.bottomAnchor),
        ])
        stack.addArrangedSubview(stakeRow)

        // Carry ties (Skins only)
        carryLabel.text = "Ties"
        carryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        carryLabel.textColor = .secondaryLabel
        carryTiesControl.selectedSegmentIndex = 0
        let carryStack = UIStackView(arrangedSubviews: [carryLabel, carryTiesControl])
        carryStack.axis = .vertical
        carryStack.spacing = 6
        carryRow.translatesAutoresizingMaskIntoConstraints = false
        carryRow.addSubview(carryStack)
        carryStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            carryStack.topAnchor.constraint(equalTo: carryRow.topAnchor),
            carryStack.leadingAnchor.constraint(equalTo: carryRow.leadingAnchor),
            carryStack.trailingAnchor.constraint(equalTo: carryRow.trailingAnchor),
            carryStack.bottomAnchor.constraint(equalTo: carryRow.bottomAnchor),
        ])
        stack.addArrangedSubview(carryRow)
    }

    private func setupCreateButton() {
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
        cfg.title = "Create Tournament"
        createButton.configuration = cfg
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        view.addSubview(createButton)

        NSLayoutConstraint.activate([
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        scrollView.contentInset.bottom = 80
    }

    // MARK: - Helpers

    private func labeled(_ title: String, field: UITextField) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [label, field])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    private func labeled(_ title: String, control: UISegmentedControl) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    // MARK: - Actions

    @objc private func gameTypeChanged() {
        // Stake and carry ties are Skins-only (index 1)
        let isSkins = gameTypeControl.selectedSegmentIndex == 1
        stakeRow.isHidden = !isSkins
        carryRow.isHidden = !isSkins
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func createTapped() {
        // Capture all control values before endEditing to avoid any responder-chain side-effects
        let name        = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let gameIdx     = gameTypeControl.selectedSegmentIndex
        let scoringIdx  = scoringControl.selectedSegmentIndex
        let stakeText   = stakeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let carryIdx    = carryTiesControl.selectedSegmentIndex
        let courseName  = GameManager.shared.currentGame?.course.name ?? ""

        view.endEditing(true)

        guard !name.isEmpty else {
            showError("Please enter a tournament name.")
            return
        }

        let gameType: String
        switch gameIdx {
        case 0: gameType = "wolf"
        case 1: gameType = "skins"
        default: gameType = "stableford"
        }
        let scoringType = scoringIdx == 0 ? "gross" : "net"
        var stake: Double? = nil
        var carryTies: Bool? = nil

        if gameType == "skins" {
            if !stakeText.isEmpty {
                guard let s = Double(stakeText), s > 0 else {
                    showError("Please enter a valid stake amount.")
                    return
                }
                stake = s
            }
            carryTies = (carryIdx == 1)
            print("🃏 carryIdx=\(carryIdx) → carryTies=\(carryTies!)")
        }

        let spinner = UIAlertController(title: nil, message: "Creating tournament…", preferredStyle: .alert)
        present(spinner, animated: true)

        Task {
            do {
                let record = try await SupabaseService.shared.createTournament(
                    name: name,
                    gameType: gameType,
                    scoringType: scoringType,
                    stake: stake,
                    carryTies: carryTies,
                    courseName: courseName
                )
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        GameManager.shared.update { g in
                            g.tournamentCode        = record.code
                            g.groupCode             = record.id
                            g.tournamentMatchId     = UUID().uuidString
                            g.tournamentName        = record.name
                            g.tournamentGameType    = record.gameType
                            g.tournamentScoringType = record.scoring
                        }
                        GameManager.shared.saveCurrent()
                        self.showSuccess(code: record.code)
                    }
                }
            } catch {
                print("❌ createTournament error: \(error)")
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Failed to create tournament.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func showSuccess(code: String) {
        let ac = UIAlertController(
            title: "Tournament Created!",
            message: "Share this code with your group:\n\n\(code)\n\nThey can join from the Tee Games screen.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Copy Code", style: .default) { [weak self] _ in
            UIPasteboard.general.string = code
            self?.navigationController?.dismiss(animated: true)
        })
        ac.addAction(UIAlertAction(title: "Done", style: .cancel) { [weak self] _ in
            self?.navigationController?.dismiss(animated: true)
        })
        present(ac, animated: true)
    }

    private func showError(_ message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
