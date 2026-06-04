import UIKit

final class WolfSpectatorViewController: UIViewController {

    // MARK: - External input
    var sessionCode: String = ""

    // MARK: - Multi-session state
    private var sessions: [WolfSession] = []
    private var holeResultsBySessionId: [String: [Int: WolfHoleResult]] = [:]
    private var currentSessionIndex: Int = 0

    private var currentSession: WolfSession? {
        sessions.indices.contains(currentSessionIndex) ? sessions[currentSessionIndex] : nil
    }
    private var currentHoleResults: [Int: WolfHoleResult] {
        guard let id = currentSession?.id else { return [:] }
        return holeResultsBySessionId[id] ?? [:]
    }

    // MARK: - UI
    private let tabScrollView = UIScrollView()
    private let tabStack      = UIStackView()
    private var tabButtons: [UIButton] = []
    private let statusBanner  = UILabel()
    private let tableView     = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingView   = UIActivityIndicatorView(style: .large)

    private let savedCodesKey = "watchedWolfSessions"
    private let maxSessions   = 3

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Match"
        view.backgroundColor = .systemBackground
        setupTabBar()
        setupStatusBanner()
        setupTableView()
        setupLoadingView()
        loadInitialSessions()
        let trashButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearAllTapped)
        )
        trashButton.tintColor = .systemRed
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )
        navigationItem.rightBarButtonItems = [trashButton, refreshButton]
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        Task {
            for session in sessions {
                await subscribeToSession(session)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let toUnsub = sessions
        Task {
            for session in toUnsub {
                await SupabaseService.shared.unsubscribeFromWolfSession(sessionId: session.id)
            }
        }
    }

    // MARK: - Setup

    private func setupTabBar() {
        tabScrollView.translatesAutoresizingMaskIntoConstraints = false
        tabScrollView.showsHorizontalScrollIndicator = false
        tabScrollView.alwaysBounceHorizontal = true
        view.addSubview(tabScrollView)
        NSLayoutConstraint.activate([
            tabScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tabScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabScrollView.heightAnchor.constraint(equalToConstant: 44),
        ])

        tabStack.axis      = .horizontal
        tabStack.spacing   = 8
        tabStack.alignment = .center
        tabStack.translatesAutoresizingMaskIntoConstraints = false
        tabScrollView.addSubview(tabStack)
        NSLayoutConstraint.activate([
            tabStack.topAnchor.constraint(equalTo: tabScrollView.contentLayoutGuide.topAnchor),
            tabStack.leadingAnchor.constraint(equalTo: tabScrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            tabStack.trailingAnchor.constraint(equalTo: tabScrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            tabStack.bottomAnchor.constraint(equalTo: tabScrollView.contentLayoutGuide.bottomAnchor),
            tabStack.heightAnchor.constraint(equalTo: tabScrollView.frameLayoutGuide.heightAnchor),
        ])
    }

    private func setupStatusBanner() {
        statusBanner.translatesAutoresizingMaskIntoConstraints = false
        statusBanner.textAlignment   = .center
        statusBanner.font            = .systemFont(ofSize: 13, weight: .semibold)
        statusBanner.textColor       = .white
        statusBanner.backgroundColor = .systemGreen
        statusBanner.text            = "LIVE"
        statusBanner.isHidden        = true
        view.addSubview(statusBanner)
        NSLayoutConstraint.activate([
            statusBanner.topAnchor.constraint(equalTo: tabScrollView.bottomAnchor),
            statusBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBanner.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(WolfHoleCell.self, forCellReuseIdentifier: WolfHoleCell.reuseID)
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: statusBanner.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupLoadingView() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        loadingView.startAnimating()
    }

    // MARK: - Tab bar

    private func rebuildTabBar() {
        for v in tabStack.arrangedSubviews {
            tabStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        tabButtons = []

        for (i, session) in sessions.enumerated() {
            let btn = makeTabButton(code: session.code, index: i)
            tabButtons.append(btn)
            tabStack.addArrangedSubview(btn)
        }

        if sessions.count < maxSessions {
            tabStack.addArrangedSubview(makeAddButton())
        }

        updateTabHighlight()
    }

    private func makeTabButton(code: String, index: Int) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.title = code
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        cfg.baseBackgroundColor = .systemGray5
        cfg.baseForegroundColor = .label
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
            return out
        }
        let btn = UIButton(configuration: cfg)
        btn.tag = index
        btn.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        let lp = UILongPressGestureRecognizer(target: self, action: #selector(tabLongPressed(_:)))
        btn.addGestureRecognizer(lp)
        return btn
    }

    private func makeAddButton() -> UIButton {
        var cfg = UIButton.Configuration.plain()
        cfg.title = "+"
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        cfg.baseForegroundColor = .secondaryLabel
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            return out
        }
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(addSessionTapped), for: .touchUpInside)
        return btn
    }

    private func updateTabHighlight() {
        for (i, btn) in tabButtons.enumerated() {
            var cfg = btn.configuration ?? UIButton.Configuration.filled()
            if i == currentSessionIndex {
                cfg.baseBackgroundColor = .wolfMoreGreen
                cfg.baseForegroundColor = .white
            } else {
                cfg.baseBackgroundColor = .systemGray5
                cfg.baseForegroundColor = .label
            }
            btn.configuration = cfg
        }
    }

    // MARK: - Session loading

    private func loadInitialSessions() {
        var codesToLoad: [String] = []
        let upper = sessionCode.uppercased()
        if !upper.isEmpty { codesToLoad.append(upper) }

        let saved = UserDefaults.standard.stringArray(forKey: savedCodesKey) ?? []
        for code in saved where !codesToLoad.contains(code) && codesToLoad.count < maxSessions {
            codesToLoad.append(code)
        }

        guard !codesToLoad.isEmpty else {
            loadingView.stopAnimating()
            loadingView.isHidden = true
            return
        }

        Task {
            var loaded: [WolfSession] = []
            var resultsBySessionId: [String: [Int: WolfHoleResult]] = [:]

            for code in codesToLoad {
                guard let session = try? await SupabaseService.shared.fetchWolfSessionByCode(code: code) else { continue }
                loaded.append(session)
                let results: [WolfHoleResult]
                do {
                    results = try await SupabaseService.shared.fetchWolfHoleResults(sessionId: session.id)
                } catch {
                    print("ERROR fetchWolfHoleResults for \(session.id): \(error)")
                    results = []
                }
                print("DEBUG wolf fetch loaded: \(results.count) holes for session \(session.id)")
                for r in results {
                    print("DEBUG wolfHoleResult hole=\(r.hole) wolfSlot=\(String(describing: r.wolfSlot)) teamWon=\(String(describing: r.teamWon)) moneyDeltas=\(String(describing: r.moneyDeltas))")
                }
                var dict: [Int: WolfHoleResult] = [:]
                for r in results { dict[r.hole] = r }
                resultsBySessionId[session.id] = dict
            }

            DispatchQueue.main.async {
                self.loadingView.stopAnimating()
                self.loadingView.isHidden = true
                guard !loaded.isEmpty else {
                    self.showError(NSError(
                        domain: "WolfmoreGolf", code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Session not found. Check the code and try again."]))
                    return
                }
                self.sessions = loaded
                self.holeResultsBySessionId = resultsBySessionId
                self.currentSessionIndex = 0
                self.rebuildTabBar()
                self.applyCurrentSession()
                self.saveSessionCodes()
                Task { for session in loaded { await self.subscribeToSession(session) } }
            }
        }
    }

    private func applyCurrentSession() {
        guard let session = currentSession else { return }
        applySessionStatus(session.status)
        tableView.reloadData()
    }

    @objc private func refreshTapped() {
        guard let session = currentSession else { return }
        let sessionId = session.id
        Task {
            let results: [WolfHoleResult]
            do {
                results = try await SupabaseService.shared.fetchWolfHoleResults(sessionId: sessionId)
            } catch {
                print("ERROR fetchWolfHoleResults for \(sessionId): \(error)")
                results = []
            }
            print("DEBUG wolf fetch loaded: \(results.count) holes for session \(sessionId)")
            for r in results {
                print("DEBUG wolfHoleResult hole=\(r.hole) wolfSlot=\(String(describing: r.wolfSlot)) teamWon=\(String(describing: r.teamWon)) moneyDeltas=\(String(describing: r.moneyDeltas))")
            }
            var dict: [Int: WolfHoleResult] = [:]
            for r in results { dict[r.hole] = r }
            DispatchQueue.main.async {
                self.holeResultsBySessionId[sessionId] = dict
                if self.currentSession?.id == sessionId {
                    print("DEBUG spectator reloadData fired with \(dict.count) holes in dict")
                    self.tableView.reloadData()
                } else {
                    print("DEBUG spectator skipping reloadData: currentSession=\(String(describing: self.currentSession?.id)) != target=\(sessionId)")
                }
            }
        }
    }

    private func subscribeToSession(_ session: WolfSession) async {
        // Tear down any stale channels for this session before re-subscribing.
        // Scoped to this session only — unsubscribeAll would cancel other sessions' channels.
        await SupabaseService.shared.unsubscribeFromWolfSession(sessionId: session.id)

        let sessionId = session.id
        print("DEBUG wolf spectator subscribing to session: \(session.id)")
        let holeCallback: (WolfHoleResult) -> Void = { [weak self] result in
            print("DEBUG wolf hole realtime received: hole=\(result.hole) wolfSlot=\(String(describing: result.wolfSlot)) teamWon=\(String(describing: result.teamWon)) moneyDeltas=\(String(describing: result.moneyDeltas))")
            guard let self else { return }
            self.holeResultsBySessionId[sessionId, default: [:]][result.hole] = result
            if self.currentSession?.id == sessionId {
                self.tableView.reloadData()
            }
        }
        SupabaseService.shared.subscribeToWolfHoles(sessionId: sessionId, onResult: holeCallback)
        try? await Task.sleep(nanoseconds: 500_000_000)
        SupabaseService.shared.subscribeToWolfHoleUpdates(sessionId: sessionId, onResult: holeCallback)
        try? await Task.sleep(nanoseconds: 500_000_000)
        SupabaseService.shared.subscribeToWolfSession(sessionId: sessionId) { [weak self] updated in
            guard let self else { return }
            if let idx = self.sessions.firstIndex(where: { $0.id == updated.id }) {
                self.sessions[idx] = updated
                if self.currentSessionIndex == idx {
                    self.applySessionStatus(updated.status)
                }
            }
        }
    }

    // MARK: - Tab actions

    @objc private func tabButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard sessions.indices.contains(index), index != currentSessionIndex else { return }
        currentSessionIndex = index
        updateTabHighlight()
        applyCurrentSession()
    }

    @objc private func tabLongPressed(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began, let btn = gr.view as? UIButton else { return }
        let index = btn.tag
        guard sessions.indices.contains(index) else { return }
        let code = sessions[index].code
        let alert = UIAlertController(
            title: "Remove \"\(code)\"?",
            message: "Stop watching this live game.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.removeSession(at: index)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func removeSession(at index: Int) {
        guard sessions.indices.contains(index) else { return }
        let removed = sessions[index]
        Task { await SupabaseService.shared.unsubscribeFromWolfSession(sessionId: removed.id) }
        holeResultsBySessionId.removeValue(forKey: removed.id)
        sessions.remove(at: index)

        if sessions.isEmpty {
            saveSessionCodes()
            navigationController?.popViewController(animated: true)
            return
        }
        currentSessionIndex = min(currentSessionIndex, sessions.count - 1)
        rebuildTabBar()
        applyCurrentSession()
        saveSessionCodes()
    }

    @objc private func addSessionTapped() {
        guard sessions.count < maxSessions else { return }
        let alert = UIAlertController(
            title: "Watch Another Game",
            message: "Enter the 6-character code",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "e.g. ABC123"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
            tf.returnKeyType = .go
            NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: tf,
                queue: .main
            ) { _ in
                if let text = tf.text, text.count > 6 { tf.text = String(text.prefix(6)) }
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Watch", style: .default) { [weak self, weak alert] _ in
            let code = (alert?.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            guard !code.isEmpty else { return }
            self?.addSession(code: code)
        })
        present(alert, animated: true)
    }

    private func addSession(code: String) {
        if let existing = sessions.firstIndex(where: { $0.code == code }) {
            currentSessionIndex = existing
            updateTabHighlight()
            applyCurrentSession()
            return
        }
        loadingView.isHidden = false
        loadingView.startAnimating()
        Task {
            do {
                let session = try await SupabaseService.shared.fetchWolfSessionByCode(code: code)
                let results: [WolfHoleResult]
                do {
                    results = try await SupabaseService.shared.fetchWolfHoleResults(sessionId: session.id)
                } catch {
                    print("ERROR fetchWolfHoleResults for \(session.id): \(error)")
                    results = []
                }
                var dict: [Int: WolfHoleResult] = [:]
                for r in results { dict[r.hole] = r }
                DispatchQueue.main.async {
                    self.sessions.append(session)
                    self.holeResultsBySessionId[session.id] = dict
                    self.currentSessionIndex = self.sessions.count - 1
                    self.loadingView.stopAnimating()
                    self.loadingView.isHidden = true
                    self.rebuildTabBar()
                    self.applyCurrentSession()
                    self.saveSessionCodes()
                    Task { await self.subscribeToSession(session) }
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadingView.stopAnimating()
                    self.loadingView.isHidden = true
                    let alert = UIAlertController(
                        title: "Code Not Found",
                        message: "Check the code and try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Status banner

    private func applySessionStatus(_ status: String) {
        if status == "archived" {
            statusBanner.text            = "This match has ended"
            statusBanner.backgroundColor = .systemGray
            statusBanner.isHidden        = false
        } else {
            statusBanner.text            = "LIVE"
            statusBanner.backgroundColor = .systemGreen
            statusBanner.isHidden        = false
        }
    }

    // MARK: - Clear all

    @objc private func clearAllTapped() {
        guard !sessions.isEmpty else { return }
        let alert = UIAlertController(
            title: "Clear All Sessions?",
            message: "Stop watching all \(sessions.count) live game(s).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            self?.clearAllSessions()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func clearAllSessions() {
        let toUnsub = sessions
        Task {
            for session in toUnsub {
                await SupabaseService.shared.unsubscribeFromWolfSession(sessionId: session.id)
            }
        }
        sessions.removeAll()
        holeResultsBySessionId.removeAll()
        UserDefaults.standard.removeObject(forKey: savedCodesKey)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Persistence

    private func saveSessionCodes() {
        UserDefaults.standard.set(sessions.map { $0.code }, forKey: savedCodesKey)
    }

    // MARK: - Error

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Could Not Load Session",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension WolfSpectatorViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (currentSession?.playerNames.count ?? 0) > 0 ? 21 : 0   // 1 header + 18 holes + score totals + money totals
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WolfHoleCell.reuseID, for: indexPath) as! WolfHoleCell
        guard let session = currentSession else { return cell }
        let allResults = Array(currentHoleResults.values)
        if indexPath.row == 0 {
            cell.configureAsHeader(playerNames: session.playerNames)
        } else if indexPath.row == 19 {
            cell.configureAsScoreTotals(results: allResults, playerCount: session.playerNames.count)
        } else if indexPath.row == 20 {
            cell.configureAsTotals(results: allResults, playerCount: session.playerNames.count)
        } else {
            let hole = indexPath.row  // 1-based
            cell.configure(hole: hole, result: currentHoleResults[hole], playerNames: session.playerNames)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let s = currentSession else { return nil }
        return "\(s.courseName)  •  Code: \(s.code)"
    }
}

// MARK: - WolfHoleCell

private final class WolfHoleCell: UITableViewCell {
    static let reuseID = "WolfHoleCell"

    private let holeLabel     = UILabel()
    private let decisionLabel = UILabel()
    private var scoreCols: [UILabel] = []
    private let scoreRow   = UIStackView()

    private let moneyLabel = UILabel()
    private var moneyCols: [UILabel] = []
    private let moneyRow   = UIStackView()

    private let outerStack = UIStackView()

    private var holePressLevel: Int = 0 {
        didSet { if oldValue != holePressLevel { setNeedsLayout() } }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Rebuild press border layers on the hole label
        holeLabel.layer.sublayers?.filter { $0.name == "pb" }.forEach { $0.removeFromSuperlayer() }
        holeLabel.layer.borderWidth = 0
        holeLabel.clipsToBounds = false
        guard holePressLevel > 0 else { return }
        let b = holeLabel.bounds
        for i in 0..<min(holePressLevel, 3) {
            let inset = CGFloat(i) * 3.0
            let bl = CALayer()
            bl.name = "pb"
            bl.frame = b.insetBy(dx: inset, dy: inset)
            bl.borderWidth = 1.5
            bl.borderColor = UIColor.systemOrange.cgColor
            bl.cornerRadius = max(2, 4 - inset * 0.5)
            holeLabel.layer.addSublayer(bl)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        outerStack.axis    = .vertical
        outerStack.spacing = 2
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            outerStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            outerStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])

        // Score row
        scoreRow.axis    = .horizontal
        scoreRow.spacing = 6
        outerStack.addArrangedSubview(scoreRow)

        configLabel(holeLabel, size: 15, weight: .regular, width: 32)
        scoreRow.addArrangedSubview(holeLabel)

        configLabel(decisionLabel, size: 11, weight: .semibold, width: 30)
        scoreRow.addArrangedSubview(decisionLabel)

        for _ in 0..<MAX_PLAYERS {
            let l = UILabel()
            configLabel(l, size: 16, weight: .semibold, width: 40)
            scoreCols.append(l)
            scoreRow.addArrangedSubview(l)
        }

        let spacer1 = UIView()
        spacer1.setContentHuggingPriority(.defaultLow, for: .horizontal)
        scoreRow.addArrangedSubview(spacer1)

        // Money sub-row (hidden until a hole has non-zero money_deltas)
        moneyRow.axis     = .horizontal
        moneyRow.spacing  = 6
        moneyRow.isHidden = true
        outerStack.addArrangedSubview(moneyRow)

        configLabel(moneyLabel, size: 13, weight: .regular, width: 32)
        moneyLabel.text      = "$"
        moneyLabel.textColor = .secondaryLabel
        moneyRow.addArrangedSubview(moneyLabel)

        // Spacer to align money cols under score cols (skip decision column)
        let moneyDecisionSpacer = UIView()
        moneyDecisionSpacer.widthAnchor.constraint(equalToConstant: 30).isActive = true
        moneyRow.addArrangedSubview(moneyDecisionSpacer)

        for _ in 0..<MAX_PLAYERS {
            let l = UILabel()
            configLabel(l, size: 13, weight: .semibold, width: 40)
            moneyCols.append(l)
            moneyRow.addArrangedSubview(l)
        }

        let spacer2 = UIView()
        spacer2.setContentHuggingPriority(.defaultLow, for: .horizontal)
        moneyRow.addArrangedSubview(spacer2)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configLabel(_ l: UILabel, size: CGFloat, weight: UIFont.Weight, width: CGFloat) {
        l.font      = .systemFont(ofSize: size, weight: weight)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.8
        l.widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    func configureAsHeader(playerNames: [String]) {
        holePressLevel = 0
        holeLabel.text        = "Hole"
        holeLabel.textColor   = .secondaryLabel
        decisionLabel.text    = ""
        decisionLabel.textColor = .secondaryLabel
        for (i, col) in scoreCols.enumerated() {
            col.text      = i < playerNames.count ? String(playerNames[i].prefix(4)) : ""
            col.textColor = .label
            col.font      = .systemFont(ofSize: 15, weight: .semibold)
        }
        moneyRow.isHidden = true
    }

    func configureAsScoreTotals(results: [WolfHoleResult], playerCount: Int) {
        holePressLevel = 0
        holeLabel.text        = "Score"
        holeLabel.textColor   = .secondaryLabel
        holeLabel.font        = .systemFont(ofSize: 13, weight: .semibold)
        decisionLabel.text    = ""

        var totals = Array(repeating: 0, count: playerCount)
        for result in results {
            guard let scores = result.scores else { continue }
            for (i, s) in scores.enumerated() where i < playerCount {
                totals[i] += s
            }
        }

        for (i, col) in scoreCols.enumerated() {
            guard i < playerCount else { col.text = ""; continue }
            col.font      = .systemFont(ofSize: 16, weight: .bold)
            col.text      = totals[i] > 0 ? "\(totals[i])" : "—"
            col.textColor = .label
        }
        moneyRow.isHidden = true
    }

    func configureAsTotals(results: [WolfHoleResult], playerCount: Int) {
        holePressLevel = 0
        holeLabel.text        = "Total"
        holeLabel.textColor   = .secondaryLabel
        holeLabel.font        = .systemFont(ofSize: 13, weight: .semibold)
        decisionLabel.text    = ""

        var totals = Array(repeating: 0.0, count: playerCount)
        for result in results {
            let deltas = result.moneyDeltas ?? result.payouts ?? []
            for (i, v) in deltas.enumerated() where i < playerCount {
                totals[i] += v
            }
        }

        for (i, col) in scoreCols.enumerated() {
            guard i < playerCount else { col.text = ""; continue }
            let v = totals[i]
            let absV = Swift.abs(v)
            let formatted = absV.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(absV))
                : String(format: "%.2f", absV)
            col.font = .systemFont(ofSize: 13, weight: .bold)
            if v > 0      { col.text = "+\(formatted)"; col.textColor = .systemGreen }
            else if v < 0 { col.text = "−\(formatted)"; col.textColor = .systemRed }
            else          { col.text = "0";              col.textColor = .secondaryLabel }
        }
        moneyRow.isHidden = true
    }

    func configure(hole: Int, result: WolfHoleResult?, playerNames: [String]) {
        holePressLevel       = result?.wolfPlayer ?? 0
        holeLabel.text       = "\(hole)"
        holeLabel.textColor  = holePressLevel > 0 ? .systemOrange : .label

        switch result?.decision {
        case "alone":
            decisionLabel.text      = "A"
            decisionLabel.textColor = .systemOrange
        case "reroll":
            decisionLabel.text      = "RR"
            decisionLabel.textColor = .systemYellow
        case "roll":
            decisionLabel.text      = "R"
            decisionLabel.textColor = .label
        default:
            decisionLabel.text      = ""
            decisionLabel.textColor = .label
        }

        let wolfSlot    = result?.wolfSlot
        let partnerSlot = result?.partnerSlot
        let deltas      = result?.moneyDeltas ?? result?.payouts

        // Wolf team indices for orange coloring (explicit slots preferred)
        let wolfTeamIndices: Set<Int>
        if let ws = wolfSlot {
            var team: Set<Int> = [ws]
            if let ps = partnerSlot { team.insert(ps) }
            wolfTeamIndices = team
        } else {
            wolfTeamIndices = []
        }

        for (i, col) in scoreCols.enumerated() {
            col.font = .systemFont(ofSize: 16, weight: .semibold)
            if let r = result, let scores = r.scores, i < scores.count, scores[i] > 0 {
                col.text      = "\(scores[i])"
                col.textColor = wolfTeamIndices.contains(i) ? .systemOrange : .label
            } else {
                col.text      = "—"
                col.textColor = .tertiaryLabel
            }
        }

        // Money sub-row: show only when this hole has non-zero deltas
        if let deltas = result?.moneyDeltas ?? result?.payouts, deltas.contains(where: { $0 != 0 }) {
            moneyRow.isHidden = false
            for (i, col) in moneyCols.enumerated() {
                if i < deltas.count {
                    let v = deltas[i]
                    let absV = Swift.abs(v)
                    let formatted = absV.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(absV))
                        : String(format: "%.2f", absV)
                    if v > 0 {
                        col.text      = "+\(formatted)"
                        col.textColor = .systemGreen
                    } else if v < 0 {
                        col.text      = "−\(formatted)"
                        col.textColor = .systemRed
                    } else {
                        col.text      = "0"
                        col.textColor = .secondaryLabel
                    }
                } else {
                    col.text      = ""
                    col.textColor = .tertiaryLabel
                }
            }
        } else {
            moneyRow.isHidden = true
        }
    }
}
