import UIKit

/// Edit event-level settings: name, course, tee set, rules, scoring options, and handicap allowance.
/// Organizer only. Locked after event status = 'finished'.
final class ClubEventSettingsViewController: UITableViewController {

    static let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)

    private let event:            ClubEventRecord
    private var rules:            ClubEventRules?
    private var pending:          Pending = Pending()
    private let payoutsCtrl       = PayoutsSectionController()

    var onSaved: (() -> Void)?

    private struct Pending {
        var name:              String?
        var courseName:        String?
        var teeSet:            String?
        var handicapAllowance: Double?
        var grossLeaderboard:  Bool?
        var grossSkins:        Bool?
        var netSkins:          Bool?
        var skinsCarryover:    Bool?
        var allowDualTeam:     Bool?

        var hasChanges: Bool {
            name != nil || courseName != nil || teeSet != nil ||
            handicapAllowance != nil || grossLeaderboard != nil ||
            grossSkins != nil || netSkins != nil || skinsCarryover != nil ||
            allowDualTeam != nil
        }
    }

    private enum Section: Int, CaseIterable {
        case event, scoring, skins, teams, payouts, action
    }

    // MARK: - Init

    init(event: ClubEventRecord, rules: ClubEventRules?,
         activePlayerCount: Int = 0, teamEnrollmentCount: Int = 0) {
        self.event = event
        self.rules = rules
        super.init(style: .insetGrouped)

        // Seed the shared controller from loaded rules
        if let r = rules {
            payoutsCtrl.configure(
                from: r,
                grossLeaderboard: r.grossLeaderboard,
                grossSkins: r.grossSkinsEnabled,
                netSkins: r.netSkinsEnabled)
        }
        payoutsCtrl.activePlayerCount    = activePlayerCount
        payoutsCtrl.teamEnrollmentCount  = teamEnrollmentCount
        payoutsCtrl.onReload = { [weak self] in
            guard let self else { return }
            self.tableView.reloadSections(
                IndexSet([Section.payouts.rawValue]), with: .automatic)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Effective helpers (drive row visibility and cell content)

    private var effectiveGrossLeaderboard: Bool {
        pending.grossLeaderboard ?? rules?.grossLeaderboard ?? false
    }
    private var effectiveGrossSkins: Bool {
        pending.grossSkins ?? rules?.grossSkinsEnabled ?? true
    }
    private var effectiveNetSkins: Bool {
        pending.netSkins ?? rules?.netSkinsEnabled ?? true
    }
    private var effectivePlacesPaid: Int {
        payoutsCtrl.placesPaid
    }
    private var pctTotal: Double { payoutsCtrl.pctTotal }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Event Settings"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .onDrag

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navigationItem.standardAppearance   = navAppearance
        navigationItem.scrollEdgeAppearance = navAppearance
    }

    // MARK: - Table structure

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .event:    return "EVENT"
        case .scoring:  return "SCORING"
        case .skins:    return "SKINS"
        case .teams:    return "TEAMS"
        case .payouts:  return "PAYOUTS"
        case .action:   return nil
        case .none:     return nil
        }
    }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .event:    return 3
        case .scoring:  return 2
        case .skins:    return 3
        case .teams:    return 1
        case .payouts:  return payoutsCtrl.rowKinds.count
        case .action:   return 1
        case .none:     return 0
        }
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .event:
            switch indexPath.row {
            case 0: return textCell(label: "Name",
                                    value: event.name, tag: 0, placeholder: "Event name")
            case 1: return textCell(label: "Course",
                                    value: event.courseName ?? "", tag: 1, placeholder: "Course name (optional)")
            case 2: return textCell(label: "Tee Set",
                                    value: event.teeSet ?? "", tag: 2, placeholder: "e.g. White Tees (optional)")
            default: break
            }
        case .scoring:
            switch indexPath.row {
            case 0:
                return stepperCell(label: "Handicap Allowance",
                                   value: pending.handicapAllowance ?? rules?.handicapAllowance ?? 1.0,
                                   step: 0.05, min: 0.0, max: 1.0,
                                   format: { String(format: "%.0f%%", $0 * 100) },
                                   tag: 10)
            case 1:
                return switchCell(label: "Gross Leaderboard",
                                  isOn: effectiveGrossLeaderboard, tag: 20)
            default: break
            }
        case .skins:
            switch indexPath.row {
            case 0: return switchCell(label: "Gross Skins",
                                      isOn: effectiveGrossSkins, tag: 21)
            case 1: return switchCell(label: "Net Skins",
                                      isOn: effectiveNetSkins, tag: 22)
            case 2: return switchCell(label: "Carryover",
                                      isOn: pending.skinsCarryover ?? rules?.skinsCarryover ?? false,
                                      tag: 23)
            default: break
            }
        case .teams:
            if indexPath.row == 0 {
                return switchCell(label: "Allow Player on Two Teams",
                                  isOn: pending.allowDualTeam ?? rules?.allowDualTeam ?? false,
                                  tag: 24)
            }
        case .payouts:
            return payoutsCtrl.cell(for: payoutsCtrl.rowKinds[indexPath.row], in: tv)
        case .action:
            return saveCell()
        case .none:
            break
        }
        return UITableViewCell()
    }

    override func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        if indexPath.section == Section.payouts.rawValue {
            (tv.cellForRow(at: indexPath)?.contentView
                .subviews.first { $0 is UITextField } as? UITextField)?.becomeFirstResponder()
        }
    }

    // MARK: - Standard cell builders

    private func textCell(label: String, value: String, tag: Int, placeholder: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .preferredFont(forTextStyle: .body)
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let tf = UITextField()
        tf.text = value
        tf.placeholder = placeholder
        tf.font = .preferredFont(forTextStyle: .body)
        tf.textColor = .secondaryLabel
        tf.textAlignment = .right
        tf.tag = tag
        tf.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        tf.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(lbl)
        cell.contentView.addSubview(tf)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            tf.leadingAnchor.constraint(greaterThanOrEqualTo: lbl.trailingAnchor, constant: 8),
            tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            tf.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        return cell
    }

    private func stepperCell(label: String, value: Double, step: Double,
                              min: Double, max: Double, format: (Double) -> String, tag: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .preferredFont(forTextStyle: .body)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let valLabel = UILabel()
        valLabel.text = format(value)
        valLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        valLabel.textColor = .secondaryLabel
        valLabel.tag = tag + 1000
        valLabel.translatesAutoresizingMaskIntoConstraints = false

        let stepper = UIStepper()
        stepper.value = value
        stepper.stepValue = step
        stepper.minimumValue = min
        stepper.maximumValue = max
        stepper.tag = tag
        stepper.addTarget(self, action: #selector(stepperChanged(_:)), for: .valueChanged)
        stepper.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(lbl)
        cell.contentView.addSubview(valLabel)
        cell.contentView.addSubview(stepper)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            stepper.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            stepper.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            valLabel.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -8),
            valLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        return cell
    }

    private func switchCell(label: String, isOn: Bool, tag: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .preferredFont(forTextStyle: .body)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let sw = UISwitch()
        sw.isOn = isOn
        sw.tag  = tag
        sw.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        sw.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(lbl)
        cell.contentView.addSubview(sw)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            sw.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            sw.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        return cell
    }

    private func saveCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none

        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = Self.darkGreen
        cfg.baseForegroundColor = .white
        cfg.cornerStyle  = .large
        cfg.title        = "Save Settings"
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            btn.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            btn.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            btn.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
        return cell
    }

    // MARK: - Control actions (non-payouts sections)

    @objc private func textFieldChanged(_ tf: UITextField) {
        let v = tf.text ?? ""
        switch tf.tag {
        case 0: pending.name       = v.isEmpty ? nil : v
        case 1: pending.courseName = v.isEmpty ? nil : v
        case 2: pending.teeSet     = v.isEmpty ? nil : v
        default: break
        }
    }

    @objc private func stepperChanged(_ stepper: UIStepper) {
        switch stepper.tag {
        case 10:
            pending.handicapAllowance = stepper.value
            if let lbl = tableView.viewWithTag(1010) as? UILabel {
                lbl.text = String(format: "%.0f%%", stepper.value * 100)
            }
        default: break
        }
    }

    @objc private func switchChanged(_ sw: UISwitch) {
        switch sw.tag {
        case 20:
            pending.grossLeaderboard = sw.isOn
            payoutsCtrl.grossLeaderboard = sw.isOn
            tableView.reloadSections(IndexSet([Section.payouts.rawValue]), with: .automatic)
        case 21:
            pending.grossSkins = sw.isOn
            payoutsCtrl.grossSkinsEnabled = sw.isOn
            tableView.reloadSections(IndexSet([Section.payouts.rawValue]), with: .automatic)
        case 22:
            pending.netSkins = sw.isOn
            payoutsCtrl.netSkinsEnabled = sw.isOn
            tableView.reloadSections(IndexSet([Section.payouts.rawValue]), with: .automatic)
        case 23: pending.skinsCarryover = sw.isOn
        case 24: pending.allowDualTeam  = sw.isOn
        default: break
        }
    }

    // MARK: - Save

    @objc private func saveTapped() {
        view.endEditing(true)
        let spinner = UIAlertController(title: nil, message: "Saving…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let p = payoutsCtrl
                try await SupabaseService.shared.updateClubEventSettings(
                    tournamentId:        event.id,
                    name:                pending.name,
                    courseName:          pending.courseName,
                    teeSet:              pending.teeSet,
                    handicapAllowance:   pending.handicapAllowance,
                    grossLeaderboard:    pending.grossLeaderboard,
                    grossSkinsEnabled:   pending.grossSkins,
                    netSkinsEnabled:     pending.netSkins,
                    skinsCarryover:      pending.skinsCarryover,
                    teamNetPerPlayer:    p.teamNetPerPlayer,
                    teamGrossPerPlayer:  p.teamGrossPerPlayer,
                    grossSkinsPerPlayer: p.grossSkinsPerPlayer,
                    netSkinsPerPlayer:   p.netSkinsPerPlayer,
                    teamPlacesPaid:      p.placesPaid,
                    placePcts:           p.placePcts,
                    allowDualTeam:       pending.allowDualTeam,
                    payoutMode:          p.payoutMode,
                    teamNetTotal:        p.teamNetTotal,
                    teamGrossTotal:      p.teamGrossTotal,
                    grossSkinsTotal:     p.grossSkinsTotal,
                    netSkinsTotal:       p.netSkinsTotal)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.onSaved?()
                        self.showSavedToast()
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(title: "Save Failed",
                                                   message: error.localizedDescription,
                                                   preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
    }

    @objc private func doneTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func showSavedToast() {
        let toast = UILabel()
        toast.text = "  Settings saved  "
        toast.font = .preferredFont(forTextStyle: .footnote)
        toast.textColor = .white
        toast.backgroundColor = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)
        toast.layer.cornerRadius = 10
        toast.layer.masksToBounds = true
        toast.sizeToFit()
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
        ])
        toast.alpha = 0
        UIView.animate(withDuration: 0.25, animations: { toast.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.4, delay: 1.4, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
