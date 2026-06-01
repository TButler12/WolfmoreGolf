import UIKit

final class WolfSpectatorViewController: UIViewController {

    var sessionCode: String = ""

    private var session: WolfSession?
    private var holeResults: [Int: WolfHoleResult] = [:]   // hole → result

    private let statusBanner = UILabel()
    private let tableView    = UITableView(frame: .zero, style: .insetGrouped)
    private let loadingView  = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Match"
        view.backgroundColor = .systemBackground
        setupStatusBanner()
        setupTableView()
        setupLoadingView()
        loadSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let id = session?.id {
            SupabaseService.shared.unsubscribeFromWolfSession(sessionId: id)
        }
    }

    // MARK: - Setup

    private func setupStatusBanner() {
        statusBanner.translatesAutoresizingMaskIntoConstraints = false
        statusBanner.textAlignment  = .center
        statusBanner.font           = .systemFont(ofSize: 13, weight: .semibold)
        statusBanner.textColor      = .white
        statusBanner.backgroundColor = .systemGreen
        statusBanner.text           = "LIVE"
        statusBanner.isHidden       = true
        view.addSubview(statusBanner)
        NSLayoutConstraint.activate([
            statusBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            statusBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBanner.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(WolfHoleCell.self, forCellReuseIdentifier: WolfHoleCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
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

    // MARK: - Data loading

    private func loadSession() {
        Task {
            do {
                let fetched = try await SupabaseService.shared.fetchWolfSessionByCode(code: sessionCode)
                let results = try await SupabaseService.shared.fetchWolfHoleResults(sessionId: fetched.id)
                DispatchQueue.main.async {
                    self.session = fetched
                    for r in results { self.holeResults[r.hole] = r }
                    self.loadingView.stopAnimating()
                    self.loadingView.isHidden = true
                    self.applySessionStatus(fetched.status)
                    self.tableView.reloadData()
                    self.subscribeToUpdates(sessionId: fetched.id)
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadingView.stopAnimating()
                    self.loadingView.isHidden = true
                    self.showError(error)
                }
            }
        }
    }

    private func subscribeToUpdates(sessionId: String) {
        SupabaseService.shared.subscribeToWolfHoles(sessionId: sessionId) { [weak self] result in
            guard let self else { return }
            self.holeResults[result.hole] = result
            self.tableView.reloadData()
        }
        SupabaseService.shared.subscribeToWolfSession(sessionId: sessionId) { [weak self] updated in
            guard let self else { return }
            self.session = updated
            self.applySessionStatus(updated.status)
        }
    }

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
        (session?.playerNames.count ?? 0) > 0 ? 19 : 0   // 1 header + 18 holes
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WolfHoleCell.reuseID, for: indexPath) as! WolfHoleCell
        guard let session else { return cell }
        if indexPath.row == 0 {
            cell.configureAsHeader(playerNames: session.playerNames)
        } else {
            let hole = indexPath.row  // 1-based
            cell.configure(hole: hole, result: holeResults[hole], playerNames: session.playerNames)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let s = session else { return nil }
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
        holeLabel.text  = "Hole"
        holeLabel.textColor = .secondaryLabel
        wolfLabel.text  = "W"
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
