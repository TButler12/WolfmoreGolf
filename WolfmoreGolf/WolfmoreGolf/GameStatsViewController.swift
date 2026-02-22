

//
//  GameStatsViewController.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 10/18/25.
//

import UIKit
import MessageUI

final class GameStatsViewController: UIViewController {

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

    private let panelView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let header = HeaderView()

    private let closeBtn = UIButton(type: .system)
    private let textBtn = UIButton(type: .system)
    private let historyBtn = UIButton(type: .system)

    // MARK: - State

    private var rows: [Row] = []
    private var sortKey: SortKey = .score
    private var ascending = false
    private var hasSavedThisOpen = false

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
        setupButtons()
        setupTable()
        setupHeader()
        setupDismissGesture()
        setupReloadObserver()

        reloadFromModel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupPanel() {
        panelView.backgroundColor = .systemBackground
        panelView.layer.cornerRadius = 16
        panelView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panelView)

        NSLayoutConstraint.activate([
            panelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panelView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            panelView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            panelView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
        ])
    }

    private func setupButtons() {
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(closeBtn)

        textBtn.setTitle("Text Group Summary", for: .normal)
        textBtn.setTitleColor(.white, for: .normal)
        textBtn.backgroundColor = .systemGreen
        textBtn.layer.cornerRadius = 14
        textBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        textBtn.addTarget(self, action: #selector(textGroupTapped), for: .touchUpInside)
        textBtn.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(textBtn)

        historyBtn.setTitle("Store to Game History", for: .normal)
        historyBtn.setTitleColor(.white, for: .normal)
        historyBtn.backgroundColor = .systemIndigo
        historyBtn.layer.cornerRadius = 14
        historyBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        historyBtn.addTarget(self, action: #selector(loadGameToHistoryTapped(_:)), for: .touchUpInside)
        historyBtn.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(historyBtn)

        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: panelView.topAnchor, constant: 8),
            closeBtn.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -8),

            historyBtn.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 16),
            historyBtn.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -16),
            historyBtn.bottomAnchor.constraint(equalTo: panelView.bottomAnchor, constant: -14),
            historyBtn.heightAnchor.constraint(equalToConstant: 52),

            textBtn.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 16),
            textBtn.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -16),
            textBtn.bottomAnchor.constraint(equalTo: historyBtn.topAnchor, constant: -10),
            textBtn.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 52
        tableView.separatorInset = .zero
        tableView.register(StatsCell.self, forCellReuseIdentifier: StatsCell.reuseID)
        panelView.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: closeBtn.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: textBtn.topAnchor, constant: -10),
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

    private func setupDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(bgTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupReloadObserver() {
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(reloadFromModel),
                                              name: .reloadUI,
                                              object: nil)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func bgTapped(_ gr: UITapGestureRecognizer) {
        let loc = gr.location(in: view)
        if !panelView.frame.contains(loc) {
            dismiss(animated: true)
        }
    }

    @objc private func textGroupTapped() {
        // Phones for active players on this card, matched by Friend.name -> Friend.phone
        let phones = phonesForPlayingGroupFromCurrentGame()
            .map(normalizePhone)
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

        guard !phones.isEmpty else {
            showAlert(
                "No Numbers Found",
                "I couldn’t find phone numbers for the active players.\n\n" +
                "Make sure:\n• Friends have a phone number\n• Player names match Friend names"
            )
            return
        }

        let body = buildGameSummaryText()
        presentComposer(to: phones, body: body)
    }

    @objc private func loadGameToHistoryTapped(_ sender: UIButton) {
        if hasSavedThisOpen {
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

    // MARK: - Texting

    private func phonesForPlayingGroupFromCurrentGame() -> [String] {
        guard let g = GameManager.shared.currentGame else { return [] }

        let seats = 0..<min(g.playerNames.count, g.playerActivated.count)
        let activeNames: [String] = seats
            .filter { g.playerActivated[$0] }
            .map { g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let phones: [String] = FriendStore.shared.friends.compactMap { f in
            let fn = f.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard activeNames.contains(where: { $0.caseInsensitiveCompare(fn) == .orderedSame }) else { return nil }

            let p = f.phone.trimmingCharacters(in: .whitespacesAndNewlines)
            return p.isEmpty ? nil : p
        }

        return phones
    }

    private func buildGameSummaryText() -> String {
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)

        var out: [String] = []
        out.append("WolfMore")
        out.append(date)
        out.append("")

        for r in rows {
            let moneyText = currency0.string(from: NSNumber(value: r.totalMoney))
                ?? "$\(Int(r.totalMoney.rounded()))"
            out.append("\(r.name): \(r.totalScore) | \(moneyText)")
        }

        return out.joined(separator: "\n")
    }

    private func presentComposer(to phones: [String], body: String) {
        let clean = phones
            .map(normalizePhone)
            .filter { !$0.isEmpty }
            .uniquePreserveOrder()

        guard !clean.isEmpty else {
            showAlert("No Numbers", "No phone numbers found for this group.")
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            // Simulator / iPad fallback: copy the message so you can verify content
            UIPasteboard.general.string = body
            showAlert("Copied Summary", "This device can’t send texts. Summary copied to clipboard.")
            return
        }

        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        composer.recipients = clean
        composer.body = body
        present(composer, animated: true)
    }

    private func normalizePhone(_ s: String) -> String { s.filter(\.isNumber) }

    private func showAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
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

            built.append(.init(seat: seat,
                               name: name,
                               front9Score: front9,
                               totalScore: total,
                               totalMoney: money,
                               proxCount: prox))
        }

        rows = built
        applySortAndReload()
    }

    private func totalScoreForSeat(_ seat: Int, in g: GameData) -> Int? {
        var sum = 0, haveAny = false

        // Layout: [player][hole]
        if seat < g.scores.count, let first = g.scores.first, first.count == 18 {
            for h in 0..<min(18, g.scores[seat].count) {
                if let v = g.scores[seat][h] { sum += v; haveAny = true }
            }
            return haveAny ? sum : nil
        }

        // Layout: [hole][player]
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

        // Layout: [player][hole]
        if seat < g.scores.count, let first = g.scores.first, first.count == 18 {
            for h in 0..<min(9, g.scores[seat].count) {
                if let v = g.scores[seat][h] { sum += v; haveAny = true }
            }
            return haveAny ? sum : nil
        }

        // Layout: [hole][player]
        if g.scores.count == 18 {
            for h in 0..<min(9, g.scores.count) {
                let row = g.scores[h]
                if seat < row.count, let v = row[seat] { sum += v; haveAny = true }
            }
            return haveAny ? sum : nil
        }

        return nil
    }

    private func totalMoneyForSeat(_ seat: Int, in g: GameData) -> Double {
        guard seat < g.playerMoney.count else { return 0 }
        return g.playerMoney[seat].prefix(18).reduce(0, +)
    }

    private func proxWinsForSeat(_ seat: Int, in g: GameData) -> Int {
        let winners = g.proxWinnerPerHole.map { $0 ?? -1 }
        return winners.prefix(18).reduce(0) { $0 + ($1 == seat ? 1 : 0) }
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
            cmp = { a, b in
                asc ? (a.totalScore, a.name) < (b.totalScore, b.name)
                    : (a.totalScore, a.name) > (b.totalScore, b.name)
            }
        case .money:
            cmp = { a, b in
                asc ? (a.totalMoney, a.name) < (b.totalMoney, b.name)
                    : (a.totalMoney, a.name) > (b.totalMoney, b.name)
            }
        case .prox:
            cmp = { a, b in
                asc ? (a.proxCount, a.name) < (b.proxCount, b.name)
                    : (a.proxCount, a.name) > (b.proxCount, b.name)
            }
        }

        rows.sort(by: cmp)
        header.indicate(sortKey: key, ascending: asc)
        tableView.reloadData()
    }

    // MARK: - Save helper

    private func recordMeAndTrackedFriendsFromCurrentGame() {
        guard GameManager.shared.currentGame != nil else { return }

        var namesToSave = Set<String>()

        let me = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !me.isEmpty { namesToSave.insert(me) }

        let trackingCourseID = ProfileStore.homeCourseID.isEmpty ? "HOME-COURSE" : ProfileStore.homeCourseID
        let trackedFriendNames = FriendStore.shared.friends
            .filter { FriendTrackStore.shared.isTracked(friendID: $0.id, courseID: trackingCourseID) }
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let g = GameManager.shared.currentGame {
            let seats = 0..<min(5, min(g.playerNames.count, g.playerActivated.count))
            for i in seats where g.playerActivated[i] {
                let seatName = g.playerNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if trackedFriendNames.contains(where: { $0.caseInsensitiveCompare(seatName) == .orderedSame }) {
                    namesToSave.insert(seatName)
                }
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
}

// MARK: - MFMessageComposeViewControllerDelegate

extension GameStatsViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension GameStatsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: StatsCell.reuseID,
                                                 for: indexPath) as! StatsCell

        cell.configure(
            name: r.name,
            front9Score: r.front9Score,
            totalScore: r.totalScore,
            totalMoneyText: currency0.string(from: NSNumber(value: r.totalMoney))
                ?? "$\(Int(r.totalMoney.rounded()))",
            proxCount: r.proxCount,
            moneyIsNegative: r.totalMoney < 0
        )
        return cell
    }
}

// MARK: - Small helper

private extension Array where Element == String {
    func uniquePreserveOrder() -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for s in self where !seen.contains(s) {
            seen.insert(s)
            out.append(s)
        }
        return out
    }
}

// MARK: - Header

private final class HeaderView: UIView {

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

private final class StatsCell: UITableViewCell {

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
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

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

    func configure(name: String,
                   front9Score: Int,
                   totalScore: Int,
                   totalMoneyText: String,
                   proxCount: Int,
                   moneyIsNegative: Bool) {
        nameLabel.text   = name
        front9Label.text = "\(front9Score)"
        scoreLabel.text  = "\(totalScore)"
        moneyLabel.text  = totalMoneyText
        proxLabel.text   = "\(proxCount)"
        moneyLabel.textColor = moneyIsNegative ? .systemRed : .label
    }

    private static func makeLabel(alignment: NSTextAlignment = .center,
                                  monospaced: Bool = true,
                                  weight: UIFont.Weight = .regular) -> UILabel {
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
