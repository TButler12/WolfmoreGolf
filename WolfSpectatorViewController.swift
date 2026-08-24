import UIKit

final class WolfSpectatorViewController: UIViewController {

    // MARK: - External input
    var sessionCode: String = ""
    var isEmbedded: Bool = false

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
    private let tabContainerView = UIView()
    private let tabRow1          = UIStackView()   // sessions 0-4
    private let tabRow2          = UIStackView()   // sessions 5-9
    private var tabContainerHeightConstraint: NSLayoutConstraint?
    private var tabButtons: [UIButton] = []
    private var addSessionBarButton: UIBarButtonItem?
    private var embeddedToolbar: UIToolbar?
    private var embeddedAddButton: UIBarButtonItem?
    private var tabTopToSafeArea: NSLayoutConstraint?
    private var tabTopToToolbar: NSLayoutConstraint?
    private let statusBanner     = UILabel()

    private let namesHeaderView  = UIView()
    private let cachedHeaderCell = WolfHoleCell(style: .default, reuseIdentifier: nil)
    private let tableView        = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingView      = UIActivityIndicatorView(style: .large)

    private let savedCodesKey = "watchedWolfSessions"
    private let maxSessions   = 10

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Match"
        navigationItem.prompt = "Long-press a tab to remove it"
        view.backgroundColor = .systemBackground
        setupTabBar()
        setupStatusBanner()
        setupNamesHeader()
        setupTableView()
        setupLoadingView()
        setupEmbeddedToolbar()
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
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addSessionTapped)
        )
        addSessionBarButton = addButton
        navigationItem.rightBarButtonItems = [trashButton, refreshButton, addButton]
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
        tabContainerView.translatesAutoresizingMaskIntoConstraints = false
        tabContainerView.backgroundColor = .systemBackground
        view.addSubview(tabContainerView)

        let hConstraint = tabContainerView.heightAnchor.constraint(equalToConstant: 44)
        tabContainerHeightConstraint = hConstraint
        let topC = tabContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        tabTopToSafeArea = topC
        NSLayoutConstraint.activate([
            topC,
            tabContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hConstraint,
        ])

        func configureRow(_ row: UIStackView) {
            row.axis         = .horizontal
            row.spacing      = 6
            row.alignment    = .fill
            row.distribution = .fillEqually
            row.translatesAutoresizingMaskIntoConstraints = false
            tabContainerView.addSubview(row)
        }
        configureRow(tabRow1)
        configureRow(tabRow2)
        tabRow2.isHidden = true

        NSLayoutConstraint.activate([
            tabRow1.topAnchor.constraint(equalTo: tabContainerView.topAnchor, constant: 6),
            tabRow1.leadingAnchor.constraint(equalTo: tabContainerView.leadingAnchor, constant: 12),
            tabRow1.trailingAnchor.constraint(equalTo: tabContainerView.trailingAnchor, constant: -12),
            tabRow1.heightAnchor.constraint(equalToConstant: 32),

            tabRow2.topAnchor.constraint(equalTo: tabRow1.bottomAnchor, constant: 6),
            tabRow2.leadingAnchor.constraint(equalTo: tabContainerView.leadingAnchor, constant: 12),
            tabRow2.trailingAnchor.constraint(equalTo: tabContainerView.trailingAnchor, constant: -12),
            tabRow2.heightAnchor.constraint(equalToConstant: 32),
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
            statusBanner.topAnchor.constraint(equalTo: tabContainerView.bottomAnchor),
            statusBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBanner.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    private func setupNamesHeader() {
        namesHeaderView.translatesAutoresizingMaskIntoConstraints = false
        namesHeaderView.backgroundColor = .systemGroupedBackground
        namesHeaderView.isHidden = true
        view.addSubview(namesHeaderView)
        NSLayoutConstraint.activate([
            namesHeaderView.topAnchor.constraint(equalTo: statusBanner.bottomAnchor),
            namesHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            namesHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            namesHeaderView.heightAnchor.constraint(equalToConstant: 44),
        ])

        cachedHeaderCell.translatesAutoresizingMaskIntoConstraints = false
        cachedHeaderCell.backgroundColor = .systemGroupedBackground
        namesHeaderView.addSubview(cachedHeaderCell)
        NSLayoutConstraint.activate([
            cachedHeaderCell.topAnchor.constraint(equalTo: namesHeaderView.topAnchor),
            cachedHeaderCell.leadingAnchor.constraint(equalTo: namesHeaderView.leadingAnchor),
            cachedHeaderCell.trailingAnchor.constraint(equalTo: namesHeaderView.trailingAnchor),
            cachedHeaderCell.bottomAnchor.constraint(equalTo: namesHeaderView.bottomAnchor),
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(WolfHoleCell.self, forCellReuseIdentifier: WolfHoleCell.reuseID)
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.contentInset          = UIEdgeInsets(top: 0, left: 0, bottom: 83, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 83, right: 0)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: namesHeaderView.bottomAnchor),
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

    private func setupEmbeddedToolbar() {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.isHidden = true
        view.addSubview(toolbar)

        let trash = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain,
                                    target: self, action: #selector(clearAllTapped))
        trash.tintColor = .systemRed
        let refresh = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain,
                                      target: self, action: #selector(refreshTapped))
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSessionTapped))
        embeddedAddButton = add
        toolbar.items = [add, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), refresh, trash]

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        tabTopToToolbar = tabContainerView.topAnchor.constraint(equalTo: toolbar.bottomAnchor)
        embeddedToolbar = toolbar
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent != nil { applyEmbeddedLayout() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyEmbeddedLayout()
    }

    private func applyEmbeddedLayout() {
        embeddedToolbar?.isHidden = !isEmbedded
        if isEmbedded {
            tabTopToSafeArea?.isActive = false
            tabTopToToolbar?.isActive = true
        } else {
            tabTopToToolbar?.isActive = false
            tabTopToSafeArea?.isActive = true
        }
        if isEmbedded { embeddedToolbar.map { view.bringSubviewToFront($0) } }
    }

    // MARK: - Tab bar

    private func rebuildTabBar() {
        for row in [tabRow1, tabRow2] {
            row.arrangedSubviews.forEach { row.removeArrangedSubview($0); $0.removeFromSuperview() }
        }
        tabButtons = []

        for (i, session) in sessions.enumerated() {
            let btn = makeTabButton(code: session.code, index: i)
            tabButtons.append(btn)
            if i < 5 { tabRow1.addArrangedSubview(btn) }
            else      { tabRow2.addArrangedSubview(btn) }
        }

        let needsRow2 = sessions.count > 5
        tabRow2.isHidden = !needsRow2
        // 6 + 6 (top/row gaps) + 32 (row1) + 6 (gap) + 32 (row2) + 6 (bottom) = 88
        let newH: CGFloat = needsRow2 ? 88 : 44
        if tabContainerHeightConstraint?.constant != newH {
            tabContainerHeightConstraint?.constant = newH
            UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        }

        addSessionBarButton?.isEnabled = sessions.count < maxSessions
        embeddedAddButton?.isEnabled   = sessions.count < maxSessions

        updateTabHighlight()
    }

    private func makeTabButton(code: String, index: Int) -> UIButton {
        var cfg = UIButton.Configuration.filled()
        cfg.title = code
        cfg.cornerStyle = .capsule
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        cfg.baseBackgroundColor = .systemGray5
        cfg.baseForegroundColor = .label
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
            return out
        }
        let btn = UIButton(configuration: cfg)
        btn.tag = index
        btn.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        let lp = UILongPressGestureRecognizer(target: self, action: #selector(tabLongPressed(_:)))
        btn.addGestureRecognizer(lp)
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
        let isMP = currentHoleResults.values.contains { $0.decision == "matchplay" }
        cachedHeaderCell.configureAsHeader(playerNames: session.playerNames, isMatchPlay: isMP)
        namesHeaderView.isHidden = false
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
                let isMP = self.currentHoleResults.values.contains { $0.decision == "matchplay" }
                if let sess = self.currentSession {
                    self.cachedHeaderCell.configureAsHeader(playerNames: sess.playerNames, isMatchPlay: isMP)
                }
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
            message: "Stop watching all \(sessions.count) live game(s).\n\nTip: Long-press a single tab to remove just that session.",
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

    /// Total holes to display for the current session.
    /// Rounds the max hole seen in results up to the nearest multiple of 18,
    /// so a 36-hole match shows 36 rows as soon as hole 19 data arrives.
    private var totalHolesForCurrentSession: Int {
        let allResults = Array(currentHoleResults.values)
        let isMatchPlay = allResults.contains { $0.decision == "matchplay" }
        guard let maxHole = currentHoleResults.keys.max() else {
            return isMatchPlay ? 36 : STANDARD_HOLES
        }
        let fromData = ((maxHole + STANDARD_HOLES - 1) / STANDARD_HOLES) * STANDARD_HOLES
        // Match play sessions always list all 36 holes
        return isMatchPlay ? max(36, fromData) : fromData
    }

    private var summaryRowCount: Int { totalHolesForCurrentSession == 36 ? 7 : 4 }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (currentSession?.playerNames.count ?? 0) > 0 ? totalHolesForCurrentSession + summaryRowCount : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WolfHoleCell.reuseID, for: indexPath) as! WolfHoleCell
        guard let session = currentSession else { return cell }
        let allResults = Array(currentHoleResults.values)
        let isMatchPlay = allResults.contains { $0.decision == "matchplay" }
        let totalHoles = totalHolesForCurrentSession
        let is36 = totalHoles == 36
        let pc = session.playerNames.count
        let summaryBase = totalHoles
        let summaryRow = indexPath.row - summaryBase

        if summaryRow >= 0 {
            if is36 {
                switch summaryRow {
                case 0: cell.configureAsScoreSubtotal(label: "F9",     holes: 1...9,  results: allResults, playerCount: pc)
                case 1: cell.configureAsScoreSubtotal(label: "1st 18", holes: 1...18, results: allResults, playerCount: pc)
                case 2: cell.configureAsScoreSubtotal(label: "2nd F9", holes: 19...27, results: allResults, playerCount: pc)
                case 3: cell.configureAsScoreSubtotal(label: "2nd 18", holes: 19...36, results: allResults, playerCount: pc)
                case 4: cell.configureAsScoreTotals(results: allResults, playerCount: pc)
                case 5:
                    if isMatchPlay { cell.configureAsMatchPlayTotals(results: allResults, playerCount: pc) }
                    else           { cell.configureAsTotals(results: allResults, playerCount: pc) }
                case 6: cell.configureAsSkinsTotals(results: allResults, playerNames: session.playerNames)
                default: break
                }
            } else {
                switch summaryRow {
                case 0: cell.configureAsScoreSubtotal(label: "F9",    holes: 1...9,  results: allResults, playerCount: pc)
                case 1: cell.configureAsScoreTotals(results: allResults, playerCount: pc)
                case 2:
                    if isMatchPlay { cell.configureAsMatchPlayTotals(results: allResults, playerCount: pc) }
                    else           { cell.configureAsTotals(results: allResults, playerCount: pc) }
                case 3: cell.configureAsSkinsTotals(results: allResults, playerNames: session.playerNames)
                default: break
                }
            }
            return cell
        }

        // Hole rows
        let hole = indexPath.row + 1  // 1-based
        if hole < 1 { return cell }
        do {
            let playerCount = session.playerNames.count
            var cumulative = Array(repeating: 0.0, count: playerCount)
            for h in 1...hole {
                guard let r = currentHoleResults[h] else { continue }
                let deltas = r.moneyDeltas ?? r.payouts ?? []
                for (i, v) in deltas.enumerated() where i < playerCount { cumulative[i] += v }
            }
            let hasCumulative = currentHoleResults[hole] != nil

            // Running match score for match play (from Team A / wolfSlot perspective)
            var matchStatus: String? = nil
            if isMatchPlay {
                var teamAWins = 0, teamBWins = 0
                for h in 1...hole {
                    guard let r = currentHoleResults[h] else { continue }
                    if let ws = r.wolfSlot, let deltas = r.moneyDeltas ?? r.payouts, ws < deltas.count {
                        let p = deltas[ws]
                        if p > 0.001 { teamAWins += 1 } else if p < -0.001 { teamBWins += 1 }
                    } else if let tw = r.teamWon {
                        if tw { teamAWins += 1 } else { teamBWins += 1 }
                    }
                }
                let diff = teamAWins - teamBWins
                if diff == 0        { matchStatus = "AS" }
                else if diff > 0    { matchStatus = "A \(diff)↑" }
                else                { matchStatus = "B \(abs(diff))↑" }
            }

            cell.configure(hole: hole, result: currentHoleResults[hole], playerNames: session.playerNames,
                           cumulativeTotals: hasCumulative ? cumulative : [],
                           matchStatus: matchStatus)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { nil }
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

    private let gameLabel  = UILabel()
    private var gameCols: [UILabel] = []
    private let gameRow    = UIStackView()

    private let skinsLabel = UILabel()
    private var skinsCols: [UILabel] = []
    private let skinsRow   = UIStackView()

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

        // Game dollars sub-row (running cumulative total through this hole)
        gameRow.axis     = .horizontal
        gameRow.spacing  = 6
        gameRow.isHidden = true
        outerStack.addArrangedSubview(gameRow)

        configLabel(gameLabel, size: 13, weight: .regular, width: 32)
        gameLabel.text      = "G$"
        gameLabel.textColor = .secondaryLabel
        gameRow.addArrangedSubview(gameLabel)

        let gameDecisionSpacer = UIView()
        gameDecisionSpacer.widthAnchor.constraint(equalToConstant: 30).isActive = true
        gameRow.addArrangedSubview(gameDecisionSpacer)

        for _ in 0..<MAX_PLAYERS {
            let l = UILabel()
            configLabel(l, size: 13, weight: .semibold, width: 40)
            gameCols.append(l)
            gameRow.addArrangedSubview(l)
        }

        let spacer3 = UIView()
        spacer3.setContentHuggingPriority(.defaultLow, for: .horizontal)
        gameRow.addArrangedSubview(spacer3)

        // Skins sub-row: "{N}S" for winner, "C" for tied carryover players
        skinsRow.axis     = .horizontal
        skinsRow.spacing  = 6
        skinsRow.isHidden = true
        outerStack.addArrangedSubview(skinsRow)

        configLabel(skinsLabel, size: 13, weight: .regular, width: 32)
        skinsLabel.text      = "SK"
        skinsLabel.textColor = .secondaryLabel
        skinsRow.addArrangedSubview(skinsLabel)

        let skinsDecisionSpacer = UIView()
        skinsDecisionSpacer.widthAnchor.constraint(equalToConstant: 30).isActive = true
        skinsRow.addArrangedSubview(skinsDecisionSpacer)

        for _ in 0..<MAX_PLAYERS {
            let l = UILabel()
            configLabel(l, size: 13, weight: .semibold, width: 40)
            skinsCols.append(l)
            skinsRow.addArrangedSubview(l)
        }

        let spacer4 = UIView()
        spacer4.setContentHuggingPriority(.defaultLow, for: .horizontal)
        skinsRow.addArrangedSubview(spacer4)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configLabel(_ l: UILabel, size: CGFloat, weight: UIFont.Weight, width: CGFloat) {
        l.font      = .systemFont(ofSize: size, weight: weight)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.lineBreakMode = .byClipping
        l.numberOfLines = 1
        l.widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    func configureAsHeader(playerNames: [String], isMatchPlay: Bool = false) {
        holePressLevel = 0
        holeLabel.text        = "Hole"
        holeLabel.textColor   = .secondaryLabel
        decisionLabel.text    = isMatchPlay ? "MP" : ""
        decisionLabel.textColor = .secondaryLabel
        decisionLabel.font    = .systemFont(ofSize: 10, weight: .semibold)

        let labels = Self.deduplicatedDisplayNames(playerNames)
        for (i, col) in scoreCols.enumerated() {
            col.text                    = i < labels.count ? labels[i] : ""
            col.textColor               = .label
            col.font                    = .systemFont(ofSize: 11, weight: .bold)
            col.adjustsFontSizeToFitWidth = true
            col.minimumScaleFactor      = 0.7
            col.lineBreakMode           = .byClipping
        }
        moneyRow.isHidden  = true
        gameRow.isHidden   = true
        skinsRow.isHidden  = true
    }

    /// Returns the shortest display label per player that keeps every entry unique.
    /// Pass 1: first name up to 8 chars ("Michael")
    /// Pass 2: if duplicates, append last-name initial ("Tom B")
    /// Pass 3: if still duplicates, append first 3 of last name ("Tom But")
    static func deduplicatedDisplayNames(_ names: [String]) -> [String] {
        func parts(_ raw: String) -> (first: String, last: String) {
            let tokens = raw.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
            let first = tokens.first ?? ""
            let last  = tokens.count > 1 ? tokens.last! : ""
            return (first, last)
        }

        // Pass 1 — first name, max 8
        var result = names.map { String(parts($0).first.prefix(8)) }
        guard result.count != Set(result).count else { return result }

        // Pass 2 — first name + last initial ("Tom B")
        result = names.map { raw in
            let (first, last) = parts(raw)
            let f = String(first.prefix(8))
            guard let li = last.first else { return f }
            return "\(f) \(li)"
        }
        guard result.count != Set(result).count else { return result }

        // Pass 3 — first name + first 3 of last ("Tom But")
        result = names.map { raw in
            let (first, last) = parts(raw)
            let f = String(first.prefix(8))
            let l = String(last.prefix(3))
            return l.isEmpty ? f : "\(f) \(l)"
        }
        return result
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
        gameRow.isHidden  = true
        skinsRow.isHidden = true
    }

    func configureAsScoreSubtotal(label: String, holes: ClosedRange<Int>, results: [WolfHoleResult], playerCount: Int) {
        holePressLevel = 0
        holeLabel.text      = label
        holeLabel.textColor = .secondaryLabel
        holeLabel.font      = .systemFont(ofSize: 13, weight: .semibold)
        decisionLabel.text  = ""

        var totals = Array(repeating: 0, count: playerCount)
        for result in results where holes.contains(result.hole) {
            guard let scores = result.scores else { continue }
            for (i, s) in scores.enumerated() where i < playerCount { totals[i] += s }
        }

        for (i, col) in scoreCols.enumerated() {
            guard i < playerCount else { col.text = ""; continue }
            col.font      = .systemFont(ofSize: 14, weight: .semibold)
            col.text      = totals[i] > 0 ? "\(totals[i])" : "—"
            col.textColor = .secondaryLabel
        }
        moneyRow.isHidden = true
        gameRow.isHidden  = true
        skinsRow.isHidden = true
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
        gameRow.isHidden  = true
        skinsRow.isHidden = true
    }

    func configureAsSkinsTotals(results: [WolfHoleResult], playerNames: [String]) {
        holePressLevel = 0
        holeLabel.text      = "SK"
        holeLabel.textColor = .systemYellow
        holeLabel.font      = .systemFont(ofSize: 13, weight: .semibold)
        moneyRow.isHidden   = true
        gameRow.isHidden    = true
        skinsRow.isHidden   = true

        // Replay the pot to show current carryover count (sorted so multi-round games work)
        var currentPot = 1
        for r in results.sorted(by: { $0.hole < $1.hole }) {
            if r.skinWinner != nil {
                currentPot = 1
            } else if r.skinTiedSeats != nil {
                currentPot += 1
            }
        }
        decisionLabel.text      = currentPot > 1 ? "\(currentPot)C" : ""
        decisionLabel.textColor = .systemYellow
        decisionLabel.font      = .systemFont(ofSize: 11, weight: .bold)

        // Tally skins won per player — use trimmed case-insensitive matching for robustness
        var skinsPerPlayer = Array(repeating: 0, count: playerNames.count)
        for r in results {
            guard let raw = r.skinWinner else { continue }
            let winner = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let idx = playerNames.firstIndex(where: {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == winner
            }) {
                skinsPerPlayer[idx] += r.skinCount ?? 1
            }
        }

        let playerCount = playerNames.count
        for (i, col) in scoreCols.enumerated() {
            guard i < playerCount else { col.text = ""; continue }
            let total = skinsPerPlayer[i]
            col.font = .systemFont(ofSize: 13, weight: total > 0 ? .bold : .regular)
            if total > 0 {
                col.text      = "\(total)S"
                col.textColor = .systemYellow
            } else {
                col.text      = "—"
                col.textColor = .secondaryLabel
            }
        }
    }

    func configureAsMatchPlayTotals(results: [WolfHoleResult], playerCount: Int) {
        holePressLevel = 0
        holeLabel.text      = "Match"
        holeLabel.textColor = .secondaryLabel
        holeLabel.font      = .systemFont(ofSize: 13, weight: .semibold)
        moneyRow.isHidden   = true
        gameRow.isHidden    = true
        skinsRow.isHidden   = true
        decisionLabel.text  = ""

        // Tally each player's match result from their own moneyDeltas.
        // This works for both single match and dual simultaneous matches: a positive
        // delta means that player won their hole, negative means they lost.
        var wins  = Array(repeating: 0, count: playerCount)
        var losses = Array(repeating: 0, count: playerCount)
        for r in results {
            guard let deltas = r.moneyDeltas ?? r.payouts else {
                // Fall back to teamWon flag for older results that lack per-player deltas
                if let tw = r.teamWon, let ws = r.wolfSlot, ws < playerCount {
                    if tw { wins[ws] += 1 } else { losses[ws] += 1 }
                }
                continue
            }
            for (i, d) in deltas.enumerated() where i < playerCount {
                if d > 0.001 { wins[i] += 1 } else if d < -0.001 { losses[i] += 1 }
            }
        }

        for (i, col) in scoreCols.enumerated() {
            guard i < playerCount else { col.text = ""; continue }
            let diff = wins[i] - losses[i]
            col.font = .systemFont(ofSize: 13, weight: .bold)
            if diff == 0 {
                col.text      = "AS"
                col.textColor = .secondaryLabel
            } else if diff > 0 {
                col.text      = "↑\(diff)"
                col.textColor = .systemGreen
            } else {
                col.text      = "↓\(abs(diff))"
                col.textColor = .systemRed
            }
        }
    }

    func configure(hole: Int, result: WolfHoleResult?, playerNames: [String], cumulativeTotals: [Double] = [],
                   matchStatus: String? = nil) {
        holePressLevel       = result?.wolfPlayer ?? 0
        holeLabel.text       = "\(hole)"
        holeLabel.textColor  = holePressLevel > 0 ? .systemOrange : .label

        // Match play: show running score in decision column (e.g. "A 2↑", "AS", "B 1↑")
        if let ms = matchStatus {
            decisionLabel.text      = ms
            decisionLabel.font      = .systemFont(ofSize: 10, weight: .bold)
            decisionLabel.textColor = ms == "AS" ? .secondaryLabel : .systemGreen
        } else {
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
        decisionLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        }

        // Match play: scores only + match status; no $ / G$ / SK rows
        if matchStatus != nil {
            let deltas = result?.moneyDeltas ?? result?.payouts ?? []
            for (i, col) in scoreCols.enumerated() {
                col.font = .systemFont(ofSize: 16, weight: .semibold)
                if let r = result, let scores = r.scores, i < scores.count, scores[i] > 0 {
                    col.text = "\(scores[i])"
                    let delta = i < deltas.count ? deltas[i] : 0.0
                    if delta > 0.001      { col.textColor = .systemGreen }
                    else if delta < -0.001 { col.textColor = .systemRed }
                    else                  { col.textColor = .label }
                } else {
                    col.text      = "—"
                    col.textColor = .tertiaryLabel
                }
            }
            moneyRow.isHidden = true
            gameRow.isHidden  = true
            skinsRow.isHidden = true
            return
        }

        let wolfSlot    = result?.wolfSlot
        let partnerSlot = result?.partnerSlot

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

        // Money sub-row: show whenever a hole result exists (display 0 for zero deltas)
        if let deltas = result?.moneyDeltas ?? result?.payouts {
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

        // Game dollars sub-row: running cumulative total through this hole
        if !cumulativeTotals.isEmpty {
            gameRow.isHidden = false
            for (i, col) in gameCols.enumerated() {
                guard i < cumulativeTotals.count else { col.text = ""; col.textColor = .tertiaryLabel; continue }
                let v = cumulativeTotals[i]
                let absV = Swift.abs(v)
                let formatted = absV.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(absV))
                    : String(format: "%.2f", absV)
                if v > 0      { col.text = "+\(formatted)"; col.textColor = .systemGreen }
                else if v < 0 { col.text = "−\(formatted)"; col.textColor = .systemRed }
                else          { col.text = "0";              col.textColor = .secondaryLabel }
            }
        } else {
            gameRow.isHidden = true
        }

        // Skins sub-row: "{N}S" for winner, "C" for tied-carryover players, blank otherwise
        let skinWinner = result?.skinWinner
        let skinCount  = result?.skinCount ?? 1
        let tiedSeats: Set<Int> = {
            guard let raw = result?.skinTiedSeats else { return [] }
            return Set(raw.split(separator: ",").compactMap { Int($0) })
        }()
        let hasSkinActivity = skinWinner != nil || !tiedSeats.isEmpty
        if hasSkinActivity {
            skinsRow.isHidden = false
            for (i, col) in skinsCols.enumerated() {
                let playerName = i < playerNames.count ? playerNames[i] : nil
                if let winner = skinWinner?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                   let name = playerName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                   winner == name {
                    col.text      = "\(skinCount)S"
                    col.textColor = .systemYellow
                } else if tiedSeats.contains(i) {
                    col.text      = "C"
                    col.textColor = .secondaryLabel
                } else {
                    col.text      = ""
                    col.textColor = .tertiaryLabel
                }
            }
        } else {
            skinsRow.isHidden = true
        }
    }
}

// MARK: - UITableViewDelegate

extension WolfSpectatorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }
}

