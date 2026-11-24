import UIKit

/// Add / edit a single roster player. Used in both add and edit modes.
final class ClubEventPlayerEditViewController: UITableViewController {

    static let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)

    private let event: ClubEventRecord
    private let existing: ClubEventPlayer?

    private var name: String = ""
    private var handicap: String = ""

    private weak var nameField: UITextField?
    private weak var hcField:   UITextField?
    private weak var saveButton: UIButton?

    init(event: ClubEventRecord, existing: ClubEventPlayer?) {
        self.event = event
        self.existing = existing
        if let p = existing {
            self.name = p.playerName
            let hc = Int(p.handicap.rounded())
            self.handicap = "\(hc)"
        }
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = existing == nil ? "Add Player" : "Edit Player"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if existing == nil { nameField?.becomeFirstResponder() }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }
    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 2 : 1
    }

    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "PLAYER" : nil
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.accessoryType = .none
        cell.selectionStyle = .none

        if indexPath.section == 0 {
            let label = UILabel()
            label.text = indexPath.row == 0 ? "Name" : "Handicap"
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false

            let tf = UITextField()
            tf.font = .preferredFont(forTextStyle: .body)
            tf.adjustsFontForContentSizeCategory = true
            tf.textAlignment = .right
            tf.translatesAutoresizingMaskIntoConstraints = false

            if indexPath.row == 0 {
                tf.placeholder = "First Last"
                tf.text = name
                tf.autocapitalizationType = .words
                tf.returnKeyType = .next
                tf.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)
                nameField = tf
            } else {
                tf.placeholder = "0–54"
                tf.text = handicap
                tf.keyboardType = .numberPad
                tf.addTarget(self, action: #selector(hcChanged(_:)), for: .editingChanged)
                hcField = tf
            }

            cell.contentView.addSubview(label)
            cell.contentView.addSubview(tf)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                tf.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
                tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                tf.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            ])
            return cell
        }

        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = Self.darkGreen
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.title = existing == nil ? "Add Player" : "Save"
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        saveButton = btn

        cell.contentView.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            btn.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            btn.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            btn.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
        return cell
    }

    // MARK: - Actions

    @objc private func nameChanged(_ tf: UITextField) { name = tf.text ?? "" }
    @objc private func hcChanged(_ tf: UITextField)   {
        let cleaned = (tf.text ?? "").filter { $0.isNumber }
        if cleaned != tf.text { tf.text = cleaned }
        handicap = cleaned
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showAlert("Name is required."); return }
        guard let hc = Int(handicap), hc >= 0, hc <= 54 else {
            showAlert("Handicap must be a whole number between 0 and 54.")
            return
        }
        saveButton?.isEnabled = false
        Task {
            do {
                if let existing {
                    try await SupabaseService.shared.updateClubEventPlayer(
                        id: existing.id, name: trimmed, handicap: Double(hc))
                } else {
                    _ = try await SupabaseService.shared.addClubEventPlayer(
                        tournamentId: event.id, name: trimmed, handicap: Double(hc))
                }
                await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.saveButton?.isEnabled = true
                    self.showAlert("Could not save.\n\n\(error.localizedDescription)")
                }
            }
        }
    }

    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
