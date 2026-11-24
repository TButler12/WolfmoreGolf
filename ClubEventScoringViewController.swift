import UIKit

/// Per-hole gross score entry for a club event group.
/// Header matches the existing GameViewController style (dark green, hole info, prev/next, dots).
final class ClubEventScoringViewController: UIViewController {

    struct HoleEntry {
        var gross: Int = 0
        var pickedUp: Bool = false
    }

    // Data
    private let tournamentId: UUID
    private let groupCode:    String
    private let eventName:    String
    private let courseName:   String?
    private let players:      [ClubEventGroupPlayer]
    private let coursePars:   [Int]
    private let courseHCs:    [Int]

    // State
    private var currentHole: Int
    private var holeCount: Int { coursePars.count }
    private var entries: [UUID: [Int: HoleEntry]] = [:]
    private var saveTimers:   [UUID: Timer] = [:]
    private var pendingHoles: [UUID: Int]   = [:]   // hole number for each in-flight save
    private var pendingSaves: Set<String>   = []    // "playerId-hole" keys not yet confirmed

    // UI
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private weak var headerView:    UIView?
    private weak var holeInfoLabel: UILabel?
    private weak var courseLabel:   UILabel?
    private weak var savedLabel:    UILabel?
    private weak var holeDotContainer: UIView?
    private var holeDotViews: [UIView] = []
    private weak var bottomBarView: UIView?
    private weak var teamALabel:    UILabel?
    private weak var teamBLabel:    UILabel?
    private weak var leaderboardButton: UIButton?
    private weak var submitButton:      UIButton?

    private weak var toastView:    UIView?
    private var toastTimer:        Timer?
    private var toastUndoAction:   (() -> Void)?
    private weak var managePlayersBtn: UIButton?

    private lazy var teamOrder: [String] = ["A", "B"].filter { team in
        players.contains { $0.teams.contains(team) }
    }

