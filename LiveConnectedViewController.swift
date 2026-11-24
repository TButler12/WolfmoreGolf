import UIKit

final class LiveConnectedViewController: UITableViewController {

    private let watchedSessionsKey = "watchedWolfSessions"
    private let wolfGreen = UIColor(red: 0.10, green: 0.33, blue: 0.18, alpha: 1.0)

    private struct Row {
        let title: String
        let subtitle: String
        let icon: String        // SF Symbol name
        let tint: UIColor       // icon tint color
        let action: () -> Void
        var removeAction: (() -> Void)? = nil        // non-nil enables swipe-to-Remove
        var creatorDeleteAction: (() -> Void)? = nil // non-nil → board creator; swipe shows choice sheet
    }

    private struct CardItem {
        let title: String
        let subtitle: String
        let icon: String
        let tint: UIColor
        let action: () -> Void
    }

    private struct Section {
        let header: String
        let rows: [Row]
        let cards: [CardItem]
        var isCardGrid: Bool { !cards.isEmpty }

        init(header: String, rows: [Row]) {
            self.header = header; self.rows = rows; self.cards = []
        }
        init(header: String, cards: [CardItem]) {
            self.header = header; self.rows = []; self.cards = cards
        }
    }

    // MARK: - Card Grid Cell

    private final class CardGridCell: UITableViewCell {
        static let reuseID = "CardGrid"

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            backgroundColor = .systemGroupedBackground
        }
        required init?(coder: NSCoder) { fatalError() }

        func configure(cards: [CardItem], isAccessibility: Bool) {
            contentView.subviews.forEach { $0.removeFromSuperview() }
            let columns = isAccessibility ? 1 : 2
            let grid = buildGrid(cards: cards, columns: columns)
            grid.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(grid)
            NSLayoutConstraint.activate([
                grid.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
                grid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                grid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                grid.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            ])
        }

        private func buildGrid(cards: [CardItem], columns: Int) -> UIStackView {
            var rows: [UIStackView] = []
            var i = 0
            while i < cards.count {
                let slice = Array(cards[i..<min(i + columns, cards.count)])
                var subviews = slice.map { buildCard($0) }
                if columns == 2 && slice.count == 1 { subviews.append(UIView()) }
                let rowStack = UIStackView(arrangedSubviews: subviews)
                rowStack.axis = .horizontal; rowStack.spacing = 12; rowStack.distribution = .fillEqually
                rows.append(rowStack)
                i += columns
            }
            let vStack = UIStackView(arrangedSubviews: rows)
            vStack.axis = .vertical; vStack.spacing = 12
            return vStack
        }

