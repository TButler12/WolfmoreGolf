import UIKit

final class RemoteNassauSetupViewController: UIViewController {

    // MARK: - Config & callback

    struct Config {
        let activePlayers: [(slot: Int, name: String)]
        let initialStake: Double
        let initialPressMode: NassauPressMode
        let initialTrigger: Int
    }

    var onConfirm: ((_ slot: Int, _ name: String, _ stake: Double,
                     _ pressMode: NassauPressMode, _ trigger: Int) -> Void)?

    // MARK: - State

    private let config: Config
    private var selectedSlot: Int
    private var selectedName: String
    private var selectedStake: Double
    private var selectedPressMode: NassauPressMode
    private var selectedTrigger: Int

    // Preset stake options. "Other…" is the implicit 6th segment.
    static let presetStakes: [Double] = [1, 2, 5, 10, 20]

    // MARK: - Controls

    private lazy var stakeSegment: UISegmentedControl = {
        let presetTitles = Self.presetStakes.map { v -> String in
            v == floor(v) ? "$\(Int(v))" : String(format: "$%.2f", v)
        }
        let s = UISegmentedControl(items: presetTitles + ["Other…"])
        if let idx = Self.presetStakes.firstIndex(of: selectedStake) {
            s.selectedSegmentIndex = idx
        } else {
            // Non-preset initial value (e.g. loaded from an existing match).
            let title = selectedStake == floor(selectedStake)
                ? "$\(Int(selectedStake))" : String(format: "$%.2f", selectedStake)
            s.setTitle(title, forSegmentAt: Self.presetStakes.count)
            s.selectedSegmentIndex = Self.presetStakes.count
        }
        s.addTarget(self, action: #selector(stakeChanged), for: .valueChanged)
        return s
    }()

    private lazy var pressSegment: UISegmentedControl = {
        let s = UISegmentedControl(items: ["Auto", "Off"])
        s.selectedSegmentIndex = Self.pressModeIndex(selectedPressMode)
        s.addTarget(self, action: #selector(pressChanged), for: .valueChanged)
        return s
    }()

    private lazy var triggerStepper: UIStepper = {
        let s = UIStepper()
        s.minimumValue = 1
        s.maximumValue = 5
        s.stepValue    = 1
        s.value        = Double(selectedTrigger)
        s.addTarget(self, action: #selector(triggerChanged), for: .valueChanged)
        return s
    }()

    private lazy var triggerLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17)
        l.text = "\(selectedTrigger) down"
        return l
    }()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Init

    init(config: Config) {
        self.config = config
        let myName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultPlayer = config.activePlayers.first(where: {
            !myName.isEmpty && $0.name.localizedCaseInsensitiveCompare(myName) == .orderedSame
        }) ?? config.activePlayers.first
        self.selectedSlot      = defaultPlayer?.slot ?? 0
        self.selectedName      = defaultPlayer?.name ?? myName
        self.selectedStake     = config.initialStake
        // Manual is not supported in remote Nassau; treat as auto.
        self.selectedPressMode = config.initialPressMode == .manual ? .auto : config.initialPressMode
        self.selectedTrigger   = config.initialTrigger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Start Remote Nassau"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.tableFooterView = buildFooter()
    }

    // MARK: - Footer button

    private func buildFooter() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
        let btn = UIButton(type: .system)
        btn.setTitle("Create & Share Invite", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            btn.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            btn.heightAnchor.constraint(equalToConstant: 50)
        ])
        return container
    }

    // MARK: - Actions

    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func createTapped() {
        let slot = selectedSlot; let name = selectedName
        let stake = selectedStake; let mode = selectedPressMode; let trig = selectedTrigger
        dismiss(animated: true) { [weak self] in
            self?.onConfirm?(slot, name, stake, mode, trig)
        }
    }

    @objc private func stakeChanged(_ s: UISegmentedControl) {
        if s.selectedSegmentIndex < Self.presetStakes.count {
            selectedStake = Self.presetStakes[s.selectedSegmentIndex]
            // Reset the Other segment title in case it was showing a custom value.
            s.setTitle("Other…", forSegmentAt: Self.presetStakes.count)
            refreshRulesFooter()
        } else {
            showCustomStakeEntry()
        }
    }

    private func showCustomStakeEntry() {
        let alert = UIAlertController(title: "Custom Stake",
                                      message: "Whole dollars (1–1000)", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.keyboardType = .numberPad
            tf.placeholder  = "15"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self else { return }
            // Revert segment to whatever stake was previously set.
            let idx = Self.presetStakes.firstIndex(of: selectedStake) ?? Self.presetStakes.count
            stakeSegment.selectedSegmentIndex = idx
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self else { return }
            let raw = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if let v = Int(raw), v >= 1, v <= 1000 {
                selectedStake = Double(v)
                stakeSegment.setTitle("$\(v)", forSegmentAt: Self.presetStakes.count)
                stakeSegment.selectedSegmentIndex = Self.presetStakes.count
                refreshRulesFooter()
            } else {
                let idx = Self.presetStakes.firstIndex(of: selectedStake) ?? Self.presetStakes.count
                stakeSegment.selectedSegmentIndex = idx
            }
        })
        present(alert, animated: true)
    }

    @objc private func pressChanged(_ s: UISegmentedControl) {
        selectedPressMode = Self.pressModeAt(s.selectedSegmentIndex)
        let ip = IndexPath(row: 2, section: 1)
        let showTrigger = selectedPressMode == .auto
        let hasTrigger  = tableView.numberOfRows(inSection: 1) > 2
        tableView.beginUpdates()
        if showTrigger && !hasTrigger  { tableView.insertRows(at: [ip], with: .automatic) }
        if !showTrigger && hasTrigger  { tableView.deleteRows(at: [ip], with: .automatic)  }
        tableView.endUpdates()
        refreshRulesFooter()
    }

    @objc private func triggerChanged(_ s: UIStepper) {
        selectedTrigger   = Int(s.value)
        triggerLabel.text = "\(selectedTrigger) down"
        refreshRulesFooter()
    }

    // MARK: - Player picker

    private func playerTapped() {
        guard config.activePlayers.count > 1 else { return }
        let sheet = UIAlertController(title: "Who is playing?", message: nil, preferredStyle: .actionSheet)
        for p in config.activePlayers {
            sheet.addAction(UIAlertAction(title: p.name, style: .default) { [weak self] _ in
                guard let self else { return }
                self.selectedSlot = p.slot
                self.selectedName = p.name
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        present(sheet, animated: true)
    }

    // MARK: - Footer refresh

    private func refreshRulesFooter() {
        guard let footer = tableView.footerView(forSection: 1) else { return }
        footer.textLabel?.text = WolfActions.rulesDescription(
            stake: selectedStake, pressMode: selectedPressMode, trigger: selectedTrigger, isV2: true)
        footer.textLabel?.sizeToFit()
    }

    // MARK: - Helpers

    /// Maps a press mode to its segment index (Auto/Manual both → 0; Off → 1).
    static func pressModeIndex(_ mode: NassauPressMode) -> Int { mode == .off ? 1 : 0 }

    /// Maps a segment index back to a press mode (only Auto and Off are valid for remote Nassau).
    static func pressModeAt(_ index: Int) -> NassauPressMode { index == 1 ? .off : .auto }
}

// MARK: - UITableViewDataSource / Delegate

extension RemoteNassauSetupViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return selectedPressMode == .auto ? 3 : 2
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Player" : "Rules"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 1 else { return nil }
        return WolfActions.rulesDescription(
            stake: selectedStake, pressMode: selectedPressMode, trigger: selectedTrigger, isV2: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = selectedName.isEmpty ? "Select player" : selectedName
            if config.activePlayers.count > 1 {
                cell.accessoryType  = .disclosureIndicator
                cell.selectionStyle = .default
            }
        case (1, 0):
            cell.textLabel?.text = "Stake"
            stakeSegment.frame   = CGRect(x: 0, y: 0, width: 265, height: 31)
            cell.accessoryView   = stakeSegment
        case (1, 1):
            cell.textLabel?.text = "Press"
            pressSegment.frame   = CGRect(x: 0, y: 0, width: 140, height: 31)
            cell.accessoryView   = pressSegment
        case (1, 2):
            cell.textLabel?.text = "Trigger"
            triggerLabel.text    = "\(selectedTrigger) down"
            let container        = UIStackView(arrangedSubviews: [triggerLabel, triggerStepper])
            container.spacing    = 8
            container.alignment  = .center
            container.frame      = CGRect(x: 0, y: 0, width: 165, height: 44)
            cell.accessoryView   = container
        default: break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 { playerTapped() }
    }
}
