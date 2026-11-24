import UIKit

/// Group setup: select up to 4 players, assign Team A / Team B (or both when dual-team is on),
/// pick starting hole. Confirm claims players atomically via setup_club_event_group RPC, then pushes code + QR screen.
final class ClubEventGroupSetupViewController: UIViewController {

    private let event: ClubEventRecord

    // Local model ──────────────────────────────────────────────────────────────
    enum PlayerSource {
        case roster(ClubEventPlayer)
        case walkOn(name: String, handicap: Int)

        var displayName: String {
            switch self { case .roster(let p): return p.playerName; case .walkOn(let n, _): return n }
        }
        var displayHandicap: String {
            switch self {
            case .roster(let p): return p.displayHandicap
            case .walkOn(_, let h): return h == 0 ? "Scratch" : "HC \(h)"
            }
        }
    }
    var selected: [(source: PlayerSource, teams: [String])] = []
    var allRoster: [ClubEventPlayer] = []
    var skipNetworkLoad = false
    var allowDualTeam = false   // internal for tests
    var isConfirmEnabled: Bool { confirmItem?.isEnabled ?? false }

    private var startingHole: Int = 1
    private var isLoading = false

    // Show "Who plays on both teams?" helper row when 3 players + dual-team enabled.
    private var showDualPicker: Bool { selected.count == 3 && allowDualTeam }

    // UI ───────────────────────────────────────────────────────────────────────
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let spinner   = UIActivityIndicatorView(style: .medium)
    private weak var confirmItem: UIBarButtonItem?

    private enum Section: Int, CaseIterable {
        case myGroup, startingHole, roster
    }

    init(event: ClubEventRecord) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = event.name
        view.backgroundColor = .systemGroupedBackground