        private func buildCard(_ item: CardItem) -> UIView {
            let card = UIView()
            card.backgroundColor = .secondarySystemBackground
            card.layer.cornerRadius = 14
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.07
            card.layer.shadowRadius = 4
            card.layer.shadowOffset = CGSize(width: 0, height: 2)

            let iconBg = UIView()
            iconBg.backgroundColor = item.tint.withAlphaComponent(0.15)
            iconBg.layer.cornerRadius = 24
            iconBg.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iconBg.widthAnchor.constraint(equalToConstant: 48),
                iconBg.heightAnchor.constraint(equalToConstant: 48),
            ])

            let iconView = UIImageView(image: UIImage(systemName: item.icon,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)))
            iconView.tintColor = item.tint
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconBg.addSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            ])

            let nameLabel = UILabel()
            nameLabel.text = item.title
            nameLabel.font = UIFontMetrics(forTextStyle: .caption1)
                .scaledFont(for: UIFont.systemFont(ofSize: 13, weight: .semibold))
            nameLabel.adjustsFontForContentSizeCategory = true
            nameLabel.textAlignment = .center
            nameLabel.numberOfLines = 2
            nameLabel.textColor = .label

            let subtitleLabel = UILabel()
            subtitleLabel.text = item.subtitle
            subtitleLabel.font = UIFontMetrics(forTextStyle: .caption2)
                .scaledFont(for: UIFont.systemFont(ofSize: 11))
            subtitleLabel.adjustsFontForContentSizeCategory = true
            subtitleLabel.textAlignment = .center
            subtitleLabel.numberOfLines = 2
            subtitleLabel.textColor = .secondaryLabel

            let vStack = UIStackView(arrangedSubviews: [iconBg, nameLabel, subtitleLabel])
            vStack.axis = .vertical; vStack.spacing = 6; vStack.alignment = .center
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            ])

            let tapBtn = UIButton()
            tapBtn.translatesAutoresizingMaskIntoConstraints = false
            tapBtn.addAction(UIAction { [weak card] _ in
                UIView.animate(withDuration: 0.08, delay: 0, options: .allowUserInteraction) { card?.alpha = 0.6 }
                UIView.animate(withDuration: 0.12, delay: 0.08, options: .allowUserInteraction) { card?.alpha = 1.0 }
                item.action()
            }, for: .touchUpInside)
            card.addSubview(tapBtn)
            NSLayoutConstraint.activate([
                tapBtn.topAnchor.constraint(equalTo: card.topAnchor),
                tapBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                tapBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                tapBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            ])

            return card
        }
    }

    private var sections: [Section] = []
    private var showAllBoards = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live & Tournaments"
        navigationItem.backButtonTitle = "Back"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(CardGridCell.self, forCellReuseIdentifier: CardGridCell.reuseID)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }

    // Tracks which tournament codes have a new day available (populated async)
    private var newDayAvailable: Set<String> = []
    private var organizerRosterCount: Int? = nil

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        newDayAvailable = []
        buildSections()
        tableView.reloadData()
        checkRecentTournamentsForNewDay()
        syncTournamentSettingsIfScorer()
        fetchOrganizerRosterCount()
    }

    private func fetchOrganizerRosterCount() {
        guard let code = GameManager.shared.currentGame?.tournamentCode,
              GameManager.shared.currentGame?.tournamentIsOrganizer == true else {
            organizerRosterCount = nil
            return
        }
        Task {
            let entries = try? await SupabaseService.shared.fetchRoster(code: code)
            await MainActor.run {
                self.organizerRosterCount = entries?.count
                self.buildSections()
                self.tableView.reloadData()
            }
        }
    }

    // Re-fetch the organizer's latest wolf/press/hammer settings for scorer devices so
    // setting changes made after the scorer joined are picked up automatically.
    private func syncTournamentSettingsIfScorer() {
        guard let code = GameManager.shared.currentGame?.tournamentCode,
              GameManager.shared.currentGame?.tournamentIsOrganizer == false else { return }
        Task {
            guard let record = try? await SupabaseService.shared.fetchTournament(code: code),
                  record.gameType == "wolf" else { return }
            await MainActor.run {
                GameManager.shared.update { g in
                    switch record.wolfVariant {
                    case "2pt":       g.gameType = .wolf
                    case "lowball":   g.gameType = .wolfLowBall
                    case "matchplay": g.gameType = .matchPlay
                    default:          g.gameType = .sixPointScotch
                    }
                    if let ps = record.pressStyle  { g.pressStyle  = ps == "additive" ? .additive : .doubling }
                    if let hs = record.hammerStyle { g.hammerStyle = hs == "additive" ? .additive : .doubling }
                    if let ws = record.wolfStake {
                        g.wolfStake = ws
                        g.gameHoleDollarsArray = Array(repeating: ws, count: STANDARD_HOLES)
                    }
                }
            }
        }
    }

    private func checkRecentTournamentsForNewDay() {
        let history = TournamentHistoryStore.shared.all()
        guard !history.isEmpty else { return }
        Task {
            var found: Set<String> = []
            for entry in history.prefix(5) {
                let savedDay = UserDefaults.standard.integer(forKey: "lastTournamentDay_\(entry.code)")
                let liveDay  = (try? await SupabaseService.shared.fetchTournament(code: entry.code))?.currentDay ?? 0
                if liveDay > max(savedDay, entry.lastDay) { found.insert(entry.code) }
            }
            guard !found.isEmpty else { return }
            await MainActor.run {
                self.newDayAvailable = found
                self.buildSections()
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Build

    private func buildSections() {
        var result: [Section] = []

        let wolfGold  = UIColor(red: 0.75, green: 0.55, blue: 0.05, alpha: 1.0)
        let eventTeal = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)

        let organizerEntries = ClubEventOrganizerStore.shared.all
        let activeSession    = ClubEventSessionStore.shared.current
        if !organizerEntries.isEmpty || activeSession != nil {
            var rows: [Row] = []
            if let s = activeSession {
                rows.append(Row(
                    title: "Resume Scoring: \(s.eventName)",
                    subtitle: "Group \(s.groupCode)",
                    icon: "play.circle.fill",
                    tint: UIColor(red: 0.18, green: 0.55, blue: 0.34, alpha: 1.0),
                    action: { [weak self] in self?.resumeClubEventScoring() },
                    removeAction: { [weak self] in
                        ClubEventSessionStore.shared.clear()
                        self?.buildSections()
                        self?.tableView.reloadData()
                    }
                ))
            }
            for entry in organizerEntries {
                let courseLabel = entry.courseName ?? "Event"
                rows.append(Row(
                    title: "My Event: \(entry.name)",
                    subtitle: "\(courseLabel) · \(entry.code)",
                    icon: "person.3.sequence.fill",
                    tint: eventTeal,
                    action: { [weak self] in self?.openOrganizerHome(entry: entry) },
                    removeAction: { [weak self] in
                        ClubEventOrganizerStore.shared.remove(id: entry.id)
                        self?.buildSections()
                        self?.tableView.reloadData()
                    }
                ))
                rows.append(Row(
                    title: "Leaderboard",
                    subtitle: entry.name,
                    icon: "list.number",
                    tint: eventTeal,
                    action: { [weak self] in self?.openClubEventLeaderboard(entry: entry) }
                ))
            }
            if !rows.isEmpty {
                result.append(Section(header: "CLUB EVENTS", rows: rows))
            }
        }

        result.append(Section(header: "CREATE", cards: [
            CardItem(title: "Club Event",
                     subtitle: "Best ball + skins",
                     icon: "person.3.fill",
                     tint: eventTeal) { [weak self] in
                self?.createClubEventTapped()
            },
            CardItem(title: "Tournament",
                     subtitle: "Create a multi-day event",
                     icon: "trophy.fill",
                     tint: wolfGreen) { [weak self] in
                self?.createTournamentTapped()
            },
            CardItem(title: "Event Board",
                     subtitle: "Live leaderboard, share a code",
                     icon: "rectangle.3.group.fill",
                     tint: wolfGold) { [weak self] in
                guard let self else { return }
                WolfActions.createMatchBoardAction(from: self)
            },
            CardItem(title: "Calcutta",
                     subtitle: "Auction pools & payouts",
                     icon: "dollarsign.circle.fill",
                     tint: wolfGold) { [weak self] in
                self?.openCalcutta()
            },
            CardItem(title: "Remote Nassau",
                     subtitle: "Match vs. a remote player",
                     icon: "flag.2.crossed.fill",
                     tint: wolfGreen) { [weak self] in
                guard let self else { return }
                guard GameManager.shared.currentGame != nil else {
                    self.showError("Start a game first before creating a Nassau match.")
                    return
                }
                WolfActions.startLiveMatch(from: self)
            },
            CardItem(title: "Live Wolf",
                     subtitle: "Broadcast your scores",
                     icon: "antenna.radiowaves.left.and.right",
                     tint: wolfGreen) { [weak self] in
                guard let self else { return }
                guard GameManager.shared.currentGame != nil else {
                    self.showError("Start a game first before going Live Wolf.")
                    return
                }
                WolfActions.presentGoLive(from: self)
            },
            CardItem(title: "Co-Organizer Code",
                     subtitle: "Claim organizer access",
                     icon: "key.fill",
                     tint: wolfGold) { [weak self] in
                self?.enterCoOrgCodeTapped()
            },
        ]))

        result.append(Section(header: "JOIN", rows: [
            Row(title: "Join Club Event",
                subtitle: "Enter a code, pick your group",
                icon: "person.3.fill",
                tint: eventTeal) { [weak self] in
                self?.joinClubEventTapped()
            },
            Row(title: "Join Tournament",
                subtitle: "Enter a code",
                icon: "trophy.fill",
                tint: wolfGreen) { [weak self] in
                self?.joinTournamentTapped()
            },
            Row(title: "Join Remote Nassau Match",
                subtitle: "Accept a live invite",
                icon: "flag.2.crossed.fill",
                tint: wolfGreen) { [weak self] in
                guard let self else { return }
                WolfActions.joinLiveMatch(from: self)
            },
            Row(title: "Watch a Group or Event Board",
                subtitle: "Watch live scores",
                icon: "eye.fill",
                tint: .secondaryLabel) { [weak self] in
                self?.watchLiveTapped()
            },
        ]))

        let isOrganizer = GameManager.shared.currentGame?.tournamentIsOrganizer == true
            && GameManager.shared.currentGame?.tournamentCode != nil
        if isOrganizer {
            let day = GameManager.shared.currentGame?.tournamentDay ?? 1
            let rosterEmpty = organizerRosterCount == 0
            let rosterSubtitle: String
            if let count = organizerRosterCount, count > 0 {
                rosterSubtitle = "Day \(day) · \(count) player\(count == 1 ? "" : "s")"
            } else if rosterEmpty {
                rosterSubtitle = "No players yet · Add Roster"
            } else {
                rosterSubtitle = "Currently Day \(day)"
            }
            result.append(Section(header: "MANAGE", rows: [
                Row(title: "Manage Tournament",
                    subtitle: rosterSubtitle,
                    icon: "chart.bar.fill",
                    tint: rosterEmpty ? .systemOrange : wolfGreen) { [weak self] in
                    if rosterEmpty {
                        self?.showRosterSheet()
                    } else {
                        self?.manageTournamentTapped()
                    }
                },
            ]))
        }

        let history = TournamentHistoryStore.shared.all()
            .sorted { $0.lastJoined > $1.lastJoined }
        if !history.isEmpty {
            let rows: [Row] = history.prefix(5).map { entry in
                let gameLabel: String
                switch entry.gameType {
                case "skins": gameLabel = "Skins"
                case "wolf":  gameLabel = "Wolf"
                default:      gameLabel = entry.gameType.capitalized
                }
                let hasNewDay = self.newDayAvailable.contains(entry.code)
                let subtitle = hasNewDay
                    ? "⚑ New day ready — tap to start"
                    : "Day \(entry.lastDay) · \(gameLabel) · \(entry.code)"
                var row = Row(
                    title: entry.name,
                    subtitle: subtitle,
                    icon: "clock.fill",
                    tint: .secondaryLabel
                ) { [weak self] in
                    self?.historyEntryTapped(entry)
                }
                row.removeAction = { [weak self] in
                    TournamentHistoryStore.shared.remove(code: entry.code)
                    self?.buildSections()
                    self?.tableView.reloadData()
                }
                return row
            }
            result.append(Section(header: "RECENT TOURNAMENTS", rows: rows))
        }

        let allBoards = MatchBoardStore.all()
        if !allBoards.isEmpty {
            let cutoff    = Date().addingTimeInterval(-30 * 86_400).timeIntervalSince1970
            let recent    = allBoards.filter { $0.createdAt >= cutoff }
            let older     = allBoards.filter { $0.createdAt <  cutoff }
            let visible   = showAllBoards ? allBoards : recent

            let boardIcon = UIColor(red: 0.20, green: 0.47, blue: 0.78, alpha: 1.0)
            var boardRows: [Row] = visible.map { board in
                let dateStr = DateFormatter.localizedString(
                    from: Date(timeIntervalSince1970: board.createdAt),
                    dateStyle: .short, timeStyle: .none)
                return Row(
                    title: board.name,
                    subtitle: "\(board.code) · \(dateStr)",
                    icon: "rectangle.3.group.fill",
                    tint: boardIcon,
                    action: { [weak self] in
                        guard let self else { return }
                        WolfActions.showEventBoard(code: board.code,
                                                   organizerToken: board.organizerToken,
                                                   from: self)
                    },
                    removeAction: { [weak self] in
                        MatchBoardStore.remove(code: board.code)
                        self?.buildSections()
                        self?.tableView.reloadData()
                    },
                    creatorDeleteAction: board.organizerToken.map { token in
                        { [weak self] in
                            self?.confirmAndDeleteBoard(code: board.code, name: board.name, token: token)
                        }
                    }
                )
            }

            if !showAllBoards && !older.isEmpty {
                boardRows.append(Row(
                    title: "Show older (\(older.count) more)",
                    subtitle: "",
                    icon: "clock.arrow.circlepath",
                    tint: .secondaryLabel,
                    action: { [weak self] in
                        self?.showAllBoards = true
                        self?.buildSections()
                        self?.tableView.reloadData()
                    }
                ))
            }

            if !boardRows.isEmpty {
                result.append(Section(header: "MY EVENT BOARDS", rows: boardRows))
            }
        }

        sections = result
    }

    // MARK: - UITableViewDataSource / Delegate

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].isCardGrid ? 1 : sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        if section.isCardGrid {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CardGridCell.reuseID, for: indexPath) as! CardGridCell
            cell.configure(cards: section.cards,
                           isAccessibility: traitCollection.preferredContentSizeCategory.isAccessibilityCategory)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let row = section.rows[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = row.title
        content.secondaryText = row.subtitle
        content.image = UIImage(systemName: row.icon)
        content.imageProperties.tintColor = row.tint
        content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = sections[indexPath.section]
        guard !section.isCardGrid else { return }
        section.rows[indexPath.row].action()
    }

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let section = sections[indexPath.section]
        guard !section.isCardGrid else { return nil }
        let row = section.rows[indexPath.row]
        guard row.removeAction != nil else { return nil }
        let action = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            done(true)
            if row.creatorDeleteAction != nil {
                self?.presentRemoveSheet(for: row)
            } else {
                row.removeAction?()
            }
        }
        return UISwipeActionsConfiguration(actions: [action])
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        let section = sections[indexPath.section]
        guard !section.isCardGrid else { return }
        let row = section.rows[indexPath.row]
        guard row.removeAction != nil else { return }
        presentRemoveSheet(for: row)
    }

    private func presentRemoveSheet(for row: Row) {
        let ac = UIAlertController(
            title: row.title,
            message: row.creatorDeleteAction != nil
                ? "You created this board. Removing it from your list will delete your organizer access on this device."
                : nil,
            preferredStyle: .actionSheet
        )
        ac.addAction(UIAlertAction(title: "Remove from My List", style: .destructive) { _ in
            row.removeAction?()
        })
        if row.creatorDeleteAction != nil {
            ac.addAction(UIAlertAction(title: "Delete for Everyone", style: .destructive) { _ in
                row.creatorDeleteAction?()
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(ac)
    }

    private func confirmAndDeleteBoard(code: String, name: String, token: String) {
        let ac = UIAlertController(
            title: "Delete \"\(name)\" for Everyone?",
            message: "Scores will be lost.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.executeDeleteBoard(code: code, token: token)
        })
        present(ac, animated: true)
    }

    private func executeDeleteBoard(code: String, token: String) {
        Task {
            do {
                try await SupabaseService.shared.deleteLiveEvent(code: code, organizerToken: token)
                MatchBoardStore.remove(code: code)
                await MainActor.run {
                    self.buildSections()
                    self.tableView.reloadData()
                }
            } catch {
                let msg = error.localizedDescription
                let friendly = msg.localizedCaseInsensitiveContains("could not find")
                    || msg.localizedCaseInsensitiveContains("does not exist")
                    ? "Board deletion isn't available right now. Please try again later."
                    : msg
                await MainActor.run { self.showError(friendly) }
            }
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Join Tournament

    private func joinTournamentTapped() {
        let ac = UIAlertController(
            title: "Join Tournament",
            message: "Enter the 6-letter code from the tournament organizer.",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "XXXXXX"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.returnKeyType = .join
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Join", style: .default) { [weak self, weak ac] _ in
            let raw = (ac?.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard raw.count == 6 else {
                self?.showError("Please enter a 6-letter code.")
                return
            }
            self?.joinTournament(code: raw)
        })
        present(ac, animated: true)
    }

    private func joinTournament(code: String) {
        let spinner = UIAlertController(title: nil, message: "Looking up tournament…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let record = try await SupabaseService.shared.fetchTournament(code: code)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showJoinConfirmation(record: record)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Tournament not found. Check the code and try again.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func showJoinConfirmation(record: TournamentRecord) {
        let scoringLabel = record.scoring == "net" ? "Net" : "Gross"
        let gameDesc: String
        switch record.gameType {
        case "wolf":
            gameDesc = "Wolf · \(scoringLabel)"
        case "skins":
            let carry = record.carryTies == true ? "carry ties" : "no carry"
            let stakeStr = record.stake.map { "$\(Int($0))/hole" } ?? ""
            gameDesc = "Skins · \(scoringLabel) · \(carry)\(stakeStr.isEmpty ? "" : " · \(stakeStr)")"
        case "scramble":
            gameDesc = "Scramble"
        default:
            gameDesc = "Stableford · \(scoringLabel)"
        }
        let msg = "\"\(record.name)\"\n\(gameDesc)"
        let ac = UIAlertController(title: "Join This Tournament?", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Watch as Spectator", style: .default) { [weak self] _ in
            guard let self else { return }
            let vc = TournamentLeaderboardViewController(code: record.code)
            self.navigationController?.pushViewController(vc, animated: true)
        })
        ac.addAction(UIAlertAction(title: "Join as Scorer", style: .default) { [weak self] _ in
            self?.applyJoinedTournament(record: record)
        })
        present(ac, animated: true)
    }

    private func applyJoinedTournament(record: TournamentRecord) {
        performJoinedTournament(record: record)
    }

    private func performJoinedTournament(record: TournamentRecord) {
        if let conflict = GameManager.checkTournamentAttachConflict(record: record) {
            let ac = UIAlertController(
                title: "Different Tournament",
                message: "Your round at \(conflict.currentCourseName) doesn't match this tournament (\(conflict.description)). Start a new round? Your current round will be saved to Restore.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Start New Round", style: .default) { [weak self] _ in
                guard let self else { return }
                ResetSnapshotStore.shared.saveFromCurrentGame()
                GameManager.shared.startNewGame()
                self.doJoinTournament(record: record)
            })
            present(ac, animated: true)
            return
        }
        doJoinTournament(record: record)
    }

    private func doJoinTournament(record: TournamentRecord) {
        GameManager.applyTournamentJoin(record: record)

        let presenter = self.navigationController?.presentingViewController ?? presentingViewController
        let sb = UIStoryboard(name: "Main", bundle: nil)

        if record.gameType == "scramble" {
            // Scramble: skip roster picker — show team entry form, then go straight to scoring.
            let tCode = record.code
            dismiss(animated: true) {
                guard let presenter else { return }
                let entryVC = ScrambleTeamEntryViewController()
                entryVC.allowSkip = false
                entryVC.submit = { vc, teamName, playerNames, startingHole in
                    let spinner = UIAlertController(title: nil, message: "Setting up team…", preferredStyle: .alert)
                    vc.present(spinner, animated: true)
                    Task {
                        do {
                            _ = try await SupabaseService.shared.findOrCreateScrambleTeam(
                                tournamentCode: tCode, teamName: teamName, playerNames: playerNames)
                            await MainActor.run {
                                let holeIndex = max(0, min(17, startingHole - 1))
                                GameManager.shared.update { g in
                                    g.scrambleTeamName   = teamName
                                    g.playerNames[0]     = teamName
                                    for i in g.playerActivated.indices { g.playerActivated[i] = false }
                                    g.playerActivated[0] = true
                                    // Wipe previous round's scores so the new game starts clean.
                                    g.scores = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: WOLF_MAX_PLAYERS)
                                    g.hole      = holeIndex
                                    g.startHole = holeIndex
                                }
                                GameManager.shared.seedScoresWithParsForActivePlayers()
                                GameManager.shared.saveCurrent()
                                let game = sb.instantiateViewController(withIdentifier: "GameViewController")
                                let hostNav = (presenter as? UINavigationController) ?? presenter.navigationController
                                spinner.dismiss(animated: false) {
                                    vc.navigationController?.dismiss(animated: true) {
                                        hostNav?.pushViewController(game, animated: true)
                                    }
                                }
                            }
                        } catch {
                            await MainActor.run {
                                spinner.dismiss(animated: false) {
                                    let err = UIAlertController(title: "Error",
                                        message: "Couldn't register team. Try again.\n\n\(error.localizedDescription)",
                                        preferredStyle: .alert)
                                    err.addAction(UIAlertAction(title: "OK", style: .default))
                                    vc.present(err, animated: true)
                                }
                            }
                        }
                    }
                }
                let nav = UINavigationController(rootViewController: entryVC)
                nav.modalPresentationStyle = .formSheet
                presenter.present(nav, animated: true)
            }
            return
        }

        // Non-scramble: surface ManagePlayersVC with the roster picker already opening.
        let day = record.currentDay ?? 1
        let successMsg = "Joined: \(record.name) · Day \(day)"
        dismiss(animated: true) {
            guard let presenter,
                  let manageVC = sb.instantiateViewController(withIdentifier: "ManagePlayersVC")
                      as? ManagePlayersViewController else { return }
            manageVC.joinSuccessMessage = successMsg
            let nav = UINavigationController(rootViewController: manageVC)
            nav.modalPresentationStyle = .pageSheet
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            presenter.present(nav, animated: true)
        }
    }

    // MARK: - Club Events

    private func createClubEventTapped() {
        let vc = ClubEventCreationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openClubEventLeaderboard(entry: ClubEventOrganizerEntry) {
        let pars: [Int]
        let hcs:  [Int]
        if let name = entry.courseName,
           let course = CourseLibrary.shared.courses.first(where: {
               $0.name.caseInsensitiveCompare(name) == .orderedSame
           }),
           course.pars.count == 18, course.hcs.count == 18 {
            pars = course.pars
            hcs  = course.hcs
        } else {
            pars = Array(repeating: 4, count: 18)
            hcs  = Array(1...18)
        }
        let vc = ClubEventLeaderboardViewController(
            tournamentId: entry.id,
            eventName:    entry.name,
            coursePars:   pars,
            courseHCs:    hcs,
            myGroupCode:  ""
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openOrganizerHome(entry: ClubEventOrganizerEntry) {
        let spinner = UIAlertController(title: nil, message: "Loading…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let event = try await SupabaseService.shared.fetchClubEvent(code: entry.code)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let vc = ClubEventOrganizerHomeViewController(event: event)
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Could Not Open Event",
                            message: error.localizedDescription,
                            preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "Remove from My List", style: .destructive) { _ in
                            ClubEventOrganizerStore.shared.remove(id: entry.id)
                            self.buildSections()
                            self.tableView.reloadData()
                        })
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }

    private func resumeClubEventScoring() {
        guard let session = ClubEventSessionStore.shared.current else { return }
        let spinner = UIAlertController(title: nil, message: "Resuming…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            let groupScores = (try? await SupabaseService.shared.fetchClubEventGroupScores(
                tournamentId: session.eventId, playerIds: session.playerIds)) ?? []
            let roster = (try? await SupabaseService.shared.fetchClubEventRoster(
                tournamentId: session.eventId)) ?? []
            let teams = (try? await SupabaseService.shared.fetchClubEventTeams(
                tournamentId: session.eventId)) ?? []
            let memberships = (try? await SupabaseService.shared.fetchClubEventTeamMemberships(
                teamIds: teams.map { $0.id })) ?? []

            var playerTeams: [UUID: [String]] = [:]
            for m in memberships {
                guard let team = teams.first(where: { $0.id == m.teamId }) else { continue }
                let suffix = team.teamName.hasSuffix("-A") ? "A"
                           : team.teamName.hasSuffix("-B") ? "B"
                           : nil
                guard let suffix else { continue }
                playerTeams[m.tournamentPlayerId, default: []].append(suffix)
            }
            let groupPlayers: [ClubEventGroupPlayer] = session.playerIds.compactMap { pid in
                guard let p = roster.first(where: { $0.id == pid }) else { return nil }
                return ClubEventGroupPlayer(
                    id: p.id, name: p.playerName, handicap: p.handicap,
                    teams: playerTeams[p.id] ?? ["A"])
            }
            let startHole = Self.findNextUnscoredHole(scores: groupScores,
                                                     startingHole: session.startingHole)

            await MainActor.run {
                spinner.dismiss(animated: false) {
                    guard !groupPlayers.isEmpty else {
                        ClubEventSessionStore.shared.clear()
                        self.buildSections()
                        self.tableView.reloadData()
                        return
                    }
                    let vc = ClubEventScoringViewController(
                        tournamentId: session.eventId,
                        groupCode:    session.groupCode,
                        startingHole: startHole,
                        eventName:    session.eventName,
                        courseName:   session.courseName,
                        players:      groupPlayers
                    )
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }

    static func findNextUnscoredHole(scores: [ClubEventHoleScore], startingHole: Int) -> Int {
        let scored = Set(scores
            .filter { ($0.grossScore ?? 0) > 0 || $0.netScoreType == "picked_up" }
            .map { $0.holeNumber })
        for offset in 0..<18 {
            let hole = ((startingHole - 1 + offset) % 18) + 1
            if !scored.contains(hole) { return hole }
        }
        return startingHole
    }

    private func joinClubEventTapped() {
        let vc  = ClubEventJoinViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    // MARK: - Create Tournament

    private func createTournamentTapped() {
        let vc = TeeGameSetupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openCalcutta() {
        let vc = CalcuttaListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Manage Tournament

    private func manageTournamentTapped() {
        let sheet = UIAlertController(title: "Manage Tournament", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Roster / Add Players", style: .default) { [weak self] _ in
            self?.showRosterSheet()
        })
        if GameManager.shared.currentGame?.tournamentIsOrganizer == true {
            sheet.addAction(UIAlertAction(title: "Edit Game Settings", style: .default) { [weak self] _ in
                self?.editTournamentSettings()
            })
        }
        if GameManager.shared.currentGame?.tournamentIsCreator == true {
            sheet.addAction(UIAlertAction(title: "Share Organizer Access", style: .default) { [weak self] _ in
                self?.shareOrganizerAccess()
            })
        }
        sheet.addAction(UIAlertAction(title: "View Results", style: .default) { [weak self] _ in
            self?.viewOrganizerResults()
        })
        sheet.addAction(UIAlertAction(title: "AI Summary", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(AISummaryViewController(), animated: true)
        })
        sheet.addAction(UIAlertAction(title: "Advance to Next Day", style: .default) { [weak self] _ in
            self?.advanceDay()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func showRosterSheet() {
        let sheet = UIAlertController(title: "Roster", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Edit Roster", style: .default) { [weak self] _ in
            self?.editRosterTapped()
        })
        sheet.addAction(UIAlertAction(title: "Permanent Roster", style: .default) { [weak self] _ in
            self?.openPermanentRoster()
        })
        if GameManager.shared.currentGame?.tournamentIsOrganizer == true {
            let currentCode = GameManager.shared.currentGame?.tournamentCode ?? ""
            let past = TournamentHistoryStore.shared.all().filter { $0.code != currentCode }
            if !past.isEmpty {
                sheet.addAction(UIAlertAction(title: "Load Roster from Past Tournament", style: .default) { [weak self] _ in
                    self?.showPastRosterImportSheet(past, into: currentCode)
                })
            }
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func showPastRosterImportSheet(_ entries: [TournamentHistoryEntry], into currentCode: String) {
        let ac = UIAlertController(
            title: "Load Roster from Past Tournament",
            message: "All players from that tournament will be added to this roster.",
            preferredStyle: .actionSheet)
        for entry in entries {
            ac.addAction(UIAlertAction(title: "\(entry.name)  ·  Day \(entry.lastDay)", style: .default) { [weak self] _ in
                self?.importRosterFromPastTournament(code: entry.code, name: entry.name, into: currentCode)
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(ac)
    }

    private func importRosterFromPastTournament(code: String, name: String, into currentCode: String) {
        let spinner = UIAlertController(title: nil, message: "Importing players from \(name)…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let entries = try await SupabaseService.shared.fetchRoster(code: code)
                for entry in entries {
                    // Preserve existing FriendStore HC — only set preselectForRound.
                    if let existing = FriendStore.shared.friends.first(where: {
                        $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            .caseInsensitiveCompare(entry.canonicalName) == .orderedSame
                    }) {
                        FriendStore.shared.update(friendID: existing.id, preselectForRound: true)
                    } else {
                        let friend = Friend(name: entry.canonicalName, defaultHC: entry.handicap)
                        FriendStore.shared.upsert(friend)
                        if let saved = FriendStore.shared.friends.first(where: {
                            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                                .caseInsensitiveCompare(entry.canonicalName) == .orderedSame
                        }) {
                            FriendStore.shared.update(friendID: saved.id, preselectForRound: true)
                        }
                    }
                    let rosterEntry = TournamentRosterEntry(
                        id: UUID(),
                        tournamentCode: currentCode,
                        canonicalName: entry.canonicalName,
                        handicap: entry.handicap,
                        addedBy: "organizer",
                        groupCode: nil)
                    try? await SupabaseService.shared.upsertRosterEntry(rosterEntry)
                }
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Roster Loaded",
                            message: "\(entries.count) player\(entries.count == 1 ? "" : "s") imported from \(name).",
                            preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Could not load players from that tournament.")
                    }
                }
            }
        }
    }

    private func editRosterTapped() {
        guard let code = GameManager.shared.currentGame?.tournamentCode,
              let name = GameManager.shared.currentGame?.tournamentName else { return }
        let vc = TournamentRosterViewController(code: code, name: name)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openPermanentRoster() {
        let vc = PermanentRosterViewController()
        vc.tournamentCode = GameManager.shared.currentGame?.tournamentCode
        navigationController?.pushViewController(vc, animated: true)
    }

    private func editTournamentSettings() {
        let vc = TournamentSettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func viewOrganizerResults() {
        guard let code = GameManager.shared.currentGame?.tournamentCode else {
            showError("No active tournament found.")
            return
        }
        let vc = TournamentLeaderboardViewController(code: code, isOrganizerView: true)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func advanceDay() {
        guard let code = GameManager.shared.currentGame?.tournamentCode else { return }
        let confirm = UIAlertController(
            title: "Advance to Next Day?",
            message: "This will clear all roster claims so scorers can re-pick players for the new day.",
            preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirm.addAction(UIAlertAction(title: "Advance", style: .destructive) { [weak self] _ in
            guard let self else { return }
            let spinner = UIAlertController(title: nil, message: "Advancing day…", preferredStyle: .alert)
            self.present(spinner, animated: true)
            Task {
                do {
                    try await SupabaseService.shared.advanceTournamentDay(code: code)
                    let record = try await SupabaseService.shared.fetchTournament(code: code)
                    let newDay = record.currentDay ?? 1
                    GameManager.shared.update { g in g.tournamentDay = newDay }
                    UserDefaults.standard.set(newDay, forKey: "lastTournamentDay_\(code)")
                    await MainActor.run {
                        spinner.dismiss(animated: false) {
                            self.buildSections()
                            self.tableView.reloadData()
                            let ac = UIAlertController(title: "Advanced to Day \(newDay)",
                                                       message: nil, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(ac, animated: true)
                        }
                    }
                } catch {
                    await MainActor.run {
                        spinner.dismiss(animated: false) {
                            self.showError("Failed to advance day: \(error.localizedDescription)")
                        }
                    }
                }
            }
        })
        present(confirm, animated: true)
    }

    // MARK: - Watch Live

    private func watchLiveTapped() {
        let saved = UserDefaults.standard.stringArray(forKey: watchedSessionsKey) ?? []
        guard !saved.isEmpty else {
            showWatchLiveAlert()
            return
        }
        Task {
            var activeCodes: [String] = []
            await withTaskGroup(of: (String, Bool).self) { group in
                for code in saved {
                    group.addTask {
                        let session = try? await SupabaseService.shared.fetchWolfSessionByCode(code: code)
                        return (code, session?.status == "active")
                    }
                }
                for await (code, isActive) in group {
                    if isActive { activeCodes.append(code) }
                }
            }
            await MainActor.run {
                if !activeCodes.isEmpty {
                    let vc = WolfSpectatorViewController()
                    vc.sessionCode = ""
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    UserDefaults.standard.removeObject(forKey: self.watchedSessionsKey)
                    self.showWatchLiveAlert()
                }
            }
        }
    }

    private func showWatchLiveAlert() {
        WolfActions.presentWatchLive(from: self)
    }

    // MARK: - Co-Organizer

    private func enterCoOrgCodeTapped() {
        let alert = UIAlertController(
            title: "Co-Organizer Code",
            message: "Enter the code shared by the tournament creator.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "ORG-XXXX"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.returnKeyType = .go
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Claim Access", style: .default) { [weak self, weak alert] _ in
            let raw = (alert?.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard raw.hasPrefix("ORG-") && raw.count == 8 else {
                self?.showError("Enter a valid co-organizer code (e.g. ORG-ABCD).")
                return
            }
            self?.claimCoOrgAccess(code: raw)
        })
        present(alert, animated: true)
    }

    private func claimCoOrgAccess(code: String) {
        let spinner = UIAlertController(title: nil, message: "Verifying code…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let record = try await SupabaseService.shared.claimCoOrganizerAccess(coOrgCode: code)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let current = GameManager.shared.currentGame
                        if current?.tournamentCode == record.code {
                            // Already in this tournament — just elevate access.
                            GameManager.shared.update { g in
                                g.tournamentIsOrganizer = true
                            }
                            GameManager.shared.saveCurrent()
                            NotificationCenter.default.post(name: .reloadUI, object: nil)
                            self.buildSections()
                            self.tableView.reloadData()
                            let ac = UIAlertController(
                                title: "Co-Organizer Access Granted",
                                message: "You now have organizer access to \(record.name).",
                                preferredStyle: .alert
                            )
                            ac.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(ac, animated: true)
                        } else {
                            // Not yet in this tournament — apply full join + organizer.
                            self.applyCoOrgJoin(record: record)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Code not found. Check it and try again.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func applyCoOrgJoin(record: TournamentRecord) {
        GameManager.shared.activeSlot = .tournament
        if !GameManager.shared.loadTournamentSlot(notify: false) {
            _ = GameManager.shared.loadLastOpened(notify: false)
            GameManager.shared.activeSlot = .tournament
        }
        if GameManager.shared.currentGame == nil {
            GameManager.shared.currentGame = GameData()
        }
        let groupCode = UUID().uuidString
        let matchId   = UUID().uuidString
        GameManager.shared.update { g in
            g.tournamentCode        = record.code
            g.groupCode             = groupCode
            g.tournamentMatchId     = matchId
            g.tournamentName        = record.name
            g.tournamentGameType    = record.gameType
            g.tournamentScoringType = record.scoring
            g.tournamentDay         = record.currentDay ?? 1
            g.tournamentIsCreator        = false
            g.tournamentIsOrganizer      = true
            g.tournamentPotAmount        = record.potAmount
            g.tournamentCarryTies        = record.carryTies
            g.stablefordBaseline          = StablefordBaseline(rawValue: record.stablefordBaseline ?? "par") ?? .par
            g.stablefordCountingPlayers   = record.stablefordTeamCount ?? 3
            g.tournamentStablefordEnabled = record.stablefordEnabled
            g.stablefordMode = StablefordMode(rawValue: record.stablefordMode ?? "standard") ?? .standard
            if g.stablefordMode == .modified {
                g.modifiedStablefordTable = ModifiedStablefordTable(
                    doubleEagleOrBetter: record.modifiedSfDoubleEagle  ??  8,
                    eagleOrBetter:       record.modifiedSfEagle        ??  4,
                    birdie:              record.modifiedSfBirdie       ??  2,
                    par:                 record.modifiedSfPar          ??  0,
                    bogey:               record.modifiedSfBogey        ?? -1,
                    doubleBogeyOrWorse:  record.modifiedSfDoubleBogey  ?? -3
                )
            } else {
                g.modifiedStablefordTable = ModifiedStablefordTable()
            }
        }
        let coOrgDay = record.currentDay ?? 1
        UserDefaults.standard.set(coOrgDay, forKey: "lastTournamentDay_\(record.code)")
        GameManager.shared.saveCurrent()
        TournamentHistoryStore.shared.record(
            code: record.code, name: record.name,
            gameType: record.gameType, day: coOrgDay, isOrganizer: true)
        NotificationCenter.default.post(name: .reloadUI, object: nil)
        buildSections()
        tableView.reloadData()
        let ac = UIAlertController(
            title: "Joined as Co-Organizer",
            message: "You've joined \"\(record.name)\" with full organizer access.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func shareOrganizerAccess() {
        guard let tournamentCode = GameManager.shared.currentGame?.tournamentCode,
              GameManager.shared.currentGame?.tournamentIsCreator == true else { return }

        let spinner = UIAlertController(title: nil, message: "Preparing code…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                // Reuse existing co-organizer code if one was already generated; create one otherwise.
                let record = try await SupabaseService.shared.fetchTournament(code: tournamentCode)
                let orgCode: String
                if let existing = record.coOrganizerCode, !existing.isEmpty {
                    orgCode = existing
                } else {
                    orgCode = try await SupabaseService.shared.generateCoOrgCode(tournamentCode: tournamentCode)
                }
                let name = record.name
                let shareText = "Your WolfMore co-organizer code for \(name): \(orgCode)"
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Co-Organizer Code",
                            message: "\(orgCode)",
                            preferredStyle: .alert
                        )
                        ac.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                            UIPasteboard.general.string = orgCode
                        })
                        ac.addAction(UIAlertAction(title: "Share…", style: .default) { [weak self] _ in
                            guard let self else { return }
                            let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                            if let pop = vc.popoverPresentationController {
                                pop.sourceView = self.view
                                pop.sourceRect = CGRect(x: self.view.bounds.midX, y: 100, width: 1, height: 1)
                            }
                            self.present(vc, animated: true)
                        })
                        ac.addAction(UIAlertAction(title: "Done", style: .cancel))
                        self.present(ac, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Could not prepare code: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Tournament History

    private func historyEntryTapped(_ entry: TournamentHistoryEntry) {
        let hasNewDay = newDayAvailable.contains(entry.code)
        let msg = hasNewDay ? "New day available — no code needed" : "Day \(entry.lastDay) · \(entry.code)"
        let sheet = UIAlertController(title: entry.name, message: msg, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "View Leaderboard", style: .default) { [weak self] _ in
            let vc = TournamentLeaderboardViewController(code: entry.code)
            self?.navigationController?.pushViewController(vc, animated: true)
        })
        let rejoinLabel = hasNewDay ? "Start New Day (no code needed)" : "Rejoin Tournament"
        sheet.addAction(UIAlertAction(title: rejoinLabel, style: .default) { [weak self] _ in
            self?.rejoinFromHistory(entry)
        })
        sheet.addAction(UIAlertAction(title: "Remove from History", style: .destructive) { [weak self] _ in
            TournamentHistoryStore.shared.remove(code: entry.code)
            self?.buildSections()
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func rejoinFromHistory(_ entry: TournamentHistoryEntry) {
        let spinner = UIAlertController(title: nil, message: "Rejoining…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let record = try await SupabaseService.shared.fetchTournament(code: entry.code)
                let liveDay = record.currentDay ?? 1
                let savedDay = UserDefaults.standard.integer(forKey: "lastTournamentDay_\(entry.code)")
                let isNewDay = liveDay > savedDay && savedDay > 0
                let isOrg = (record.createdBy == DeviceID.id)
                    || (record.coOrganizerDevices?.contains(DeviceID.id) == true)
                if isNewDay && isOrg {
                    try? await SupabaseService.shared.clearRosterClaims(code: record.code)
                }
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.applyJoinedTournament(record: record)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Tournament not found. It may have ended.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func showError(_ message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
