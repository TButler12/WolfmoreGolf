//
//  GameStatsViewController: UIViewController.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 10/18/25.
//
//
//  GameStatsViewController: UIViewController.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 10/18/25.
//

import UIKit

final class GameStatsViewController: UIViewController {

    // MARK: - Types

    enum SortKey { case name, score, money, prox }   // internal (default)

    private struct Row {
        let seat: Int
        let name: String
        let front9Score: Int   // NEW
        let totalScore: Int
        let totalMoney: Double
        let proxCount: Int
    }

    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let header = HeaderView()

    // MARK: - State

    private var rows: [Row] = []
    private var sortKey: SortKey = .score
    private var ascending = false // by default, highest score/money first; tap to flip

    // Money (no cents) — reuse across paints
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

        // 1) make the whole background slightly dim
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)

        // 2) make an inner container for the stats
        let panel = UIView()
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

        // 3) add a close (X) button
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(closeBtn)

        // 4) add your table INSIDE the panel
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

            tableView.topAnchor.constraint(equalTo: closeBtn.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
        ])

        // header
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
        tableView.tableHeaderView = header
        header.onTapName  = { [weak self] in self?.setSort(.name)  }
        header.onTapScore = { [weak self] in self?.setSort(.score) }
        header.onTapMoney = { [weak self] in self?.setSort(.money) }
        header.onTapProx  = { [weak self] in self?.setSort(.prox)  }

        // 9) tap outside to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(bgTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadFromModel),
                                               name: .reloadUI,
                                               object: nil)
        reloadFromModel()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func bgTapped(_ gr: UITapGestureRecognizer) {
        // if tap is on the dim background (not the panel), dismiss
        let loc = gr.location(in: view)
        if let panel = view.subviews.first(where: { $0 is UIView && $0.layer.cornerRadius == 16 }),
           !panel.frame.contains(loc) {
            dismiss(animated: true)
        }
    }

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

    // MARK: - Data

    @objc private func reloadFromModel() {
        guard let g = GameManager.shared.currentGame else {
            rows = []; tableView.reloadData(); return
        }

        let names = g.playerNames
        let actives = g.playerActivated
        let seats = min(names.count, actives.count)

        var built: [Row] = []
        for seat in 0..<seats {
            let name = names[seat].trimmingCharacters(in: .whitespacesAndNewlines)
            guard actives[seat], !name.isEmpty else { continue }

            let total = totalScoreForSeat(seat, in: g) ?? 0
            let front9 = front9ScoreForSeat(seat, in: g) ?? 0   // NEW
            let money = totalMoneyForSeat(seat, in: g)
            let prox  = proxWinsForSeat(seat, in: g)

            built.append(
                Row(
                    seat: seat,
                    name: name,
                    front9Score: front9,
                    totalScore: total,
                    totalMoney: money,
                    proxCount: prox
                )
            )
        }

        rows = built
        applySortAndReload()
    }

    // Total score across 18 holes; supports [player][hole] or [hole][player]
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
            for h in 0..<18 where h < g.scores.count {
                let row = g.scores[h]
                if seat < row.count, let v = row[seat] { sum += v; haveAny = true }
            }
            return haveAny ? sum : nil
        }
        return nil
    }

    // NEW: front-nine score (holes 0–8)
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

    // Sum money across all 18 holes for a seat (expects [[Double]] seat×hole)
    private func totalMoneyForSeat(_ seat: Int, in g: GameData) -> Double {
        guard !g.playerMoney.isEmpty else { return 0 }
        let rows = g.playerMoney
        guard seat < rows.count else { return 0 }
        let holes = rows[seat]
        let upto18 = min(18, holes.count)
        return holes.prefix(upto18).reduce(0, +)
    }

    // Count of CTP wins for a seat.
    private func proxWinsForSeat(_ seat: Int, in g: GameData) -> Int {
        let winnersOpt: [Int?] = g.proxWinnerPerHole
        let winners = winnersOpt.map { $0 ?? -1 }   // normalize to [Int]

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
            ascending = (key == .name) // names A→Z; numbers default high→low
        }
        applySortAndReload()
    }

    private func applySortAndReload() {
        let asc = self.ascending
        let key = self.sortKey

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
}

// MARK: - UITableViewDataSource / Delegate

extension GameStatsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: StatsCell.reuseID,
            for: indexPath
        ) as! StatsCell

        cell.configure(
            name: r.name,
            front9Score: r.front9Score,
            totalScore: r.totalScore,
            totalMoneyText: currency0.string(from: NSNumber(value: r.totalMoney))
                ?? "\(Int(r.totalMoney.rounded()))",
            proxCount: r.proxCount,
            moneyIsNegative: r.totalMoney < 0
        )
        return cell
    }
}

// MARK: - Header

private final class HeaderView: UIView {
    var onTapName:  (() -> Void)?
    var onTapScore: (() -> Void)?
    var onTapMoney: (() -> Void)?
    var onTapProx:  (() -> Void)?

    private let nameBtn   = UIButton(type: .system)
    private let front9Lbl = UILabel()                // NEW
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

        // NEW: Front 9 label
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

        // 5 columns: Player | Front 9 | Score | Money | Prox
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
        // front9Lbl is static – no sort arrow
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
    private let front9Label = StatsCell.makeLabel()                     // NEW
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

        // 5 columns now
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
