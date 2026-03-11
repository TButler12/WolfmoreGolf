

//  GameStatsViewController: UIViewController.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 10/18/25.
//

import UIKit
import MessageUI

final class GameStatsViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    // MARK: - Types

    enum SortKey { case name, score, money, prox }

    private struct Row {
        let seat: Int
        let name: String
        let front9Score: Int
        let totalScore: Int
        let totalMoney: Double
        let proxCount: Int
    }

    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let header = HeaderView()

    private let panel = UIView()
    private let closeBtn = UIButton(type: .system)
    private let sendBtn = UIButton(type: .system)
    private let historyBtn = UIButton(type: .system)

    // MARK: - State

    private var rows: [Row] = []
    private var sortKey: SortKey = .score
    private var ascending = false

    private var hasSavedThisOpen = false

    // Money (no cents)
    private let currency0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        nf.roundingMode = .halfUp
        return nf
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        setupPanel()
        setupHeader()
        setupDismissTap()
        setupObservers()

        reloadFromModel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupPanel() {
        panel.backgroundColor = .systemBackground
        panel.layer.cornerRadius = 16
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)

        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            panel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            panel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
        ])

        closeBtn.setTitle("Close", for: .normal)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(closeBtn)

        sendBtn.setTitle("Send Round Summary", for: .normal)
        sendBtn.setTitleColor(.white, for: .normal)
        sendBtn.backgroundColor = .systemGreen
        sendBtn.layer.cornerRadius = 14
        sendBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        sendBtn.addTarget(self, action: #selector(sendSummaryTapped(_:)), for: .touchUpInside)
        sendBtn.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(sendBtn)

        historyBtn.setTitle("Save to History", for: .normal)
        historyBtn.setTitleColor(.white, for: .normal)
        historyBtn.backgroundColor = .systemIndigo
        historyBtn.layer.cornerRadius = 14
        historyBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        historyBtn.addTarget(self, action: #selector(saveToHistoryTapped(_:)), for: .touchUpInside)
        historyBtn.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(historyBtn)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 52
        tableView.separatorInset = .zero
        tableView.register(StatsCell.self, forCellReuseIdentifier: StatsCell.reuseID)
        panel.addSubview(tableView)

        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: panel.topAnchor, constant: 8),
            closeBtn.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -8),

            historyBtn.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            historyBtn.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            historyBtn.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -14),
            historyBtn.heightAnchor.constraint(equalToConstant: 52),

            sendBtn.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            sendBtn.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            sendBtn.bottomAnchor.constraint(equalTo: historyBtn.topAnchor, constant: -10),
            sendBtn.heightAnchor.constraint(equalToConstant: 52),

            tableView.topAnchor.constraint(equalTo: closeBtn.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: sendBtn.topAnchor, constant: -10),
        ])
    }

    private func setupHeader() {
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
        tableView.tableHeaderView = header

        header.onTapName  = { [weak self] in self?.setSort(.name)  }
        header.onTapScore = { [weak self] in self?.setSort(.score) }
        header.onTapMoney = { [weak self] in self?.setSort(.money) }
        header.onTapProx  = { [weak self] in self?.setSort(.prox)  }
    }

    private func setupDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(bgTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadFromModel),
            name: .reloadUI,
            object: nil
        )
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func bgTapped(_ gr: UITapGestureRecognizer) {
        let loc = gr.location(in: view)
        if !panel.frame.contains(loc) {
            dismiss(animated: true)
        }
    }

    @objc private func saveToHistoryTapped(_ sender: UIButton) {
        guard !hasSavedThisOpen else {
            showAlert("Already Saved", "This round is already in History.")
            return
        }

        let ac = UIAlertController(
            title: "Save Round to History?",
            message: "This will save stats for you and any tracked friends on this card.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "No", style: .cancel))

        ac.addAction(UIAlertAction(title: "Yes, Save", style: .default) { [weak self] _ in
            guard let self else { return }

            self.recordMeAndTrackedFriendsFromCurrentGame()

            self.hasSavedThisOpen = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            sender.isEnabled = false
            sender.alpha = 0.7
            sender.setTitle("Saved ✓", for: .disabled)
        })

        present(ac, animated: true)
    }

    @objc private func sendSummaryTapped(_ sender: UIButton) {
        guard MFMessageComposeViewController.canSendText() else {
            showAlert("Messages Unavailable", "This device can’t send text messages.")
            return
        }

        let body = buildRoundSummaryText()

        let ac = UIAlertController(title: "Send Summary", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Today’s Group", style: .default) { [weak self] _ in
            guard let self else { return }
            let recipients = FriendStore.shared.friends
                .filter { $0.preselectForRound }
                .map { $0.phone.filter(\.isNumber) }
                .filter { !$0.isEmpty }

            guard !recipients.isEmpty else {
                self.showAlert("No Group Selected", "Activate players (Today’s Group) first.")
                return
            }

            self.presentComposer(recipients: recipients, body: body)
        })

        ac.addAction(UIAlertAction(title: "Pro Shop", style: .default) { [weak self] _ in
            guard let self else { return }
            let pro = ServiceContactStore.shared.contacts.proShop.filter(\.isNumber)
            guard !pro.isEmpty else {
                self.showAlert("No Pro Shop Number", "Add a Pro Shop number first.")
                return
            }
            self.presentComposer(recipients: [pro], body: body)
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(ac, animated: true)
    }

    // MARK: - Summary Text

    private func buildRoundSummaryText() -> String {
        // Message: money high -> low
        let sorted = rows.sorted { $0.totalMoney > $1.totalMoney }

        func moneyString(_ v: Double) -> String {
            let i = Int(v.rounded())
            let sign = i > 0 ? "+" : ""
            return "\(sign)$\(i)"
        }

        var lines: [String] = []
        lines.append("WolfMore Round Summary")
        lines.append("")

        for r in sorted {
            lines.append("\(r.name): \(moneyString(r.totalMoney)) • \(r.totalScore) • Prox \(r.proxCount)")
        }

        lines.append("")
        lines.append("Sent from WolfMore")

        return lines.joined(separator: "\n")
    }

    private func presentComposer(recipients: [String], body: String) {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = self
        vc.recipients = recipients
        vc.body = body
        present(vc, animated: true)
    }

    // MARK: - MFMessageComposeViewControllerDelegate

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                     didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }

    // MARK: - Save Helpers

    private func recordMeAndTrackedFriendsFromCurrentGame() {
        guard let g = GameManager.shared.currentGame else { return }

        var namesToSave = Set<String>()

        let me = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !me.isEmpty { namesToSave.insert(me) }

        let trackingCourseID = ProfileStore.homeCourseID.isEmpty ? "HOME-COURSE" : ProfileStore.homeCourseID

        let trackedFriendNames = FriendStore.shared.friends
            .filter { FriendTrackStore.shared.isTracked($0.id, on: trackingCourseID) }
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let seats = 0..<min(5, min(g.playerNames.count, g.playerActivated.count))
        for i in seats where g.playerActivated[i] {
            let seatName = g.playerNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if trackedFriendNames.contains(where: { $0.caseInsensitiveCompare(seatName) == .orderedSame }) {
                namesToSave.insert(seatName)
            }
        }

        let sharedGameID = UUID()
        let sharedDate = Date()

        for name in namesToSave {
            _ = RoundStore.shared.recordFromCurrentGame(
                playerNameOverride: name,
                gameID: sharedGameID,
                date: sharedDate
            )
        }
    }

    // MARK: - Data

    @objc private func reloadFromModel() {
        guard let g = GameManager.shared.currentGame else {
            rows = []
            tableView.reloadData()
            return
        }

        let names = g.playerNames
        let actives = g.playerActivated
        let seats = min(names.count, actives.count)

        var built: [Row] = []
        for seat in 0..<seats {
            let name = names[seat].trimmingCharacters(in: .whitespacesAndNewlines)
            guard actives[seat], !name.isEmpty else { continue }

            let total = totalScoreForSeat(seat, in: g) ?? 0
            let front9 = front9ScoreForSeat(seat, in: g) ?? 0
            let money = totalMoneyForSeat(seat, in: g)
            let prox  = proxWinsForSeat(seat, in: g)

            built.append(Row(seat: seat, name: name, front9Score: front9, totalScore: total, totalMoney: money, proxCount: prox))
        }

        rows = built
        applySortAndReload()
    }

    private func totalScoreForSeat(_ seat: Int, in g: GameData) -> Int? {
        var sum = 0, haveAny = false

        if seat < g.scores.count, let first = g.scores.first, first.count == 18 {
            let holes = 0..<min(18, g.scores[seat].count)
            for h in holes {
                if let v = g.scores[seat][h] { sum += v; haveAny = true }
            }
            return haveAny ? sum : nil
        }

        if g.scores.count == 18 {
            for h in 0..<18 {
                let row = g.scores[h]
                if seat < row.count, let v = row[seat] { sum += v; haveAny = true }
            }
            return haveAny ? sum : nil
        }
        return nil
    }

    private func front9ScoreForSeat(_ seat: Int, in g: GameData) -> Int? {
        var sum = 0, haveAny = false

        if seat < g.scores.count, let first = g.scores.first, first.count == 18 {
            let holes = 0..<min(9, g.scores[seat].count)
            for h in holes {
                if let v = g.scores[seat][h] { sum += v; haveAny = true }
            }
            return haveAny ? sum : nil
        }

        if g.scores.count == 18 {
            let maxHole = min(9, g.scores.count)
            for h in 0..<maxHole {
                let row = g.scores[h]
                if seat < row.count, let v = row[seat] { sum += v; haveAny = true }
            }
            return haveAny ? sum : nil
        }
        return nil
    }

    private func totalMoneyForSeat(_ seat: Int, in g: GameData) -> Double {
        guard !g.playerMoney.isEmpty else { return 0 }
        guard seat < g.playerMoney.count else { return 0 }
        let holes = g.playerMoney[seat]
        return holes.prefix(min(18, holes.count)).reduce(0, +)
    }

    private func proxWinsForSeat(_ seat: Int, in g: GameData) -> Int {
        let winners = g.proxWinnerPerHole.map { $0 ?? -1 }
        let upto18 = min(18, winners.count)
        var c = 0
        for h in 0..<upto18 where winners[h] == seat { c += 1 }
        return c
    }

    // MARK: - Sorting

    private func setSort(_ key: SortKey) {
        if sortKey == key {
            ascending.toggle()
        } else {
            sortKey = key
            ascending = (key == .name)
        }
        applySortAndReload()
    }

    private func applySortAndReload() {
        let asc = ascending
        let key = sortKey

        let cmp: (Row, Row) -> Bool
        switch key {
        case .name:
            cmp = { a, b in
                asc
                    ? a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                    : a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
            }
        case .score:
            cmp = { a, b in asc ? (a.totalScore, a.name) < (b.totalScore, b.name)
                                : (a.totalScore, a.name) > (b.totalScore, b.name) }
        case .money:
            cmp = { a, b in asc ? (a.totalMoney, a.name) < (b.totalMoney, b.name)
                                : (a.totalMoney, a.name) > (b.totalMoney, b.name) }
        case .prox:
            cmp = { a, b in asc ? (a.proxCount, a.name) < (b.proxCount, b.name)
                                : (a.proxCount, a.name) > (b.proxCount, b.name) }
        }

        rows.sort(by: cmp)
        header.indicate(sortKey: key, ascending: asc)
        tableView.reloadData()
    }

    // MARK: - Alerts

    private func showAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - Header sizing

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let hv = tableView.tableHeaderView {
            let size = hv.systemLayoutSizeFitting(
                CGSize(width: tableView.bounds.width,
                       height: UIView.layoutFittingCompressedSize.height)
            )
            if hv.frame.height != size.height {
                hv.frame.size.height = size.height
                tableView.tableHeaderView = hv
            }
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension GameStatsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: StatsCell.reuseID, for: indexPath) as! StatsCell

        cell.configure(
            name: r.name,
            front9Score: r.front9Score,
            totalScore: r.totalScore,
            totalMoneyText: currency0.string(from: NSNumber(value: r.totalMoney)) ?? "\(Int(r.totalMoney.rounded()))",
            proxCount: r.proxCount,
            moneyIsNegative: r.totalMoney < 0
        )
        return cell
    }
}
// MARK: - Header

