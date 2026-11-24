import UIKit
import UniformTypeIdentifiers

/// Organizer roster manager — add, edit, delete, bulk-paste/import.
final class ClubEventRosterViewController: UITableViewController {

    static let teal = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)

    private let event: ClubEventRecord
    private var roster: [ClubEventPlayer] = []
    private var isLoading = false

    init(event: ClubEventRecord) {
        self.event = event
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Roster"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 44

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"),
                            style: .plain, target: self, action: #selector(moreTapped)),
        ]
        updateDoneButton()

        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(reload), for: .valueChanged)
        tableView.refreshControl = rc
    }

    private func updateDoneButton() {
        let title = roster.isEmpty ? "Done" : "Done (\(roster.count))"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: title, style: .done, target: self, action: #selector(doneTapped))
    }

    @objc private func doneTapped() {
        navigationController?.popViewController(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    @objc private func reload() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                let r = try await SupabaseService.shared.fetchClubEventRoster(tournamentId: event.id)
                await MainActor.run {
                    self.isLoading = false
                    self.roster = r
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    self.updateDoneButton()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.tableView.refreshControl?.endRefreshing()
                    self.showAlert("Could not load roster.\n\n\(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(roster.count, 1)
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        // Always clear both configuration and custom subviews to avoid reuse bleed
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        if roster.isEmpty {
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "No players yet"
            cfg.secondaryText = "Tap + to add, or use ⋯ to paste."
            cfg.textProperties.color = .secondaryLabel
            cell.contentConfiguration = cfg
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell
        }
        let player = roster[indexPath.row]

        let nameLabel = UILabel()
        nameLabel.text = player.playerName
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let hcBadge = makeBadge(text: player.displayHandicap, color: .systemGray)
        hcBadge.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [nameLabel, hcBadge])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        if let group = player.groupCode, !group.isEmpty {
            let groupBadge = makeBadge(text: group, color: .systemGreen)
            stack.addArrangedSubview(groupBadge)
        }

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10),
        ])
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    private func makeBadge(text: String, color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = color.withAlphaComponent(0.15)
        view.layer.cornerRadius = 8

        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -3),
        ])
        return view
    }

    override func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        guard !roster.isEmpty, indexPath.row < roster.count else { return }
        let player = roster[indexPath.row]
        let vc = ClubEventPlayerEditViewController(event: event, existing: player)
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tv: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !roster.isEmpty, indexPath.row < roster.count else { return nil }
        let player = roster[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.confirmDelete(player: player) { success in done(success) }
        }
        return UISwipeActionsConfiguration(actions: [action])
    }

    private func confirmDelete(player: ClubEventPlayer, done: @escaping (Bool) -> Void) {
        let ac = UIAlertController(
            title: "Delete \(player.playerName)?",
            message: "This cannot be undone.",
            preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in done(false) })
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePlayer(player, done: done)
        })
        present(ac, animated: true)
    }

    private func deletePlayer(_ player: ClubEventPlayer, done: @escaping (Bool) -> Void) {
        Task {
            do {
                try await SupabaseService.shared.deleteClubEventPlayer(id: player.id)
                await MainActor.run {
                    done(true)
                    self.reload()
                }
            } catch {
                await MainActor.run {
                    done(false)
                    self.showAlert("Could not delete.\n\n\(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Add / More

    @objc private func addTapped() {
        let vc = ClubEventPlayerEditViewController(event: event, existing: nil)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func moreTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Copy from Past Event", style: .default) { [weak self] _ in
            self?.openCopyFromPastEvent()
        })
        sheet.addAction(UIAlertAction(title: "Paste Roster", style: .default) { [weak self] _ in
            self?.openPasteRoster()
        })
        sheet.addAction(UIAlertAction(title: "Import CSV from Files", style: .default) { [weak self] _ in
            self?.openFilePicker()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        present(sheet, animated: true)
    }

    private func openCopyFromPastEvent() {
        let vc = ClubEventCopyRosterViewController(event: event, currentRoster: roster)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openPasteRoster() {
        let vc = ClubEventPasteRosterViewController(event: event, existingRoster: roster)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openFilePicker() {
        let types: [UTType] = [UTType.commaSeparatedText, UTType.plainText]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - Document picker

extension ClubEventRosterViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            showAlert("Could not read file.")
            return
        }
        let vc = ClubEventPasteRosterViewController(event: event, existingRoster: roster, initialText: text)
        navigationController?.pushViewController(vc, animated: true)
    }
}