        let confirm = UIBarButtonItem(title: "Confirm", style: .done,
                                      target: self, action: #selector(confirmTapped))
        confirm.isEnabled = false
        navigationItem.rightBarButtonItem = confirm
        confirmItem = confirm

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self,          forCellReuseIdentifier: "Cell")
        tableView.register(SelectedPlayerCell.self,        forCellReuseIdentifier: "Selected")
        tableView.register(StartingHoleCell.self,          forCellReuseIdentifier: "Hole")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshRoster), for: .valueChanged)
        tableView.refreshControl = refresh

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        view.addSubview(tableView)
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        loadRoster()
    }

    // MARK: - Load

    private func loadRoster() {
        guard !skipNetworkLoad else { return }
        isLoading = true
        spinner.startAnimating()
        Task {
            do {
                async let rosterTask = SupabaseService.shared.fetchClubEventRoster(tournamentId: event.id)
                async let rulesTask  = SupabaseService.shared.fetchClubEventRules(tournamentId: event.id)
                let (rows, rules) = try await (rosterTask, rulesTask)
                await MainActor.run {
                    self.allRoster     = rows
                    self.allowDualTeam = rules?.allowDualTeam ?? false
                    self.isLoading     = false
                    self.spinner.stopAnimating()
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                    self.updateConfirmState()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.spinner.stopAnimating()
                    self.tableView.refreshControl?.endRefreshing()
                    self.showError("Could not load roster: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func refreshRoster() { loadRoster() }

    // MARK: - Helpers

    private var availableRosterRows: [ClubEventPlayer] {
        let selectedIDs: Set<UUID> = Set(selected.compactMap {
            if case .roster(let p) = $0.source { return p.id } else { return nil }
        })
        return allRoster.filter { !selectedIDs.contains($0.id) }
    }

    private func defaultTeams(for index: Int) -> [String] {
        switch index {
        case 0, 1: return ["A"]
        case 2, 3: return ["B"]
        default:   return ["A"]
        }
    }

    // internal so tests can call it directly after mutating `selected`
    func updateConfirmState() {
        let aCount = selected.filter { $0.teams.contains("A") }.count
        let bCount = selected.filter { $0.teams.contains("B") }.count
        // Valid: Team A has 1–2 players; Team B is either empty or has 1–2 players.
        confirmItem?.isEnabled = aCount >= 1 && aCount <= 2 && bCount <= 2
    }

    // MARK: - Confirm

    @objc private func confirmTapped() {
        guard confirmItem?.isEnabled == true else { return }

        // With 3 players + dual-team on, require the user to pick who plays both.
        if showDualPicker && !selected.contains(where: { $0.teams.count > 1 }) {
            promptDualTeamPlayer()
            return
        }

        let code = ClubEventGroupSetupViewController.randomGroupCode()
        let spinner = UIAlertController(title: nil, message: "Setting up group…", preferredStyle: .alert)
        present(spinner, animated: true)

        Task {
            do {
                let scoringPlayers = try await setupGroup(code: code)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.pushCodeScreen(code: code, players: scoringPlayers)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        if (error as NSError).localizedDescription.contains("already in use") {
                            Task { await self.confirmWithCode(ClubEventGroupSetupViewController.randomGroupCode()) }
                        } else {
                            self.showError("Could not set up group: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    private func setupGroup(code: String) async throws -> [ClubEventGroupPlayer] {
        let rosterPlayers: [(id: UUID, teams: [String])] = selected.compactMap {
            guard case .roster(let p) = $0.source else { return nil }
            return (p.id, $0.teams)
        }
        let walkOns: [(name: String, handicap: Int, teams: [String])] = selected.compactMap {
            guard case .walkOn(let n, let h) = $0.source else { return nil }
            return (n, h, $0.teams)
        }
        _ = try await SupabaseService.shared.setupClubEventGroup(
            tournamentId:  event.id,
            groupCode:     code,
            startingHole:  startingHole,
            rosterPlayers: rosterPlayers,
            walkOns:       walkOns
        )
        let freshRoster = try await SupabaseService.shared.fetchClubEventRoster(tournamentId: event.id)
        let groupRoster = freshRoster.filter { $0.groupCode == code }
        let nameToTeams = Dictionary(uniqueKeysWithValues: selected.map { ($0.source.displayName, $0.teams) })
        return groupRoster.map {
            ClubEventGroupPlayer(id: $0.id, name: $0.playerName, handicap: $0.handicap,
                                 teams: nameToTeams[$0.playerName] ?? ["A"])
        }
    }

    private func confirmWithCode(_ code: String) async {
        do {
            let scoringPlayers = try await setupGroup(code: code)
            await MainActor.run { pushCodeScreen(code: code, players: scoringPlayers) }
        } catch {
            await MainActor.run { showError(error.localizedDescription) }
        }
    }

    private func pushCodeScreen(code: String, players: [ClubEventGroupPlayer]) {
        let vc = ClubEventGroupCodeViewController(
            groupCode:    code,
            eventCode:    event.code,
            eventName:    event.name,
            players:      players,
            tournamentId: event.id,
            startingHole: startingHole,
            courseName:   event.courseName
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Dual-team helper

    // "Who plays on both teams?" — assigns shared + splits the other two A/B.
    private func promptDualTeamPlayer() {
        let ac = UIAlertController(title: "Who plays on both teams?",
                                   message: "They'll be on Team A and Team B. The others each get one team.",
                                   preferredStyle: .actionSheet)
        for i in selected.indices {
            let name = selected[i].source.displayName
            ac.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.assignDualPlayer(sharedIndex: i)
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    private func assignDualPlayer(sharedIndex: Int) {
        selected[sharedIndex].teams = ["A", "B"]
        let others = selected.indices.filter { $0 != sharedIndex }
        if others.count >= 1 { selected[others[0]].teams = ["A"] }
        if others.count >= 2 { selected[others[1]].teams = ["B"] }
        tableView.reloadSections(IndexSet(integer: Section.myGroup.rawValue), with: .none)
        updateConfirmState()
    }

    // MARK: - Swap offer (Full button tapped)

    private func promptSwap(team: String, for row: Int) {
        let onTeam = selected.enumerated().filter { $0.element.teams.contains(team) }
        guard !onTeam.isEmpty else { return }
        let requester = selected[row].source.displayName
        let currentNames = onTeam.map { $0.element.source.displayName }.joined(separator: ", ")
        let ac = UIAlertController(title: "Team \(team) is full (\(currentNames))",
                                   message: "Replace a player for \(requester)?",
                                   preferredStyle: .actionSheet)
        for (i, entry) in onTeam {
            ac.addAction(UIAlertAction(title: "Replace \(entry.source.displayName)", style: .default) { [weak self] _ in
                guard let self else { return }
                // Drop the replaced player from this team; if it was their only team, move them to the other.
                var replacedTeams = self.selected[i].teams.filter { $0 != team }
                if replacedTeams.isEmpty { replacedTeams = [team == "A" ? "B" : "A"] }
                self.selected[i].teams = replacedTeams
                // Add the requester to this team.
                if self.allowDualTeam {
                    if !self.selected[row].teams.contains(team) {
                        self.selected[row].teams.append(team)
                        self.selected[row].teams.sort()
                    }
                } else {
                    self.selected[row].teams = [team]
                }
                self.tableView.reloadSections(IndexSet(integer: Section.myGroup.rawValue), with: .none)
                self.updateConfirmState()
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    // MARK: - Add walk-on

    private func promptAddManually() {
        guard selected.count < 4 else {
            showError("A group can have at most 4 players.")
            return
        }
        let ac = UIAlertController(title: "Add Player",
                                   message: "Enter name and course handicap",
                                   preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder            = "Full name"
            tf.autocapitalizationType = .words
            tf.autocorrectionType     = .no
        }
        ac.addTextField { tf in
            tf.placeholder    = "Handicap (0 = Scratch)"
            tf.keyboardType   = .numberPad
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak ac] _ in
            guard let self else { return }
            let name = (ac?.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let hcStr = (ac?.textFields?[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            let hc = Int(hcStr) ?? 0
            let nameLower = name.lowercased()
            let existingPlayer = self.allRoster.first { $0.playerName.lowercased() == nameLower }
            let existsInGroup  = self.selected.contains { $0.source.displayName.lowercased() == nameLower }

            if existsInGroup {
                self.showError("\(name) is already in this group.")
                return
            }
            if let existing = existingPlayer {
                let warn = UIAlertController(
                    title: "\(name) is already on the roster",
                    message: "Use the existing player or add a new one?",
                    preferredStyle: .alert)
                warn.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                warn.addAction(UIAlertAction(title: "Add as new player", style: .destructive) { [weak self] _ in
                    guard let self else { return }
                    let teams = self.defaultTeams(for: self.selected.count)
                    self.selected.append((.walkOn(name: name, handicap: hc), teams))
                    self.afterPlayerAdded()
                })
                let useExisting = UIAlertAction(title: "Use existing \(name)", style: .default) { [weak self] _ in
                    guard let self else { return }
                    let teams = self.defaultTeams(for: self.selected.count)
                    self.selected.append((.roster(existing), teams))
                    self.afterPlayerAdded()
                }
                warn.addAction(useExisting)
                warn.preferredAction = useExisting
                self.present(warn, animated: true)
                return
            }
            let teams = self.defaultTeams(for: self.selected.count)
            self.selected.append((.walkOn(name: name, handicap: hc), teams))
            self.afterPlayerAdded()
        })
        present(ac, animated: true)
    }

    // MARK: - Group code generation

    static func randomGroupCode() -> String {
        let chars = Array("23456789ABCDEFGHJKLMNPQRSTUVWXYZ")
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    private func afterPlayerAdded() {
        tableView.reloadData()
        updateConfirmState()
    }

    // MARK: - Utilities

    private func showError(_ msg: String) {
        let ac = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ClubEventGroupSetupViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .myGroup:
            let dualNote = allowDualTeam ? "Two teams: ON" : "Two teams: OFF"
            return "MY GROUP  (\(selected.count)/4)  ·  \(dualNote)"
        case .startingHole: return "STARTING HOLE"
        case .roster:       return "AVAILABLE PLAYERS"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .myGroup:
            let base = max(selected.count, 1)
            return base + (showDualPicker ? 1 : 0)
        case .startingHole:
            return 1
        case .roster:
            if isLoading { return 0 }
            return availableRosterRows.count + 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {

        case .myGroup:
            // "Who plays on both teams?" helper row
            if showDualPicker && indexPath.row == selected.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                var c = cell.defaultContentConfiguration()
                c.text = "Who plays on both teams?"
                c.textProperties.color = .systemBlue
                cell.selectionStyle = .default
                cell.accessoryType  = .none
                cell.contentConfiguration = c
                return cell
            }

            if selected.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                var c = cell.defaultContentConfiguration()
                c.text = "Tap a player below to add them"
                c.textProperties.color = .tertiaryLabel
                cell.contentConfiguration = c
                cell.selectionStyle = .none
                return cell
            }
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "Selected", for: indexPath) as! SelectedPlayerCell
            let entry  = selected[indexPath.row]
            let aCount = selected.filter { $0.teams.contains("A") }.count
            let bCount = selected.filter { $0.teams.contains("B") }.count
            cell.configure(
                name: entry.source.displayName,
                handicap: entry.source.displayHandicap,
                teams: entry.teams,
                allowDual: allowDualTeam,
                teamACount: aCount,
                teamBCount: bCount
            ) { [weak self] newTeams in
                guard let self else { return }
                self.selected[indexPath.row].teams = newTeams
                self.updateConfirmState()
                self.tableView.reloadSections(IndexSet(integer: Section.myGroup.rawValue), with: .none)
            }
            cell.onFullTeamTap = { [weak self] team in
                self?.promptSwap(team: team, for: indexPath.row)
            }
            return cell

        case .startingHole:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "Hole", for: indexPath) as! StartingHoleCell
            cell.configure(hole: startingHole) { [weak self] newHole in
                self?.startingHole = newHole
            }
            return cell

        case .roster:
            let available = availableRosterRows
            if indexPath.row == available.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                var c = cell.defaultContentConfiguration()
                c.text = "Add player manually…"
                c.textProperties.color = .systemBlue
                cell.selectionStyle = .default
                cell.accessoryType  = .none
                cell.contentConfiguration = c
                return cell
            }
            let player = available[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let isTaken = player.groupCode != nil
            var c = cell.defaultContentConfiguration()
            c.text          = player.playerName
            c.secondaryText = isTaken ? "Taken" : player.displayHandicap
            c.textProperties.color          = isTaken ? .tertiaryLabel : .label
            c.secondaryTextProperties.color = isTaken ? .tertiaryLabel : .secondaryLabel
            cell.selectionStyle = isTaken ? .none : .default
            cell.contentConfiguration = c
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .myGroup, !selected.isEmpty else { return nil }
        let aNames = selected.filter { $0.teams.contains("A") }.map { $0.source.displayName }.joined(separator: " / ")
        let bNames = selected.filter { $0.teams.contains("B") }.map { $0.source.displayName }.joined(separator: " / ")
        let aCount = selected.filter { $0.teams.contains("A") }.count
        let bCount = selected.filter { $0.teams.contains("B") }.count
        var text = "Team A: \(aNames.isEmpty ? "—" : aNames)  ·  Team B: \(bNames.isEmpty ? "—" : bNames)"
        if aCount == 0 {
            text += "\nTeam A needs at least 1 player"
        } else if aCount >= 2 && bCount >= 2 {
            text += "\nTap Full to swap a player between teams"
        }
        return text
    }
}

// MARK: - UITableViewDelegate

extension ClubEventGroupSetupViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section)! {
        case .myGroup:
            if showDualPicker && indexPath.row == selected.count {
                promptDualTeamPlayer()
            }
        case .startingHole: break
        case .roster:
            let available = availableRosterRows
            if indexPath.row == available.count {
                promptAddManually()
                return
            }
            let player = available[indexPath.row]
            guard player.groupCode == nil else { return }
            guard selected.count < 4 else {
                showError("A group can have at most 4 players.")
                return
            }
            let teams = defaultTeams(for: selected.count)
            selected.append((.roster(player), teams))
            afterPlayerAdded()
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard Section(rawValue: indexPath.section) == .myGroup,
              !selected.isEmpty,
              indexPath.row < selected.count else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            self?.selected.remove(at: indexPath.row)
            tableView.reloadData()
            self?.updateConfirmState()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - SelectedPlayerCell

final class SelectedPlayerCell: UITableViewCell {

    private let nameLabel = UILabel()
    private let hcLabel   = UILabel()
    // internal so tests can inspect button state and send actions
    let teamABtn = UIButton(type: .system)
    let teamBBtn = UIButton(type: .system)

    private var currentTeams: Set<String> = ["A"]
    private var allowDual  = false
    private var teamACnt   = 0
    private var teamBCnt   = 0
    var onTeamsChange: (([String]) -> Void)?
    // Fired when a full-team button is tapped; VC shows swap action sheet.
    var onFullTeamTap: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true

        hcLabel.font = .preferredFont(forTextStyle: .footnote)
        hcLabel.adjustsFontForContentSizeCategory = true
        hcLabel.textColor = .secondaryLabel

        for btn in [teamABtn, teamBBtn] {
            btn.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth  = 1.5
            btn.contentEdgeInsets  = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        }
        teamABtn.addTarget(self, action: #selector(teamATapped), for: .touchUpInside)
        teamBBtn.addTarget(self, action: #selector(teamBTapped), for: .touchUpInside)

        let nameRow = UIStackView(arrangedSubviews: [nameLabel, hcLabel])
        nameRow.axis      = .horizontal
        nameRow.spacing   = 8
        nameRow.alignment = .center

        let btnRow = UIStackView(arrangedSubviews: [teamABtn, teamBBtn])
        btnRow.axis    = .horizontal
        btnRow.spacing = 10

        let stack = UIStackView(arrangedSubviews: [nameRow, btnRow])
        stack.axis    = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, handicap: String, teams: [String], allowDual: Bool,
                   teamACount: Int, teamBCount: Int,
                   onChange: @escaping ([String]) -> Void) {
        nameLabel.text = name
        hcLabel.text   = handicap
        onTeamsChange  = onChange
        self.allowDual = allowDual
        self.teamACnt  = teamACount
        self.teamBCnt  = teamBCount
        currentTeams   = Set(teams)
        onFullTeamTap  = nil   // reset; VC re-sets it after configure
        updateButtonUI()
    }

    private func updateButtonUI() {
        for (btn, team) in [(teamABtn, "A"), (teamBBtn, "B")] {
            let onThisTeam = currentTeams.contains(team)
            let count = team == "A" ? teamACnt : teamBCnt
            // "Full" when 2 players on this team and this player is not one of them.
            let full = count >= 2 && !onThisTeam

            btn.isEnabled = true   // always tappable — full fires swap offer

            if full {
                btn.setTitle("Full", for: .normal)
                btn.backgroundColor = .clear
                btn.setTitleColor(.tertiaryLabel, for: .normal)
                btn.layer.borderColor = UIColor.tertiaryLabel.cgColor
            } else {
                btn.setTitle(team == "A" ? "Team A" : "Team B", for: .normal)
                btn.backgroundColor = onThisTeam ? .systemBlue : .clear
                btn.setTitleColor(onThisTeam ? .white : .systemBlue, for: .normal)
                btn.layer.borderColor = UIColor.systemBlue.cgColor
            }
        }
    }

    @objc private func teamATapped() { toggle("A") }
    @objc private func teamBTapped() { toggle("B") }

    private func toggle(_ team: String) {
        let onThisTeam = currentTeams.contains(team)
        let count = team == "A" ? teamACnt : teamBCnt
        let full  = count >= 2 && !onThisTeam

        if full {
            // Hand off to VC to show the swap action sheet.
            onFullTeamTap?(team)
            return
        }

        if onThisTeam {
            guard currentTeams.count > 1 else { return }  // must keep at least one
            currentTeams.remove(team)
        } else {
            if allowDual {
                currentTeams.insert(team)
            } else {
                currentTeams = [team]  // radio: replace
            }
        }
        updateButtonUI()
        onTeamsChange?(Array(currentTeams).sorted())
    }
}

// MARK: - StartingHoleCell

final class StartingHoleCell: UITableViewCell {

    private let holeLabel = UILabel()
    private let stepper   = UIStepper()
    var onHoleChange: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        holeLabel.font = .preferredFont(forTextStyle: .body)
        holeLabel.adjustsFontForContentSizeCategory = true
        holeLabel.translatesAutoresizingMaskIntoConstraints = false

        stepper.minimumValue = 1
        stepper.maximumValue = 18
        stepper.stepValue    = 1
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        stepper.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(holeLabel)
        contentView.addSubview(stepper)
        NSLayoutConstraint.activate([
            holeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            holeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stepper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stepper.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(hole: Int, onChange: @escaping (Int) -> Void) {
        holeLabel.text = "Hole \(hole)"
        stepper.value  = Double(hole)
        onHoleChange   = onChange
    }

    @objc private func stepperChanged() {
        let h = Int(stepper.value)
        holeLabel.text = "Hole \(h)"
        onHoleChange?(h)
    }
}