    static let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)

    // MARK: - Init

    init(tournamentId: UUID, groupCode: String, startingHole: Int,
         eventName: String, courseName: String?, players: [ClubEventGroupPlayer]) {
        self.tournamentId = tournamentId
        self.groupCode    = groupCode
        self.eventName    = eventName
        self.courseName   = courseName
        self.players      = players

        if let name = courseName,
           let course = CourseLibrary.shared.courses.first(where: {
               $0.name.caseInsensitiveCompare(name) == .orderedSame
           }),
           !course.pars.isEmpty, course.pars.count == course.hcs.count {
            self.coursePars = course.pars
            self.courseHCs  = course.hcs
        } else {
            self.coursePars = Array(repeating: 4, count: 18)
            self.courseHCs  = Array(1...18)
        }
        // Clamp after pars are known — findNextUnscoredHole uses a hardcoded 18-hole
        // search and may return a hole > holeCount for 9-hole events where all holes
        // are already scored.
        self.currentHole = max(1, min(startingHole, self.coursePars.count))

        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        buildHeader()
        buildBottomBar()
        buildTableView()
        refreshBottomBar()
        loadExistingScores()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        flushSaveTimers()
    }

    // MARK: - Build Header

    private func buildHeader() {
        let header = UIView()
        header.backgroundColor = Self.darkGreen
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        headerView = header

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Ghost back button
        let backBtn = UIButton(type: .system)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        backBtn.layer.cornerRadius = 18
        backBtn.clipsToBounds = true
        backBtn.tintColor = .white
        let chevronCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        backBtn.setImage(UIImage(systemName: "chevron.left", withConfiguration: chevronCfg), for: .normal)
        backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        header.addSubview(backBtn)
        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backBtn.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),
        ])

        // Manage players button (top-right, mirrors back button)
        let mgBtn = UIButton(type: .system)
        mgBtn.translatesAutoresizingMaskIntoConstraints = false
        mgBtn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        mgBtn.layer.cornerRadius = 18
        mgBtn.clipsToBounds = true
        mgBtn.tintColor = .white
        let peopleCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        mgBtn.setImage(UIImage(systemName: "person.2", withConfiguration: peopleCfg), for: .normal)
        mgBtn.addTarget(self, action: #selector(managePlayersTapped), for: .touchUpInside)
        mgBtn.accessibilityLabel = "Manage Players"
        header.addSubview(mgBtn)
        managePlayersBtn = mgBtn
        NSLayoutConstraint.activate([
            mgBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            mgBtn.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            mgBtn.widthAnchor.constraint(equalToConstant: 36),
            mgBtn.heightAnchor.constraint(equalToConstant: 36),
        ])

        // "✓ Saved" indicator (fades in/out, left of manage button)
        let saved = UILabel()
        saved.translatesAutoresizingMaskIntoConstraints = false
        saved.text = "✓ Saved"
        saved.font = .systemFont(ofSize: 12, weight: .semibold)
        saved.textColor = UIColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1.0)
        saved.alpha = 0
        header.addSubview(saved)
        savedLabel = saved
        NSLayoutConstraint.activate([
            saved.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            saved.trailingAnchor.constraint(equalTo: mgBtn.leadingAnchor, constant: -8),
        ])

        // Hole info label
        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.textAlignment = .center
        infoLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        infoLabel.textColor = .white
        infoLabel.adjustsFontSizeToFitWidth = true
        infoLabel.minimumScaleFactor = 0.6
        header.addSubview(infoLabel)
        holeInfoLabel = infoLabel
        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            infoLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backBtn.trailingAnchor, constant: 8),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: mgBtn.leadingAnchor, constant: -8),
        ])

        // Course name label
        let cLabel = UILabel()
        cLabel.translatesAutoresizingMaskIntoConstraints = false
        cLabel.textAlignment = .center
        cLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        cLabel.textColor = UIColor.white.withAlphaComponent(0.60)
        cLabel.adjustsFontSizeToFitWidth = true
        cLabel.minimumScaleFactor = 0.7
        cLabel.text = courseName ?? eventName
        header.addSubview(cLabel)
        courseLabel = cLabel
        NSLayoutConstraint.activate([
            cLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            cLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 3),
            cLabel.leadingAnchor.constraint(greaterThanOrEqualTo: header.leadingAnchor, constant: 60),
            cLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -60),
        ])

        // Prev / Next ghost pills
        let prevBtn = makePillButton(title: "< Prev", action: #selector(prevHole))
        let nextBtn = makePillButton(title: "Next >", action: #selector(nextHole))
        let dotsView = UIView()
        dotsView.translatesAutoresizingMaskIntoConstraints = false
        dotsView.backgroundColor = .clear
        holeDotContainer = dotsView

        header.addSubview(prevBtn)
        header.addSubview(nextBtn)
        header.addSubview(dotsView)
        NSLayoutConstraint.activate([
            prevBtn.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            prevBtn.topAnchor.constraint(equalTo: cLabel.bottomAnchor, constant: 10),
            prevBtn.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            nextBtn.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            nextBtn.centerYAnchor.constraint(equalTo: prevBtn.centerYAnchor),
            nextBtn.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            dotsView.leadingAnchor.constraint(equalTo: prevBtn.trailingAnchor, constant: 6),
            dotsView.trailingAnchor.constraint(equalTo: nextBtn.leadingAnchor, constant: -6),
            dotsView.centerYAnchor.constraint(equalTo: prevBtn.centerYAnchor),
            dotsView.heightAnchor.constraint(equalToConstant: 10),

            header.bottomAnchor.constraint(equalTo: prevBtn.bottomAnchor, constant: 12),
        ])

        buildHoleDots(in: dotsView)
        refreshHeader()
    }

    private func makePillButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    private func buildHoleDots(in container: UIView) {
        holeDotViews.forEach { $0.removeFromSuperview() }
        holeDotViews.removeAll()
        var prev: UIView?
        for i in 0..<holeCount {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 3
            dot.backgroundColor = UIColor.white.withAlphaComponent(0.30)
            container.addSubview(dot)
            holeDotViews.append(dot)
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 6),
                dot.heightAnchor.constraint(equalToConstant: 6),
                dot.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ])
            if let p = prev {
                dot.leadingAnchor.constraint(equalTo: p.trailingAnchor, constant: 3).isActive = true
            } else {
                dot.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor).isActive = true
            }
            if i == holeCount - 1 {
                dot.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor).isActive = true
            }
            prev = dot
        }
    }

    private func refreshHeader() {
        guard currentHole >= 1, currentHole <= holeCount else { return }
        let par = coursePars[currentHole - 1]
        let hc  = courseHCs[currentHole - 1]
        holeInfoLabel?.text = "Hole \(currentHole)  ·  Par \(par)  ·  HC \(hc)"
        for (i, dot) in holeDotViews.enumerated() {
            dot.backgroundColor = (i == currentHole - 1)
                ? .white
                : UIColor.white.withAlphaComponent(0.30)
        }
    }

    // MARK: - Build Bottom Bar

    private func buildBottomBar() {
        let bar = UIView()
        bar.backgroundColor = .systemBackground
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        bottomBarView = bar
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(sep)

        let aLabel = UILabel()
        aLabel.font = .preferredFont(forTextStyle: .footnote)
        aLabel.adjustsFontForContentSizeCategory = true
        aLabel.numberOfLines = 0
        aLabel.translatesAutoresizingMaskIntoConstraints = false
        teamALabel = aLabel

        let bLabel = UILabel()
        bLabel.font = .preferredFont(forTextStyle: .footnote)
        bLabel.adjustsFontForContentSizeCategory = true
        bLabel.numberOfLines = 0
        bLabel.translatesAutoresizingMaskIntoConstraints = false
        teamBLabel = bLabel

        let teamStack = UIStackView(arrangedSubviews: [aLabel, bLabel])
        teamStack.axis      = .vertical
        teamStack.spacing   = 2
        teamStack.alignment = .fill
        teamStack.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(teamStack)

        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        cfg.title = "Full Leaderboard"
        cfg.image = UIImage(systemName: "list.number")
        cfg.imagePadding = 6
        let lbBtn = UIButton(configuration: cfg)
        lbBtn.addTarget(self, action: #selector(leaderboardTapped), for: .touchUpInside)
        lbBtn.translatesAutoresizingMaskIntoConstraints = false
        leaderboardButton = lbBtn

        var subCfg = UIButton.Configuration.filled()
        subCfg.baseBackgroundColor = Self.darkGreen
        subCfg.baseForegroundColor = .white
        subCfg.cornerStyle = .large
        subCfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        subCfg.title = "Submit Card ✓"
        subCfg.image = UIImage(systemName: "checkmark.seal.fill")
        subCfg.imagePadding = 6
        let subBtn = UIButton(configuration: subCfg)
        subBtn.addTarget(self, action: #selector(submitCardTapped), for: .touchUpInside)
        subBtn.translatesAutoresizingMaskIntoConstraints = false
        subBtn.isHidden = true
        submitButton = subBtn

        let btnStack = UIStackView(arrangedSubviews: [subBtn, lbBtn])
        btnStack.axis = .vertical
        btnStack.spacing = 8
        btnStack.alignment = .center
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(btnStack)

        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: bar.topAnchor),
            sep.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            teamStack.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 8),
            teamStack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 20),
            teamStack.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -20),

            btnStack.topAnchor.constraint(equalTo: teamStack.bottomAnchor, constant: 8),
            btnStack.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
            btnStack.bottomAnchor.constraint(equalTo: bar.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])

        // Hide unused team label rows
        aLabel.isHidden = !teamOrder.contains("A")
        bLabel.isHidden = !teamOrder.contains("B")
    }

    // MARK: - Build Table View

    private func buildTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ClubEventScoreCell.self, forCellReuseIdentifier: "Score")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        guard let header = headerView, let bottom = bottomBarView else { return }
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottom.topAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func managePlayersTapped() {
        let sheet = UIAlertController(title: "Manage Players", message: nil, preferredStyle: .actionSheet)
        for player in players {
            sheet.addAction(UIAlertAction(title: "Release \(player.name)…", style: .destructive) { [weak self] _ in
                self?.confirmRelease(player: player)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.sourceView = managePlayersBtn ?? view
        present(sheet, animated: true)
    }

    private func confirmRelease(player: ClubEventGroupPlayer) {
        let ac = UIAlertController(
            title: "Release \(player.name)?",
            message: "They will return to the available roster. Any scores they entered will be deleted.",
            preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Release", style: .destructive) { [weak self] _ in
            self?.performRelease(player: player)
        })
        present(ac, animated: true)
    }

    private func performRelease(player: ClubEventGroupPlayer) {
        let loading = UIAlertController(title: nil, message: "Releasing…", preferredStyle: .alert)
        present(loading, animated: true)
        Task {
            do {
                try await SupabaseService.shared.releaseClubEventPlayer(
                    playerId: player.id, groupCode: groupCode)
                await MainActor.run {
                    loading.dismiss(animated: false) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    loading.dismiss(animated: false) {
                        let err = UIAlertController(title: "Could Not Release",
                                                    message: error.localizedDescription,
                                                    preferredStyle: .alert)
                        err.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(err, animated: true)
                    }
                }
            }
        }
    }

    @objc private func prevHole() {
        flushSaveTimers()
        currentHole = currentHole == 1 ? holeCount : currentHole - 1
        refreshHeader()
        tableView.reloadData()
        refreshBottomBar()
    }

    @objc private func nextHole() {
        flushSaveTimers()
        currentHole = currentHole == holeCount ? 1 : currentHole + 1
        refreshHeader()
        tableView.reloadData()
        refreshBottomBar()
    }

    @objc private func leaderboardTapped() {
        let vc = ClubEventLeaderboardViewController(
            tournamentId: tournamentId,
            eventName:    eventName,
            coursePars:   coursePars,
            courseHCs:    courseHCs,
            myGroupCode:  groupCode
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func submitCardTapped() {
        let vc = ClubEventReviewSubmitViewController(
            tournamentId: tournamentId,
            groupCode:    groupCode,
            players:      players,
            entries:      entries,
            coursePars:   coursePars,
            courseHCs:    courseHCs
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    private var allHolesComplete: Bool {
        for team in teamOrder {
            let teamPlayers = players.filter { $0.teams.contains(team) }
            guard !teamPlayers.isEmpty else { continue }
            for hole in 1...holeCount {
                let anyScored = teamPlayers.contains { p in
                    let e = entries[p.id]?[hole]
                    return (e?.gross ?? 0) > 0 || e?.pickedUp == true
                }
                if !anyScored { return false }
            }
        }
        return true
    }

    // MARK: - Picked-up toast

    func showPickedUpToast(playerName: String, holeNumber: Int, undoAction: @escaping () -> Void) {
        toastView?.removeFromSuperview()
        toastTimer?.invalidate()
        toastUndoAction = undoAction

        let container = UIView()
        container.backgroundColor = UIColor(white: 0.15, alpha: 0.92)
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        let msgLabel = UILabel()
        msgLabel.text = "\(playerName) picked up on hole \(holeNumber)"
        msgLabel.font = .preferredFont(forTextStyle: .footnote)
        msgLabel.textColor = .white
        msgLabel.translatesAutoresizingMaskIntoConstraints = false

        let undoBtn = UIButton(type: .system)
        undoBtn.setTitle("Undo", for: .normal)
        undoBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        undoBtn.setTitleColor(.systemYellow, for: .normal)
        undoBtn.accessibilityIdentifier = "pickUpUndoButton"
        undoBtn.translatesAutoresizingMaskIntoConstraints = false
        undoBtn.addTarget(self, action: #selector(toastUndoTapped), for: .touchUpInside)

        container.addSubview(msgLabel)
        container.addSubview(undoBtn)
        view.addSubview(container)

        // Position above the bottom bar so it never covers Submit or Leaderboard at any text size
        let bottomRef: NSLayoutYAxisAnchor = bottomBarView?.topAnchor ?? view.safeAreaLayoutGuide.bottomAnchor
        NSLayoutConstraint.activate([
            msgLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            msgLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            undoBtn.leadingAnchor.constraint(equalTo: msgLabel.trailingAnchor, constant: 12),
            undoBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            undoBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: bottomRef, constant: -8),
        ])

        container.alpha = 0
        UIView.animate(withDuration: 0.25) { container.alpha = 1 }

        toastView = container
        toastTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            self?.dismissToast()
        }
    }

    private func dismissToast() {
        toastTimer?.invalidate()
        toastTimer = nil
        toastUndoAction = nil
        guard let v = toastView else { return }
        UIView.animate(withDuration: 0.2, animations: { v.alpha = 0 }) { _ in v.removeFromSuperview() }
        toastView = nil
    }

    @objc private func toastUndoTapped() {
        toastUndoAction?()
        toastUndoAction = nil
        dismissToast()
    }

    // MARK: - Save

    private func pendingKey(_ playerId: UUID, _ hole: Int) -> String { "\(playerId.uuidString)-\(hole)" }

    private func flushSaveTimers() {
        for (pid, timer) in saveTimers {
            timer.invalidate()
            savePlayerScoreNow(playerId: pid)
        }
        saveTimers.removeAll()
    }

    private func scheduleAutoSave(for playerId: UUID) {
        let hole = currentHole
        saveTimers[playerId]?.invalidate()
        pendingHoles[playerId] = hole
        pendingSaves.insert(pendingKey(playerId, hole))
        updateSaveIndicator()
        saveTimers[playerId] = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.saveTimers.removeValue(forKey: playerId)
            self.savePlayerScoreNow(playerId: playerId)
        }
    }

    private func savePlayerScoreNow(playerId: UUID, retryCount: Int = 0) {
        let hole  = pendingHoles[playerId] ?? currentHole
        let entry = entries[playerId]?[hole] ?? HoleEntry()
        guard entry.gross > 0 || entry.pickedUp else {
            pendingSaves.remove(pendingKey(playerId, hole))
            pendingHoles.removeValue(forKey: playerId)
            updateSaveIndicator()
            return
        }
        Task {
            do {
                try await SupabaseService.shared.upsertClubEventHoleScore(
                    tournamentId: tournamentId,
                    playerId:     playerId,
                    day:          1,
                    hole:         hole,
                    gross:        entry.gross > 0 ? entry.gross : nil,
                    pickedUp:     entry.pickedUp,
                    groupCode:    groupCode
                )
                await MainActor.run {
                    self.pendingSaves.remove(self.pendingKey(playerId, hole))
                    self.pendingHoles.removeValue(forKey: playerId)
                    self.updateSaveIndicator()
                }
            } catch {
                await MainActor.run {
                    if retryCount < 3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            self?.savePlayerScoreNow(playerId: playerId, retryCount: retryCount + 1)
                        }
                    }
                    self.updateSaveIndicator()
                }
            }
        }
    }

    private func updateSaveIndicator() {
        guard let lbl = savedLabel else { return }
        lbl.layer.removeAllAnimations()
        if pendingSaves.isEmpty {
            lbl.text      = "✓ Saved"
            lbl.textColor = UIColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1.0)
            lbl.alpha = 1
            UIView.animate(withDuration: 0.25, delay: 1.5, options: .curveEaseOut) {
                lbl.alpha = 0
            }
        } else {
            lbl.text      = "Not saved, retrying…"
            lbl.textColor = .systemRed
            lbl.alpha = 1
        }
    }

    // MARK: - Load

    private func loadExistingScores() {
        Task {
            do {
                let playerIds = players.map { $0.id }
                let existing  = try await SupabaseService.shared.fetchClubEventGroupScores(
                    tournamentId: tournamentId, playerIds: playerIds)
                await MainActor.run {
                    for s in existing {
                        let pid = s.tournamentPlayerId
                        if self.entries[pid] == nil { self.entries[pid] = [:] }
                        self.entries[pid]![s.holeNumber] = HoleEntry(
                            gross:    s.grossScore ?? 0,
                            pickedUp: s.netScoreType == "picked_up"
                        )
                    }
                    self.tableView.reloadData()
                    self.refreshBottomBar()
                }
            } catch {
                print("⚠️ Load scores failed: \(error)")
            }
        }
    }

    // MARK: - Bottom Bar Refresh

    private func refreshBottomBar() {
        for team in ["A", "B"] {
            let label = team == "A" ? teamALabel : teamBLabel
            guard let lbl = label, teamOrder.contains(team) else { continue }
            let net      = runningNetToPar(for: team)
            let thru     = holesThru(for: team)
            lbl.text = "\(teamDisplayName(for: team)): \(formatNet(net)) · thru \(thru)"
            lbl.textColor = net < 0 ? UIColor.systemRed
                           : net > 0 ? UIColor.secondaryLabel
                           : UIColor.label
        }
        submitButton?.isHidden = !allHolesComplete
    }

    private func lastName(of name: String) -> String {
        name.components(separatedBy: " ").last ?? name
    }

    private func teamDisplayName(for team: String) -> String {
        let tp = players.filter { $0.teams.contains(team) }
        if tp.isEmpty { return "Team \(team)" }
        return tp.map { lastName(of: $0.name) }.sorted().joined(separator: " / ")
    }

    private func formatNet(_ net: Int) -> String {
        if net == 0 { return "E" }
        return net > 0 ? "+\(net)" : "\(net)"
    }

    // MARK: - Scoring helpers

    // Static so tests can call ClubEventScoringViewController.strokesOnHole(playerHC:holeHCRank:holeCount:)
    static func strokesOnHole(playerHC: Double, holeHCRank: Int, holeCount: Int) -> Int {
        var hc = max(0, Int(playerHC.rounded()))
        if holeCount == 9 { hc = Int((Double(hc) / 2.0).rounded()) }
        return hc / holeCount + (holeHCRank <= hc % holeCount ? 1 : 0)
    }

    private func strokesOnHole(playerHC: Double, holeHCRank: Int) -> Int {
        Self.strokesOnHole(playerHC: playerHC, holeHCRank: holeHCRank, holeCount: holeCount)
    }

    private func countingPlayerID(for team: String, hole: Int) -> UUID? {
        let holeHC = courseHCs[hole - 1]
        var bestNet = Int.max
        var best: UUID?
        for player in players where player.teams.contains(team) {
            let entry = entries[player.id]?[hole] ?? HoleEntry()
            guard !entry.pickedUp, entry.gross > 0 else { continue }
            let net = entry.gross - strokesOnHole(playerHC: player.handicap, holeHCRank: holeHC)
            if net < bestNet { bestNet = net; best = player.id }
        }
        return best
    }

    private func runningNetToPar(for team: String) -> Int {
        var total = 0
        for hole in 1...holeCount {
            let holeHC = courseHCs[hole - 1]
            var bestNet: Int?
            for player in players where player.teams.contains(team) {
                let entry = entries[player.id]?[hole] ?? HoleEntry()
                guard !entry.pickedUp, entry.gross > 0 else { continue }
                let net = entry.gross - strokesOnHole(playerHC: player.handicap, holeHCRank: holeHC)
                if bestNet == nil || net < bestNet! { bestNet = net }
            }
            if let net = bestNet { total += net - coursePars[hole - 1] }
        }
        return total
    }

    private func holesThru(for team: String) -> Int {
        var count = 0
        for hole in 1...holeCount {
            let scored = players.filter { $0.teams.contains(team) }.contains { player in
                let e = entries[player.id]?[hole]
                return (e?.gross ?? 0) > 0 && !(e?.pickedUp ?? false)
            }
            if scored { count += 1 }
        }
        return count
    }

    private func setEntry(for playerId: UUID, hole: Int, transform: (inout HoleEntry) -> Void) {
        if entries[playerId] == nil { entries[playerId] = [:] }
        var e = entries[playerId]![hole] ?? HoleEntry()
        transform(&e)
        entries[playerId]![hole] = e
    }
}

