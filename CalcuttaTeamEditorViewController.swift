import UIKit

final class CalcuttaTeamEditorViewController: UIViewController {

    private let eventID: UUID
    private var team: CalcuttaTeam
    private let isNew: Bool

    init(eventID: UUID, team: CalcuttaTeam?, nextOrder: Int) {
        self.eventID = eventID
        self.isNew   = team == nil
        self.team    = team ?? CalcuttaTeam(sortOrder: nextOrder)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Fields

    private let nameField    = CalcuttaTeamEditorViewController.field("Team name")
    private let bidField     = CalcuttaTeamEditorViewController.field("Bid amount ($)", keyboard: .decimalPad)
    private let captainField = CalcuttaTeamEditorViewController.field("Captain name")
    private let playerFields: [UITextField] = (1...4).map {
        CalcuttaTeamEditorViewController.field("Player \($0)")
    }
    private let captainOnlySwitch = UISwitch()
    private let scrollView = UIScrollView()
    private let outerStack = UIStackView()

    // Cards to show/hide
    private var captainCard: UIView!
    private var playersCard: UIView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = isNew ? "Add Team" : "Edit Team"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

        if !isNew {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Delete", style: .plain, target: self, action: #selector(deleteTapped))
            navigationItem.leftBarButtonItem?.tintColor = .systemRed
        }

        buildLayout()
        populateFields()
        updateRosterUI(animated: false)
    }

    // MARK: - Layout

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        outerStack.axis = .vertical
        outerStack.spacing = 24
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            outerStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            outerStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            outerStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40),
            outerStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])

        // Team info card
        outerStack.addArrangedSubview(sectionHeader("TEAM INFO"))
        let infoRows: [(String, UITextField)] = [("Team Name", nameField), ("Bid ($)", bidField)]
        outerStack.addArrangedSubview(fieldCard(rows: infoRows))

        // Roster type card
        outerStack.addArrangedSubview(sectionHeader("ROSTER"))
        outerStack.addArrangedSubview(switchCard())

        // Captain card (shown when captain-only)
        captainCard = fieldCard(rows: [("Captain", captainField)])
        outerStack.addArrangedSubview(captainCard)

        // Players card (shown when full roster)
        let playerRows: [(String, UITextField)] = (0..<4).map { ("Player \($0 + 1)", playerFields[$0]) }
        playersCard = fieldCard(rows: playerRows)
        outerStack.addArrangedSubview(playersCard)
    }

    // ── Card builders ──────────────────────────────────────────

    private func fieldCard(rows: [(String, UITextField)]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0

        for (i, (label, field)) in rows.enumerated() {
            let row = makeRow(label: label, field: field)
            stack.addArrangedSubview(row)
            if i < rows.count - 1 {
                stack.addArrangedSubview(divider())
            }
        }

        return card(containing: stack)
    }

    private func switchCard() -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let label = UILabel()
        label.text = "Captain only"
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false

        captainOnlySwitch.isOn = team.useCaptainOnly
        captainOnlySwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        captainOnlySwitch.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)
        row.addSubview(captainOnlySwitch)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            captainOnlySwitch.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            captainOnlySwitch.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])

        return card(containing: row)
    }

    private func card(containing child: UIView) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        child.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: container.topAnchor),
            child.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            child.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    private func makeRow(label: String, field: UITextField) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 17)
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        field.textAlignment = .right
        field.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(lbl)
        row.addSubview(field)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.leadingAnchor.constraint(equalTo: lbl.trailingAnchor, constant: 8),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        return row
    }

    private func divider() -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        let line = UIView()
        line.backgroundColor = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(line)
        NSLayoutConstraint.activate([
            line.heightAnchor.constraint(equalToConstant: 0.5),
            line.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            line.topAnchor.constraint(equalTo: wrapper.topAnchor),
            line.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        return wrapper
    }

    private func sectionHeader(_ text: String) -> UIView {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 13, weight: .regular)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 4),
            lbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lbl.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -4),
            lbl.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
        ])
        return wrapper
    }

    private func populateFields() {
        nameField.text = team.teamName
        if team.bidAmount > 0 {
            bidField.text = team.bidAmount.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(team.bidAmount)) : String(team.bidAmount)
        }
        captainField.text = team.captain
        for (i, pf) in playerFields.enumerated() {
            pf.text = i < team.players.count ? team.players[i] : ""
        }
    }

    // MARK: - Toggle

    @objc private func switchToggled() { updateRosterUI(animated: true) }

    private func updateRosterUI(animated: Bool) {
        let captainOnly = captainOnlySwitch.isOn
        let update = {
            self.captainCard.isHidden = !captainOnly
            self.playersCard.isHidden = captainOnly
        }
        if animated {
            UIView.animate(withDuration: 0.2) { update(); self.view.layoutIfNeeded() }
        } else {
            update()
        }
    }

    // MARK: - Save / Delete

    @objc private func saveTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            showAlert("Team name required", "Please enter a team name.")
            return
        }
        let bid = Double(bidField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0

        team.teamName = name
        team.bidAmount = bid
        team.useCaptainOnly = captainOnlySwitch.isOn
        team.captain = captainField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        team.players = playerFields.map { $0.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }

        guard var event = CalcuttaStore.shared.events.first(where: { $0.id == eventID }) else { return }
        if let idx = event.teams.firstIndex(where: { $0.id == team.id }) {
            let oldName = event.teams[idx].teamName
            event.teams[idx] = team
            if oldName != name, let li = event.day1Board.firstIndex(where: { $0.teamName == oldName }) {
                event.day1Board[li].teamName = name
            }
        } else {
            event.teams.append(team)
        }
        CalcuttaStore.shared.save(event)
        navigationController?.popViewController(animated: true)
    }

    @objc private func deleteTapped() {
        let ac = UIAlertController(
            title: "Remove \"\(team.teamName)\"?",
            message: "This will also remove their Day 1 entry.",
            preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self,
                  var event = CalcuttaStore.shared.events.first(where: { $0.id == self.eventID }) else { return }
            event.teams.removeAll { $0.id == self.team.id }
            event.day1Board.removeAll { $0.teamName == self.team.teamName }
            CalcuttaStore.shared.save(event)
            self.navigationController?.popViewController(animated: true)
        })
        present(ac, animated: true)
    }

    private func showAlert(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Field factory

    private static func field(_ placeholder: String, keyboard: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = keyboard
        tf.returnKeyType = .next
        tf.clearButtonMode = .whileEditing
        tf.font = .systemFont(ofSize: 17)
        return tf
    }
}
