import UIKit

/// Bulk-paste roster entries. Parses one player per line; shows valid/invalid preview.
final class ClubEventPasteRosterViewController: UIViewController {

    static let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)

    private struct ParsedRow {
        let line: String
        let name: String?
        let handicap: Int?
        let error: String?
        var isValid: Bool { name != nil && handicap != nil && error == nil }
    }

    private let event: ClubEventRecord
    private var existingRoster: [ClubEventPlayer]
    private var initialText: String?
    private var rows: [ParsedRow] = []
    private var parseTimer: Timer?

    private let textView = UITextView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addButton = UIButton(type: .system)
    private let placeholderLabel = UILabel()

    init(event: ClubEventRecord, existingRoster: [ClubEventPlayer] = [], initialText: String? = nil) {
        self.event = event
        self.existingRoster = existingRoster
        self.initialText = initialText
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Paste Roster"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        buildUI()

        if let t = initialText {
            textView.text = t
            placeholderLabel.isHidden = !t.isEmpty
            parseNow()
        }
    }

    private func buildUI() {
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.autocapitalizationType = .words
        textView.autocorrectionType = .no
        textView.backgroundColor = .systemBackground
        textView.layer.cornerRadius = 10
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        placeholderLabel.text = "One player per line:\n  First Last, HC\n  Moore, Patrick, 12\n  Smith John 8"
        placeholderLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.numberOfLines = 0
        placeholderLabel.isUserInteractionEnabled = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .singleLine
        tableView.estimatedRowHeight = 48
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = Self.darkGreen
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.title = "Add 0 valid players"
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        addButton.configuration = cfg
        addButton.isEnabled = false
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.38),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 10),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -10),

            tableView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -12),

            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            addButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
    }

    // MARK: - Parse

    private func scheduleParse() {
        parseTimer?.invalidate()
        parseTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.parseNow()
        }
    }

    private func parseNow() {
        let lines = (textView.text ?? "").components(separatedBy: .newlines)
        rows = lines.compactMap { parseLine($0) }
        let valid = rows.filter { $0.isValid }.count
        addButton.configuration?.title = valid == 1 ? "Add 1 valid player" : "Add \(valid) valid players"
        addButton.isEnabled = valid > 0
        tableView.reloadData()
    }

    private func parseLine(_ raw: String) -> ParsedRow? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }

        // Split on commas or whitespace tokens, preserving order
        let commaParts = trimmed.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        if commaParts.count >= 3 {
            let first = commaParts[0]
            let second = commaParts[1]
            let hcStr = commaParts[2]
            let fullName: String
            if let _ = Int(second) {
                // Last, First, HC? Odd; but handle "First Last, HC, extra"
                fullName = "\(first) \(second)"
            } else {
                // "Last, First, HC" → "First Last"
                fullName = "\(second) \(first)"
            }
            guard let hc = Int(hcStr) else {
                return ParsedRow(line: trimmed, name: fullName, handicap: nil,
                                 error: "No handicap found")
            }
            guard hc >= 0 && hc <= 54 else {
                return ParsedRow(line: trimmed, name: fullName, handicap: nil,
                                 error: "Invalid handicap (must be 0–54)")
            }
            return ParsedRow(line: trimmed, name: fullName, handicap: hc, error: nil)
        }

        if commaParts.count == 2 {
            let name = commaParts[0]
            let hcStr = commaParts[1]
            guard !name.isEmpty else {
                return ParsedRow(line: trimmed, name: nil, handicap: nil, error: "Missing name")
            }
            guard let hc = Int(hcStr) else {
                return ParsedRow(line: trimmed, name: name, handicap: nil,
                                 error: "No handicap found")
            }
            guard hc >= 0 && hc <= 54 else {
                return ParsedRow(line: trimmed, name: name, handicap: nil,
                                 error: "Invalid handicap (must be 0–54)")
            }
            return ParsedRow(line: trimmed, name: name, handicap: hc, error: nil)
        }

        // Single-part line "First Last HC"
        let tokens = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard tokens.count >= 2 else {
            return ParsedRow(line: trimmed, name: trimmed, handicap: nil,
                             error: "No handicap found")
        }
        if let hc = Int(tokens.last!) {
            guard hc >= 0 && hc <= 54 else {
                return ParsedRow(line: trimmed, name: tokens.dropLast().joined(separator: " "),
                                 handicap: nil, error: "Invalid handicap (must be 0–54)")
            }
            let name = tokens.dropLast().joined(separator: " ")
            guard !name.isEmpty else {
                return ParsedRow(line: trimmed, name: nil, handicap: nil, error: "Missing name")
            }
            return ParsedRow(line: trimmed, name: name, handicap: hc, error: nil)
        }
        return ParsedRow(line: trimmed, name: trimmed, handicap: nil, error: "No handicap found")
    }

    // MARK: - Submit

    @objc private func addTapped() {
        let validPlayers: [(name: String, handicap: Double)] = rows.compactMap { r in
            guard r.isValid, let name = r.name, let hc = r.handicap else { return nil }
            return (name: name, handicap: Double(hc))
        }
        guard !validPlayers.isEmpty else { return }

        let existingNames = Set(existingRoster.map { $0.playerName.lowercased() })
        let duplicates   = validPlayers.filter { existingNames.contains($0.name.lowercased()) }
        let nonDupes     = validPlayers.filter { !existingNames.contains($0.name.lowercased()) }
        if !duplicates.isEmpty {
            let nameList = duplicates.map { $0.name }.joined(separator: ", ")
            let countWord = duplicates.count == 1 ? "is" : "are"
            let skipTitle = duplicates.count == 1
                ? "Use existing \(duplicates[0].name)"
                : "Skip \(duplicates.count) duplicates"
            let ac = UIAlertController(
                title: duplicates.count == 1
                    ? "\(duplicates[0].name) is already on the roster"
                    : "Duplicate players",
                message: "\(nameList) \(countWord) already on the roster.",
                preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Add all as new", style: .destructive) { [weak self] _ in
                self?.performAdd(validPlayers)
            })
            let skipAction = UIAlertAction(title: skipTitle, style: .default) { [weak self] _ in
                guard let self else { return }
                if nonDupes.isEmpty {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.performAdd(nonDupes)
                }
            }
            ac.addAction(skipAction)
            ac.preferredAction = skipAction
            present(ac, animated: true)
            return
        }
        performAdd(validPlayers)
    }

    private func performAdd(_ validPlayers: [(name: String, handicap: Double)]) {
        addButton.isEnabled = false
        Task {
            do {
                try await SupabaseService.shared.batchAddClubEventPlayers(
                    tournamentId: event.id, players: validPlayers)
                await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.addButton.isEnabled = true
                    let ac = UIAlertController(title: nil,
                                               message: "Could not add players.\n\n\(error.localizedDescription)",
                                               preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        }
    }
}

// MARK: - TextView delegate

extension ClubEventPasteRosterViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !(textView.text ?? "").isEmpty
        scheduleParse()
    }
}

// MARK: - Table

extension ClubEventPasteRosterViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let row = rows[indexPath.row]
        var cfg = cell.defaultContentConfiguration()
        if row.isValid {
            cfg.image = UIImage(systemName: "checkmark.circle.fill")
            cfg.imageProperties.tintColor = .systemGreen
            cfg.text = row.name ?? row.line
            cfg.secondaryText = "HC \(row.handicap ?? 0)"
        } else {
            cfg.image = UIImage(systemName: "xmark.circle.fill")
            cfg.imageProperties.tintColor = .systemRed
            cfg.text = row.line
            cfg.secondaryText = row.error ?? "Invalid"
            cfg.secondaryTextProperties.color = .systemRed
        }
        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tv: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