// MARK: - UITableViewDataSource

extension ClubEventScoringViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { teamOrder.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let team = teamOrder[section]
        let net = runningNetToPar(for: team)
        return "\(teamDisplayName(for: team).uppercased())  —  \(formatNet(net))"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        players.filter { $0.teams.contains(teamOrder[section]) }.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let team       = teamOrder[indexPath.section]
        let teamPlayers = players.filter { $0.teams.contains(team) }
        let player     = teamPlayers[indexPath.row]
        let entry      = entries[player.id]?[currentHole] ?? HoleEntry()
        let holeHC     = courseHCs[currentHole - 1]
        let par        = coursePars[currentHole - 1]
        let strokes    = strokesOnHole(playerHC: player.handicap, holeHCRank: holeHC)
        let isCounting = countingPlayerID(for: team, hole: currentHole) == player.id

        let otherTeam = player.teams.filter { $0 != team }.first
        let subtitle: String? = player.isWithdrawn ? "Withdrawn"
                              : otherTeam.map { "also counts for Team \($0)" }

        // A dual-team player is editable only in their primary (alphabetically first) team section.
        // A withdrawn player is always read-only.
        let primaryTeam = player.teams.min() ?? team
        let isReadOnly  = player.isWithdrawn || (player.teams.count > 1 && team != primaryTeam)

