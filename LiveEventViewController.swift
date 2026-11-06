import UIKit

final class LiveEventViewController: UIViewController {

    private let eventCode: String
    private let organizerToken: String?
    private var event: LiveEvent?
    private var sessions: [WolfSession] = []

    private let tableView    = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingView  = UIActivityIndicatorView(style: .large)
    private let emptyStateView = UIView()
    private var pollTimer: Timer?

    private var visibleSessions: [WolfSession] { sessions }

    private lazy var qrImage: UIImage? = Self.makeQRImage(from: "wolfmore://event?code=\(eventCode)")

    private static func makeQRImage(from string: String, size: CGFloat = 200) -> UIImage? {
        guard let data = string.data(using: .ascii),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let raw = filter.outputImage else { return nil }
        let scale = size / raw.extent.width
        let scaled = raw.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let bg = CIImage(color: CIColor.white).cropped(to: scaled.extent)
        let composed = scaled.composited(over: bg)
        guard let cgImage = CIContext().createCGImage(composed, from: composed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Init

    init(eventCode: String, organizerToken: String? = nil) {
        self.eventCode      = eventCode.uppercased()
        self.organizerToken = organizerToken
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = eventCode
        navigationItem.prompt = "Event Board"

        setupTableView()
        setupLoading()
        setupEmptyState()
        fetchAll()
        startPollTimer()

        SupabaseService.shared.subscribeToEventSessions(eventCode: eventCode) { [weak self] updated in
            self?.handleSessionUpdate(updated)
        }

        if organizerToken != nil {
            let trashButton = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(deleteBoardTapped)
            )
            trashButton.tintColor = .systemRed
            navigationItem.rightBarButtonItem = trashButton
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

        let qrScanLabel = UILabel()
        qrScanLabel.text      = "Scorers: scan to join"
        qrScanLabel.font      = .systemFont(ofSize: 12)
        qrScanLabel.textColor = .secondaryLabel
        qrScanLabel.textAlignment = .center

        let qrButton = UIButton(type: .custom)
        qrButton.translatesAutoresizingMaskIntoConstraints = false
        if let img = qrImage { qrButton.setImage(img, for: .normal) }
        qrButton.imageView?.contentMode = .scaleAspectFit
        qrButton.layer.borderColor = UIColor.separator.cgColor
        qrButton.layer.borderWidth = 1
        qrButton.layer.cornerRadius = 4
        qrButton.clipsToBounds = true
        qrButton.addTarget(self, action: #selector(qrTapped), for: .touchUpInside)
        qrButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        qrButton.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let shareQRButton = UIButton(type: .system)
        shareQRButton.setTitle("Share QR", for: .normal)
        shareQRButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        shareQRButton.addTarget(self, action: #selector(shareQRTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [nameLabel, codeLabel, qrScanLabel, qrButton, shareQRButton, shareButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis    = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.setCustomSpacing(12, after: codeLabel)
        stack.setCustomSpacing(8, after: qrButton)
        stack.setCustomSpacing(12, after: shareQRButton)

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
        let text = "Join our Wolfmore event board (\(eventCode))\nScorers, tap to join: wolfmore://event?code=\(eventCode)\nWatch the board: wolfmore://watch?code=\(eventCode)"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    @objc private func qrTapped() {
        guard let img = qrImage else { return }
        let vc = QRFullscreenViewController(image: img)
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true)
    }

    @objc private func shareQRTapped() {
        guard let img = qrImage else { return }
        let vc = UIActivityViewController(activityItems: [img], applicationActivities: nil)
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
                    let a = UIAlertController(title: "Event Board Not Found",
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

    // MARK: - Delete Board

    @objc private func deleteBoardTapped() {
        let name = event?.name ?? eventCode
        let ac = UIAlertController(
            title: "Delete Board?",
            message: "Delete \"\(name)\" for everyone? Scores will be lost.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDeleteBoard()
        })
        present(ac, animated: true)
    }

    private func performDeleteBoard() {
        guard let token = organizerToken else { return }
        let spinner = UIAlertController(title: nil, message: "Deleting board…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                try await SupabaseService.shared.deleteLiveEvent(code: eventCode, organizerToken: token)
                MatchBoardStore.remove(code: eventCode)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let msg = error.localizedDescription
                        // PostgREST returns "Could not find the function" when the RPC hasn't been
                        // deployed yet. Show something the user can act on instead of a raw error.
                        let friendly = msg.localizedCaseInsensitiveContains("could not find")
                            || msg.localizedCaseInsensitiveContains("does not exist")
                            ? "Board deletion isn't available right now. Please try again later."
                            : msg
                        let err = UIAlertController(title: "Delete Failed",
                                                    message: friendly,
                                                    preferredStyle: .alert)
                        err.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(err, animated: true)
                    }
                }
            }
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

    private func liveStatusLabel(for session: WolfSession) -> String {
        if session.status == "archived" { return "Final" }
        let played = session.holesPlayed ?? 0
        guard played > 0 else { return "Not started" }
        let isNineHole = session.nineHoleMatch == true
        let totalHoles = isNineHole ? 9 : 18
        if played >= totalHoles { return "Final" }
        return "Thru \(played) · Hole \(played + 1)"
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

        let hasMatchPlay = session.matchStatus != nil
        let holes  = holesLabel(for: session)
        let secondary: String
        if hasMatchPlay {
            secondary = MatchStatusFormatter.boardSecondary(status: session.matchStatus!, holes: holes)
        } else {
            secondary = liveStatusLabel(for: session)
        }

        var config = cell.defaultContentConfiguration()
        config.text          = groupLabel(for: session)
        config.secondaryText = secondary
        config.textProperties.font          = .systemFont(ofSize: 16, weight: .semibold)
        config.secondaryTextProperties.font = .systemFont(ofSize: 14)
        config.secondaryTextProperties.numberOfLines = 0
        config.secondaryTextProperties.color = hasMatchPlay ? .label : .secondaryLabel
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

private final class QRFullscreenViewController: UIViewController {
    private let qrImage: UIImage

    init(image: UIImage) {
        self.qrImage = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let iv = UIImageView(image: qrImage)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iv.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            iv.heightAnchor.constraint(equalTo: iv.widthAnchor),
        ])
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
    }

    @objc private func close() { dismiss(animated: true) }
}
