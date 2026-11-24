import UIKit

/// Entry point for club event scoring: enter the event code, confirm event details,
/// then proceed to group setup.
final class ClubEventJoinViewController: UIViewController {

    // MARK: - UI

    private let scroll      = UIScrollView()
    private let codeField   = UITextField()
    private let findButton  = UIButton(type: .system)
    private let eventCard   = UIView()
    private let eventNameLabel   = UILabel()
    private let eventDetailLabel = UILabel()
    private let setupButton = UIButton(type: .system)
    private let spectatorButton = UIButton(type: .system)
    private let enterGroupButton = UIButton(type: .system)

    private var foundEvent: ClubEventRecord?
    private let prefillCode: String?

    private static let teal = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)

    // MARK: - Init

    init(prefillCode: String? = nil) {
        self.prefillCode = prefillCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Join Club Event"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        buildUI()
        if let code = prefillCode {
            codeField.text = code.uppercased()
            codeChanged()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if prefillCode != nil {
            findTapped()
        } else {
            codeField.becomeFirstResponder()
        }
    }

    // MARK: - Layout

    private func buildUI() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])

        // ── Instruction ────────────────────────────────────────────────────────
        let instrLabel = UILabel()
        instrLabel.text = "Enter the 6-character event code from your tournament organizer."
        instrLabel.font = .preferredFont(forTextStyle: .subheadline)
        instrLabel.adjustsFontForContentSizeCategory = true
        instrLabel.textColor    = .secondaryLabel
        instrLabel.textAlignment = .center
        instrLabel.numberOfLines = 0
        instrLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Code field ─────────────────────────────────────────────────────────
        codeField.placeholder            = "XXXXXX"
        codeField.font                   = UIFont.monospacedSystemFont(ofSize: 32, weight: .bold)
        codeField.textAlignment          = .center
        codeField.autocapitalizationType = .allCharacters
        codeField.autocorrectionType     = .no
        codeField.keyboardType           = .asciiCapable
        codeField.returnKeyType          = .search
        codeField.delegate               = self
        codeField.translatesAutoresizingMaskIntoConstraints = false
        codeField.addTarget(self, action: #selector(codeChanged), for: .editingChanged)

        // ── Find button ────────────────────────────────────────────────────────
        var findCfg = UIButton.Configuration.filled()
        findCfg.baseBackgroundColor = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)
        findCfg.baseForegroundColor = .white
        findCfg.cornerStyle         = .large
        findCfg.contentInsets       = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        findCfg.title               = "Find Event"
        findButton.configuration    = findCfg
        findButton.isEnabled        = false
        findButton.addTarget(self, action: #selector(findTapped), for: .touchUpInside)
        findButton.translatesAutoresizingMaskIntoConstraints = false
        findButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true

        // ── Event card (hidden until event is found) ───────────────────────────
        eventCard.backgroundColor  = .systemBackground
        eventCard.layer.cornerRadius = 12
        eventCard.layer.shadowColor  = UIColor.black.cgColor
        eventCard.layer.shadowOpacity = 0.07
        eventCard.layer.shadowRadius  = 6
        eventCard.layer.shadowOffset  = CGSize(width: 0, height: 2)
        eventCard.isHidden           = true
        eventCard.translatesAutoresizingMaskIntoConstraints = false

        eventNameLabel.font = .preferredFont(forTextStyle: .headline)
        eventNameLabel.adjustsFontForContentSizeCategory = true
        eventNameLabel.numberOfLines = 0
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false

        eventDetailLabel.font = .preferredFont(forTextStyle: .subheadline)
        eventDetailLabel.adjustsFontForContentSizeCategory = true
        eventDetailLabel.textColor   = .secondaryLabel
        eventDetailLabel.numberOfLines = 0
        eventDetailLabel.translatesAutoresizingMaskIntoConstraints = false

        [eventNameLabel, eventDetailLabel].forEach { eventCard.addSubview($0) }
        NSLayoutConstraint.activate([
            eventNameLabel.topAnchor.constraint(equalTo: eventCard.topAnchor, constant: 16),
            eventNameLabel.leadingAnchor.constraint(equalTo: eventCard.leadingAnchor, constant: 16),
            eventNameLabel.trailingAnchor.constraint(equalTo: eventCard.trailingAnchor, constant: -16),
            eventDetailLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 4),
            eventDetailLabel.leadingAnchor.constraint(equalTo: eventCard.leadingAnchor, constant: 16),
            eventDetailLabel.trailingAnchor.constraint(equalTo: eventCard.trailingAnchor, constant: -16),
            eventDetailLabel.bottomAnchor.constraint(equalTo: eventCard.bottomAnchor, constant: -16),
        ])

        // ── Setup button ───────────────────────────────────────────────────────
        var setupCfg = UIButton.Configuration.filled()
        setupCfg.baseBackgroundColor = UIColor(red: 0.22, green: 0.62, blue: 0.34, alpha: 1.0)
        setupCfg.baseForegroundColor = .white
        setupCfg.cornerStyle         = .large
        setupCfg.contentInsets       = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        setupCfg.title               = "Set Up My Group →"
        setupButton.configuration    = setupCfg
        setupButton.isHidden         = true
        setupButton.addTarget(self, action: #selector(setupTapped), for: .touchUpInside)
        setupButton.translatesAutoresizingMaskIntoConstraints = false
        setupButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true

        // ── Spectator button ───────────────────────────────────────────────────
        var spectatorCfg = UIButton.Configuration.plain()
        spectatorCfg.title = "Watch Leaderboard (spectator)"
        spectatorCfg.image = UIImage(systemName: "eye.fill")
        spectatorCfg.imagePadding = 6
        spectatorCfg.baseForegroundColor = Self.teal
        spectatorCfg.cornerStyle = .large
        spectatorButton.configuration = spectatorCfg
        spectatorButton.isHidden = true
        spectatorButton.addTarget(self, action: #selector(watchSpectator), for: .touchUpInside)
        spectatorButton.translatesAutoresizingMaskIntoConstraints = false

        // ── Enter group code button ────────────────────────────────────────────
        var egCfg = UIButton.Configuration.plain()
        egCfg.title = "My group is set up — enter group code"
        egCfg.image = UIImage(systemName: "number")
        egCfg.imagePadding = 6
        egCfg.baseForegroundColor = Self.teal
        egCfg.cornerStyle = .large
        enterGroupButton.configuration = egCfg
        enterGroupButton.isHidden = true
        enterGroupButton.addTarget(self, action: #selector(enterGroupCode), for: .touchUpInside)
        enterGroupButton.translatesAutoresizingMaskIntoConstraints = false

        // ── Assemble ───────────────────────────────────────────────────────────
        [instrLabel, codeField, findButton, eventCard, setupButton, spectatorButton, enterGroupButton]
            .forEach { content.addSubview($0) }

        NSLayoutConstraint.activate([
            instrLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 32),
            instrLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            instrLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),

            codeField.topAnchor.constraint(equalTo: instrLabel.bottomAnchor, constant: 24),
            codeField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            codeField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),

            findButton.topAnchor.constraint(equalTo: codeField.bottomAnchor, constant: 16),
            findButton.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            findButton.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -48),

            eventCard.topAnchor.constraint(equalTo: findButton.bottomAnchor, constant: 24),
            eventCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            eventCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            setupButton.topAnchor.constraint(equalTo: eventCard.bottomAnchor, constant: 16),
            setupButton.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            setupButton.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -48),

            enterGroupButton.topAnchor.constraint(equalTo: setupButton.bottomAnchor, constant: 8),
            enterGroupButton.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            enterGroupButton.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -48),

            spectatorButton.topAnchor.constraint(equalTo: enterGroupButton.bottomAnchor, constant: 4),
            spectatorButton.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            spectatorButton.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -48),
            spectatorButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -32),
        ])
    }

    // MARK: - Actions

    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func codeChanged() {
        let raw = (codeField.text ?? "").uppercased().filter { $0.isLetter || $0.isNumber }
        let trimmed = String(raw.prefix(6))
        if codeField.text != trimmed { codeField.text = trimmed }
        findButton.isEnabled = trimmed.count == 6
        // Hide card if user edits the code after a successful lookup
        if !eventCard.isHidden {
            eventCard.isHidden  = true
            setupButton.isHidden = true
            spectatorButton.isHidden = true
            enterGroupButton.isHidden = true
            foundEvent = nil
        }
    }

    @objc private func findTapped() {
        guard let code = codeField.text, code.count == 6 else { return }
        codeField.resignFirstResponder()

        findButton.configuration?.showsActivityIndicator = true
        findButton.isEnabled = false

        Task {
            do {
                let record = try await SupabaseService.shared.fetchClubEvent(code: code)
                await MainActor.run {
                    self.foundEvent = record
                    self.showEventCard(record)
                    self.findButton.configuration?.showsActivityIndicator = false
                    self.findButton.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    self.findButton.configuration?.showsActivityIndicator = false
                    self.findButton.isEnabled = true
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    @objc private func setupTapped() {
        guard let event = foundEvent else { return }
        let vc = ClubEventGroupSetupViewController(event: event)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func watchSpectator() {
        guard let event = foundEvent else { return }
        let (pars, hcs) = coursePHForEvent(event)
        let vc = ClubEventLeaderboardViewController(
            tournamentId: event.id,
            eventName: event.name,
            coursePars: pars,
            courseHCs: hcs,
            myGroupCode: ""
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func enterGroupCode() {
        guard let event = foundEvent else { return }
        let ac = UIAlertController(
            title: "Enter Group Code",
            message: "Enter the 6-character group code for your scoring group.",
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "XXXXXX"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.font = UIFont.monospacedSystemFont(ofSize: 22, weight: .bold)
            tf.textAlignment = .center
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self, weak ac] _ in
            let raw = (ac?.textFields?.first?.text ?? "")
                .uppercased()
                .filter { $0.isLetter || $0.isNumber }
            let code = String(raw.prefix(6))
            guard code.count == 6 else {
                self?.showError("Group code must be 6 characters.")
                return
            }
            self?.resolveAndJoinGroup(event: event, groupCode: code)
        })
        present(ac, animated: true)
    }

    private func resolveAndJoinGroup(event: ClubEventRecord, groupCode: String) {
        let spinner = UIAlertController(title: nil, message: "Loading group…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                // Fetch roster, teams, and rules in parallel.
                async let rosterFetch = SupabaseService.shared.fetchClubEventRoster(tournamentId: event.id)
                async let teamsFetch  = SupabaseService.shared.fetchClubEventTeams(tournamentId: event.id)
                async let rulesFetch  = SupabaseService.shared.fetchClubEventRules(tournamentId: event.id)

                let roster = try await rosterFetch
                let teams  = try await teamsFetch
                let _      = try await rulesFetch   // ensure rules load succeeds; values reserved for future use

                // Memberships depend on team IDs — fetched after.
                let memberships = try await SupabaseService.shared.fetchClubEventTeamMemberships(
                    teamIds: teams.map { $0.id })

                let groupPlayers = roster.filter { ($0.groupCode ?? "") == groupCode }
                guard !groupPlayers.isEmpty else {
                    await MainActor.run {
                        spinner.dismiss(animated: false) { self.showError("No players found for group \(groupCode).") }
                    }
                    return
                }

                var playerTeams: [UUID: [String]] = [:]
                for m in memberships {
                    guard let team = teams.first(where: { $0.id == m.teamId }) else { continue }
                    let suffix = team.teamName.hasSuffix("-A") ? "A"
                               : team.teamName.hasSuffix("-B") ? "B"
                               : nil
                    guard let suffix else { continue }
                    playerTeams[m.tournamentPlayerId, default: []].append(suffix)
                }
                let built: [ClubEventGroupPlayer] = groupPlayers.map { p in
                    ClubEventGroupPlayer(
                        id: p.id, name: p.playerName, handicap: p.handicap,
                        teams: playerTeams[p.id] ?? ["A"],
                        isWithdrawn: p.isWithdrawn
                    )
                }

                let scores = (try? await SupabaseService.shared.fetchClubEventGroupScores(
                    tournamentId: event.id,
                    playerIds: built.map { $0.id })) ?? []
                let startHole = LiveConnectedViewController.findNextUnscoredHole(
                    scores: scores, startingHole: 1)

                await MainActor.run {
                    ClubEventSessionStore.shared.save(ClubEventSession(
                        eventId:      event.id,
                        eventCode:    event.code,
                        eventName:    event.name,
                        courseName:   event.courseName,
                        groupCode:    groupCode,
                        startingHole: startHole,
                        playerIds:    built.map { $0.id }
                    ))
                    spinner.dismiss(animated: false) {
                        let vc = ClubEventScoringViewController(
                            tournamentId: event.id,
                            groupCode:    groupCode,
                            startingHole: startHole,
                            eventName:    event.name,
                            courseName:   event.courseName,
                            players:      built
                        )
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showError("Failed to load group: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func coursePHForEvent(_ event: ClubEventRecord) -> ([Int], [Int]) {
        if let name = event.courseName,
           let course = CourseLibrary.shared.courses.first(where: {
               $0.name.caseInsensitiveCompare(name) == .orderedSame
           }),
           !course.pars.isEmpty, course.pars.count == course.hcs.count {
            return (course.pars, course.hcs)
        }
        return (Array(repeating: 4, count: 18), Array(1...18))
    }

    // MARK: - Helpers

    func showEventCard(_ record: ClubEventRecord) {
        eventNameLabel.text   = record.name
        var details: [String] = []
        if let course = record.courseName, !course.isEmpty { details.append(course) }
        details.append("Net Best Ball + Skins")
        if record.numDays > 1 { details.append("\(record.numDays) days") }
        eventDetailLabel.text = details.joined(separator: "  ·  ")
        eventCard.isHidden   = false
        setupButton.isHidden = false
        spectatorButton.isHidden = false
        enterGroupButton.isHidden = false
    }

    private func showError(_ msg: String) {
        let ac = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension ClubEventJoinViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if findButton.isEnabled { findTapped() }
        return false
    }
}