        let cell = tableView.dequeueReusableCell(withIdentifier: "Score", for: indexPath) as! ClubEventScoreCell
        cell.configure(
            name:       player.name,
            subtitle:   isReadOnly ? nil : subtitle,
            strokes:    strokes,
            par:        par,
            gross:      entry.gross,
            pickedUp:   entry.pickedUp,
            isCounting: isReadOnly ? false : isCounting,
            readOnly:   isReadOnly,
            onGrossChange: { [weak self] newGross in
                guard let self, !isReadOnly else { return }
                self.setEntry(for: player.id, hole: self.currentHole) { $0.gross = newGross }
                self.tableView.reloadData()
                self.refreshBottomBar()
                self.scheduleAutoSave(for: player.id)
            },
            onPickedUpToggle: { [weak self] pickedUp in
                guard let self, !isReadOnly else { return }
                let prevGross = self.entries[player.id]?[self.currentHole]?.gross ?? 0
                let holeSnap  = self.currentHole
                self.setEntry(for: player.id, hole: self.currentHole) { e in
                    e.pickedUp = pickedUp
                    if pickedUp { e.gross = 0 }
                }
                self.tableView.reloadData()
                self.refreshBottomBar()
                self.scheduleAutoSave(for: player.id)
                if pickedUp {
                    self.showPickedUpToast(playerName: player.name, holeNumber: holeSnap) { [weak self] in
                        guard let self else { return }
                        self.setEntry(for: player.id, hole: holeSnap) { e in
                            e.pickedUp = false
                            e.gross    = prevGross
                        }
                        self.tableView.reloadData()
                        self.refreshBottomBar()
                        self.scheduleAutoSave(for: player.id)
                    }
                } else {
                    self.dismissToast()
                }
            }
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ClubEventScoringViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

// MARK: - ClubEventScoreCell

final class ClubEventScoreCell: UITableViewCell {

    private let nameLabel      = UILabel()
    private let dotsLabel      = UILabel()
    private let pickUpButton   = UIButton(type: .system)
    private let grossLabel     = UILabel()
    private let netLabel       = UILabel()
    private let minusButton    = UIButton(type: .system)
    private let plusButton     = UIButton(type: .system)

    var onGrossChange:    ((Int)  -> Void)?
    var onPickedUpToggle: ((Bool) -> Void)?

    private var currentGross: Int  = 0
    private var isPickedUp:   Bool = false
    private var isCounting:   Bool = false
    private var strokes:      Int  = 0
    private var parForHole:   Int  = 4

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        buildLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildLayout() {
        // Fixed font — never mutated during configure/updateDisplay so layout stays stable
        nameLabel.font = .systemFont(ofSize: 17, weight: .regular)
        nameLabel.adjustsFontForContentSizeCategory = false
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byWordWrapping
        // UILabel default compression resistance is .defaultHigh (750) — don't lower it
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        dotsLabel.font      = .systemFont(ofSize: 10, weight: .regular)
        dotsLabel.textColor = .systemOrange
        dotsLabel.translatesAutoresizingMaskIntoConstraints = false

        pickUpButton.titleLabel?.font = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .systemFont(ofSize: 12, weight: .regular))
        pickUpButton.titleLabel?.adjustsFontForContentSizeCategory = true
        pickUpButton.contentHorizontalAlignment = .leading
        pickUpButton.accessibilityIdentifier = "pickUpButton"
        pickUpButton.translatesAutoresizingMaskIntoConstraints = false
        pickUpButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        pickUpButton.addTarget(self, action: #selector(pickedUpTapped), for: .touchUpInside)

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, dotsLabel, pickUpButton])
        nameStack.axis    = .vertical
        nameStack.spacing = 1
        nameStack.translatesAutoresizingMaskIntoConstraints = false

        // Fixed-width gross score
        grossLabel.textAlignment = .center
        grossLabel.translatesAutoresizingMaskIntoConstraints = false
        grossLabel.widthAnchor.constraint(equalToConstant: 36).isActive = true

        // Net score shown below gross when player has strokes
        netLabel.font          = .systemFont(ofSize: 11, weight: .regular)
        netLabel.textColor     = .secondaryLabel
        netLabel.textAlignment = .center
        netLabel.translatesAutoresizingMaskIntoConstraints = false

        let scoreColumn = UIStackView(arrangedSubviews: [grossLabel, netLabel])
        scoreColumn.axis      = .vertical
        scoreColumn.spacing   = 1
        scoreColumn.alignment = .center
        scoreColumn.translatesAutoresizingMaskIntoConstraints = false
        scoreColumn.setContentHuggingPriority(.required, for: .horizontal)

        for (btn, title) in [(minusButton, "−"), (plusButton, "+")] {
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        }
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
        plusButton.addTarget(self,  action: #selector(plusTapped),  for: .touchUpInside)

        let controlStack = UIStackView(arrangedSubviews: [minusButton, scoreColumn, plusButton])
        controlStack.axis      = .horizontal
        controlStack.spacing   = 4
        controlStack.alignment = .center
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        controlStack.setContentHuggingPriority(.required, for: .horizontal)
        controlStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(nameStack)
        contentView.addSubview(controlStack)
        NSLayoutConstraint.activate([
            nameStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            nameStack.trailingAnchor.constraint(lessThanOrEqualTo: controlStack.leadingAnchor, constant: -8),

            controlStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            controlStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
        ])
    }

    func configure(name:     String,
                   subtitle: String? = nil,
                   strokes:  Int,
                   par:      Int,
                   gross:    Int,
                   pickedUp: Bool,
                   isCounting: Bool,
                   readOnly: Bool = false,
                   onGrossChange:    @escaping (Int)  -> Void,
                   onPickedUpToggle: @escaping (Bool) -> Void) {
        self.currentGross     = gross
        self.isPickedUp       = pickedUp
        self.isCounting       = isCounting
        self.strokes          = strokes
        self.parForHole       = par
        self.onGrossChange    = onGrossChange
        self.onPickedUpToggle = onPickedUpToggle

        nameLabel.text = subtitle.map { "\(name)\n\($0)" } ?? name

        if readOnly {
            dotsLabel.text      = "scored above ↑"
            dotsLabel.textColor = .secondaryLabel
        } else {
            dotsLabel.text      = strokes > 0 ? String(repeating: "●", count: strokes) : ""
            dotsLabel.textColor = .systemOrange
        }
        minusButton.isHidden  = readOnly
        plusButton.isHidden   = readOnly
        pickUpButton.isHidden = readOnly
        updateDisplay()
    }

    private func updateDisplay() {
        // Green background tint for the counting player — font never changes
        contentView.backgroundColor = (isCounting && !isPickedUp && currentGross > 0)
            ? UIColor.systemGreen.withAlphaComponent(0.10)
            : .systemBackground

        if isPickedUp {
            grossLabel.text       = "P"
            grossLabel.font       = .systemFont(ofSize: 20, weight: .semibold)
            grossLabel.textColor  = .systemOrange
            netLabel.text         = nil
            minusButton.isEnabled = false
            plusButton.isEnabled  = false
            pickUpButton.setTitle("✕ Picked up", for: .normal)
            pickUpButton.setTitleColor(.systemOrange, for: .normal)
        } else if currentGross > 0 {
            grossLabel.text       = "\(currentGross)"
            grossLabel.font       = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
            grossLabel.textColor  = .label
            netLabel.text         = strokes > 0 ? "net \(currentGross - strokes)" : nil
            minusButton.isEnabled = currentGross > 1
            plusButton.isEnabled  = true
            pickUpButton.setTitle("Pick up", for: .normal)
            pickUpButton.setTitleColor(.secondaryLabel, for: .normal)
        } else {
            grossLabel.text       = "—"
            grossLabel.font       = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
            grossLabel.textColor  = .tertiaryLabel
            netLabel.text         = nil
            minusButton.isEnabled = false
            plusButton.isEnabled  = true
            pickUpButton.setTitle("Pick up", for: .normal)
            pickUpButton.setTitleColor(.secondaryLabel, for: .normal)
        }
    }

    @objc private func minusTapped() {
        guard !isPickedUp, currentGross > 1 else { return }
        currentGross -= 1
        updateDisplay()
        onGrossChange?(currentGross)
    }

    @objc private func plusTapped() {
        guard !isPickedUp else { return }
        // First tap: set to par; subsequent taps increment
        if currentGross == 0 {
            currentGross = parForHole
        } else {
            currentGross = min(currentGross + 1, 15)
        }
        updateDisplay()
        onGrossChange?(currentGross)
    }

    @objc private func pickedUpTapped() {
        isPickedUp.toggle()
        if isPickedUp { currentGross = 0 }
        updateDisplay()
        onPickedUpToggle?(isPickedUp)
    }
}