final class HeaderView: UIView {
    var onTapName:  (() -> Void)?
    var onTapScore: (() -> Void)?
    var onTapMoney: (() -> Void)?
    var onTapProx:  (() -> Void)?

    private let nameBtn   = UIButton(type: .system)
    private let front9Lbl = UILabel()
    private let scoreBtn  = UIButton(type: .system)
    private let moneyBtn  = UIButton(type: .system)
    private let proxBtn   = UIButton(type: .system)

    private let stack = UIStackView()

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .secondarySystemBackground

        [nameBtn, scoreBtn, moneyBtn, proxBtn].forEach {
            $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            $0.contentHorizontalAlignment = .center
            $0.setTitleColor(.label, for: .normal)
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }

        nameBtn.setTitle("Player ⬍", for: .normal)
        scoreBtn.setTitle("Score ⬍", for: .normal)
        moneyBtn.setTitle("Money ⬍", for: .normal)
        proxBtn.setTitle("Prox ⬍", for: .normal)

        nameBtn.addTarget(self, action: #selector(tapName),  for: .touchUpInside)
        scoreBtn.addTarget(self, action: #selector(tapScore), for: .touchUpInside)
        moneyBtn.addTarget(self, action: #selector(tapMoney), for: .touchUpInside)
        proxBtn.addTarget(self, action: #selector(tapProx),   for: .touchUpInside)

        front9Lbl.text = "Front 9"
        front9Lbl.font = .systemFont(ofSize: 14, weight: .semibold)
        front9Lbl.textAlignment = .center
        front9Lbl.heightAnchor.constraint(equalToConstant: 44).isActive = true

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        [nameBtn, front9Lbl, scoreBtn, moneyBtn, proxBtn].forEach { stack.addArrangedSubview($0) }
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func indicate(sortKey: GameStatsViewController.SortKey, ascending: Bool) {
        let arrow = ascending ? "▲" : "▼"
        nameBtn.setTitle("Player \(sortKey == .name  ? arrow : "⬍")", for: .normal)
        scoreBtn.setTitle("Score \(sortKey == .score ? arrow : "⬍")", for: .normal)
        moneyBtn.setTitle("Money \(sortKey == .money ? arrow : "⬍")", for: .normal)
        proxBtn.setTitle("Prox \(sortKey == .prox ? arrow : "⬍")", for: .normal)
    }

    @objc private func tapName()  { onTapName?()  }
    @objc private func tapScore() { onTapScore?() }
    @objc private func tapMoney() { onTapMoney?() }
    @objc private func tapProx()  { onTapProx?()  }
}


// MARK: - Cell

final class StatsCell: UITableViewCell {
    static let reuseID = "StatsCell"

    private let nameLabel   = StatsCell.makeLabel(alignment: .left, monospaced: false)
    private let front9Label = StatsCell.makeLabel()
    private let scoreLabel  = StatsCell.makeLabel(weight: .semibold)
    private let moneyLabel  = StatsCell.makeLabel(weight: .semibold)
    private let proxLabel   = StatsCell.makeLabel()

    private let stack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        selectionStyle = .none

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        contentView.addSubview(stack)

        [nameLabel, front9Label, scoreLabel, moneyLabel, proxLabel].forEach {
            stack.addArrangedSubview($0)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    func configure(
        name: String,
        front9Score: Int,
        totalScore: Int,
        totalMoneyText: String,
        proxCount: Int,
        moneyIsNegative: Bool
    ) {
        nameLabel.text   = name
        front9Label.text = "\(front9Score)"
        scoreLabel.text  = "\(totalScore)"
        moneyLabel.text  = totalMoneyText
        proxLabel.text   = "\(proxCount)"
        moneyLabel.textColor = moneyIsNegative ? .systemRed : .label
    }

    private static func makeLabel(
        alignment: NSTextAlignment = .center,
        monospaced: Bool = true,
        weight: UIFont.Weight = .regular
    ) -> UILabel {
        let l = UILabel()
        l.textAlignment = alignment
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.8
        l.font = monospaced
            ? .monospacedDigitSystemFont(ofSize: 16, weight: weight)
            : .systemFont(ofSize: 16, weight: weight)
        return l
    }
}
