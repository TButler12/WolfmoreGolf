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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearAllTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .systemRed
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for session in sessions {
            SupabaseService.shared.unsubscribeFromWolfSession(sessionId: session.id)
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
                let results = (try? await SupabaseService.shared.fetchWolfHoleResults(sessionId: session.id)) ?? []
                print("DEBUG wolf fetch loaded: \(results.count) holes for session \(session.id)")
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
                for session in loaded { self.subscribeToSession(session) }
            }
        }
    }

    private func applyCurrentSession() {
        guard let session = currentSession else { return }
        applySessionStatus(session.status)
        tableView.reloadData()
    }

    private func subscribeToSession(_ session: WolfSession) {
        let sessionId = session.id
        print("DEBUG wolf spectator subscribing to session: \(session.id)")
        let holeCallback: (WolfHoleResult) -> Void = { [weak self] result in
            print("DEBUG wolf hole realtime received: hole=\(result.hole)")
            guard let self else { return }
            self.holeResultsBySessionId[sessionId, default: [:]][result.hole] = result
            if self.currentSession?.id == sessionId {
                self.tableView.reloadData()
            }
        }
        SupabaseService.shared.subscribeToWolfHoles(sessionId: sessionId, onResult: holeCallback)
        SupabaseService.shared.subscribeToWolfHoleUpdates(sessionId: sessionId, onResult: holeCallback)
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
        SupabaseService.shared.unsubscribeFromWolfSession(sessionId: removed.id)
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
                let results = (try? await SupabaseService.shared.fetchWolfHoleResults(sessionId: session.id)) ?? []
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
                    self.subscribeToSession(session)
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
        for session in sessions {
            SupabaseService.shared.unsubscribeFromWolfSession(sessionId: session.id)
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
        (currentSession?.playerNames.count ?? 0) > 0 ? 19 : 0   // 1 header + 18 holes
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WolfHoleCell.reuseID, for: indexPath) as! WolfHoleCell
        guard let session = currentSession else { return cell }
        if indexPath.row == 0 {
            cell.configureAsHeader(playerNames: session.playerNames)
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

    private let holeLabel  = UILabel()
    private let wolfLabel  = UILabel()
    private var scoreCols: [UILabel] = []
    private let stack      = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        stack.axis    = .horizontal
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])

        configLabel(holeLabel, size: 13, weight: .regular, width: 28)
        configLabel(wolfLabel, size: 11, weight: .regular, width: 20)
        stack.addArrangedSubview(holeLabel)
        stack.addArrangedSubview(wolfLabel)

        for _ in 0..<MAX_PLAYERS {
            let l = UILabel()
            configLabel(l, size: 13, weight: .semibold, width: 34)
            scoreCols.append(l)
            stack.addArrangedSubview(l)
        }

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(spacer)
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
        holeLabel.text      = "Hole"
        holeLabel.textColor = .secondaryLabel
        wolfLabel.text      = "W"
        wolfLabel.textColor = .secondaryLabel
        for (i, col) in scoreCols.enumerated() {
            col.text      = i < playerNames.count ? String(playerNames[i].prefix(4)) : ""
            col.textColor = .secondaryLabel
            col.font      = .systemFont(ofSize: 11, weight: .regular)
        }
    }

    func configure(hole: Int, result: WolfHoleResult?, playerNames: [String]) {
        holeLabel.text      = "\(hole)"
        holeLabel.textColor = .label

        if let r = result, let wp = r.wolfPlayer, wp < playerNames.count {
            wolfLabel.text      = String(playerNames[wp].prefix(2))
            wolfLabel.textColor = r.teamWon ? .systemGreen : .systemRed
        } else {
            wolfLabel.text      = "—"
            wolfLabel.textColor = .tertiaryLabel
        }

        let lowScore = result.map { r -> Int? in
            let active = r.scores.filter { $0 > 0 }
            return active.min()
        } ?? nil

        for (i, col) in scoreCols.enumerated() {
            col.font = .systemFont(ofSize: 13, weight: .semibold)
            if let r = result, i < r.scores.count, r.scores[i] > 0 {
                let s = r.scores[i]
                col.text      = "\(s)"
                col.textColor = (s == lowScore) ? .systemGreen : .label
            } else {
                col.text      = "—"
                col.textColor = .tertiaryLabel
            }
        }
    }
}
