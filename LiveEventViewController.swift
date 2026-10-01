import UIKit

final class LiveEventViewController: UIViewController {

    private let eventCode: String
    private var event: LiveEvent?
    private var sessions: [WolfSession] = []

    private let tableView    = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingView  = UIActivityIndicatorView(style: .large)
    private let emptyStateView = UIView()
    private var pollTimer: Timer?

    private var visibleSessions: [WolfSession] { sessions }

    // MARK: - Init

    init(eventCode: String) {
        self.eventCode = eventCode.uppercased()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = eventCode
        navigationItem.prompt = "Match Board"

        setupTableView()
        setupLoading()
        setupEmptyState()
        fetchAll()
        startPollTimer()

        SupabaseService.shared.subscribeToEventSessions(eventCode: eventCode) { [weak self] updated in
            self?.handleSessionUpdate(updated)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pollTimer?.invalidate()
        pollTimer = nil
        Task { await SupabaseService.shared.unsubscribeFromEventSessions(eventCode: eventCode) }
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "liveEventCell")
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupLoading() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        loadingView.startAnimating()
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text          = "No groups yet.\nShare this code with each group's scorer.\nThey enter it when they tap Go Live."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font          = .systemFont(ofSize: 15)
        label.textColor     = .secondaryLabel

        let shareButton = UIButton(type: .system)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setTitle("Share Code \(eventCode)", for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, shareButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis    = .vertical
        stack.spacing = 16
        stack.alignment = .center

        emptyStateView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
        ])
    }

    // MARK: - Board header

    private func buildHeaderView(name: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGroupedBackground

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text      = name
        nameLabel.font      = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0

        let codeLabel = UILabel()
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.text      = eventCode
        codeLabel.font      = .monospacedSystemFont(ofSize: 15, weight: .regular)
        codeLabel.textColor = .secondaryLabel
        codeLabel.textAlignment = .center

        let shareButton = UIButton(type: .system)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setTitle("Share Code", for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [nameLabel, codeLabel, shareButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis    = .vertical
        stack.spacing = 4
        stack.alignment = .center

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        return container
    }

    private func applyHeaderView(name: String) {
        let header = buildHeaderView(name: name)
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let size = header.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        header.frame = CGRect(origin: .zero, size: size)
        tableView.tableHeaderView = header
    }

    // MARK: - Share

    @objc private func shareTapped() {
        let boardName = event?.name ?? eventCode
        let text = "Join my match board \"\(boardName)\" — enter code \(eventCode) when you tap Go Live in WolfMore Golf."
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    // MARK: - Data

    private func fetchAll() {
        Task {
            async let eventTask    = SupabaseService.shared.fetchLiveEvent(code: eventCode)
            async let sessionsTask = SupabaseService.shared.fetchEventSessions(eventCode: eventCode)
            do {
                let (ev, sess) = try await (eventTask, sessionsTask)
                await MainActor.run {
                    self.event    = ev
                    self.title    = ev.name
                    self.sessions = sess
                    self.applyHeaderView(name: ev.name)
                    self.finishLoading()
                }
            } catch {
                await MainActor.run {
                    self.finishLoading()
                    let a = UIAlertController(title: "Match Board Not Found",
                                              message: "Check the code and try again.",
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.navigationController?.popViewController(animated: true)
                    })
                    self.present(a, animated: true)
                }
            }
        }
    }

    private func fetchSessions() {
        Task {
            guard let sess = try? await SupabaseService.shared.fetchEventSessions(eventCode: eventCode) else { return }
            await MainActor.run {
                self.sessions = sess
                self.reloadData()
            }
        }
    }

    private func finishLoading() {
        loadingView.stopAnimating()
        loadingView.isHidden = true
        reloadData()
    }

    private func reloadData() {
        emptyStateView.isHidden = !sessions.isEmpty
        tableView.reloadData()
    }

    private func handleSessionUpdate(_ updated: WolfSession) {
        if let idx = sessions.firstIndex(where: { $0.id == updated.id }) {
            sessions[idx] = updated
        } else {
            sessions.append(updated)
        }
        reloadData()
    }

    private func startPollTimer() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.fetchSessions()
        }
    }

    // MARK: - Helpers

    private func groupLabel(for session: WolfSession) -> String {
        if let name = session.groupName, !name.isEmpty {
            var counts: [String: Int] = [:]
            for s in visibleSessions {
                if let n = s.groupName { counts[n, default: 0] += 1 }
            }
            return (counts[name] ?? 0) > 1 ? "\(name) · \(session.code.prefix(3))" : name
        }
        return session.code
    }

    private func holesLabel(for session: WolfSession) -> String {
        if session.status == "archived" { return "Final" }
        let played = session.holesPlayed ?? 0
        return played > 0 ? "thru \(played)" : ""
    }
}

// MARK: - UITableViewDataSource / Delegate

extension LiveEventViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleSessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = visibleSessions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "liveEventCell", for: indexPath)

        let hasStatus = session.matchStatus != nil
        let status = session.matchStatus ?? "Not playing match play"
        let holes  = holesLabel(for: session)
        let secondary = (!hasStatus || holes.isEmpty) ? status : "\(status)  ·  \(holes)"

        var config = cell.defaultContentConfiguration()
        config.text          = groupLabel(for: session)
        config.secondaryText = secondary
        config.textProperties.font          = .systemFont(ofSize: 16, weight: .semibold)
        config.secondaryTextProperties.font = .systemFont(ofSize: 14)
        config.secondaryTextProperties.numberOfLines = 0
        config.secondaryTextProperties.color = hasStatus ? .label : .secondaryLabel
        cell.contentConfiguration  = config
        cell.accessoryType         = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let session = visibleSessions[indexPath.row]
        let vc = WolfSpectatorViewController()
        vc.sessionCode = session.code
        navigationController?.pushViewController(vc, animated: true)
    }
}
