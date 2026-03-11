import UIKit

final class MyStatsViewController: UIViewController {

    // MARK: - Modes / Sorting

    enum Mode { case me, friends }
    enum SortKey { case name, money, prox }

    var mode: Mode = .me
    private var sortKey: SortKey = .money   // default for friends mode

    // MARK: - UI

    private let textView = UITextView()
    private let sortControl = UISegmentedControl(items: ["Name", "Money", "Prox"])

    // MARK: - Data

    private var allFriends: [Friend] { FriendStore.shared.friends }

    // MARK: - Formatting

    private let currency0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        return nf
    }()

    private func wonLostText(totalMoney: Int) -> String {
        let verb = (totalMoney >= 0) ? "Won" : "Lost"
        let amt = abs(totalMoney)
        let amtStr = currency0.string(from: NSNumber(value: amt)) ?? "\(amt)"
        return "\(verb) \(amtStr)"
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = (mode == .me) ? "My Stats" : "Friend Stats"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )

        configureTextView()

        if mode == .friends {
            configureSortControl()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: .reloadUI,
            object: nil
        )

        reload()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup

    private func configureTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureSortControl() {
        sortControl.selectedSegmentIndex = 1 // Money
        sortControl.addTarget(self, action: #selector(sortChanged(_:)), for: .valueChanged)
        navigationItem.titleView = sortControl
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        // If pushed, pop. If presented, dismiss.
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func sortChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: sortKey = .name
        case 1: sortKey = .money
        default: sortKey = .prox
        }
        reload()
    }

    // MARK: - Reload

    @objc private func reload() {
        switch mode {
        case .me:
            navigationItem.titleView = nil
            title = "My Stats"
            textView.text = buildMyStatsMessage()
        case .friends:
            title = "Friend Stats"
            textView.text = buildFriendStatsMessagePinnedMe()
        }
    }

    // MARK: - Build: My Stats

    private func buildMyStatsMessage() -> String {
        let myName = (ProfileStore.name ?? "Player 1")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let s = RoundStore.shared.stats(forPlayerNamed: myName) else {
            return "No rounds saved yet for \(myName)."
        }

        return formatBlock(name: myName, stats: s)
    }

    // MARK: - Build: Friends Stats (with Me pinned + sortable friends)

    private func buildFriendStatsMessagePinnedMe() -> String {
        let myName = (ProfileStore.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var blocks: [String] = []

        // --- ME pinned at top ---
        if !myName.isEmpty, let myStats = RoundStore.shared.stats(forPlayerNamed: myName) {
            blocks.append("— ME —\n" + formatBlock(name: myName, stats: myStats))
        }

        // --- FRIENDS ---
        var friendRows: [(name: String, stats: MyStats)] = allFriends.compactMap { f in
            let n = f.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !n.isEmpty else { return nil }

            // Avoid duplicates if "me" is also in FriendStore
            if !myName.isEmpty, n.caseInsensitiveCompare(myName) == .orderedSame {
                return nil
            }

            guard let s = RoundStore.shared.stats(forPlayerNamed: n) else { return nil }
            return (n, s)
        }

        // Nothing at all?
        guard !(blocks.isEmpty && friendRows.isEmpty) else {
            return "No rounds saved yet."
        }

        // Sort friends
        switch sortKey {
        case .name:
            friendRows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .money:
            friendRows.sort { $0.stats.totalMoney > $1.stats.totalMoney } // high → low
        case .prox:
            friendRows.sort { $0.stats.totalProx > $1.stats.totalProx }   // high → low
        }

        if !friendRows.isEmpty {
            let friendsText = friendRows
                .map { formatBlock(name: $0.name, stats: $0.stats) }
                .joined(separator: "\n\n")

            blocks.append("— FRIENDS —\n" + friendsText)
        }

        return blocks.joined(separator: "\n\n\n")
    }

    // MARK: - Formatting

    private func formatBlock(name: String, stats s: MyStats) -> String {
        let totalLine = wonLostText(totalMoney: s.totalMoney)
        let avgMoneyStr = String(format: "%.1f", s.avgMoneyPerRound)
        let avgProxStr  = String(format: "%.1f", s.avgProxPerRound)

        return """
        • \(name)
          \(s.rounds) rds
          \(totalLine)
          avg $\(avgMoneyStr) per 18
          prox \(s.totalProx) total (avg \(avgProxStr) per 18)
        """
    }
}
