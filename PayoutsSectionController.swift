import UIKit

// MARK: - Row kind

enum PayoutsRowKind: Equatable {
    case payoutMode
    case header(String)
    case teamNet, teamGross, grossSkins, netSkins
    case entryFeeSum    // per_player: sum of all per-player amounts
    case totalPotSum    // fixed_total: sum of all entered totals
    case placesPaid
    case pct(Int)
    case pctTotal
}

// MARK: - Controller

final class PayoutsSectionController: NSObject {

    // MARK: State (read by VCs to send to save)

    private(set) var payoutMode:          String  = "per_player"
    private(set) var teamNetPerPlayer:    Double  = 0
    private(set) var teamGrossPerPlayer:  Double  = 0
    private(set) var grossSkinsPerPlayer: Double  = 0
    private(set) var netSkinsPerPlayer:   Double  = 0
    private(set) var teamNetTotal:        Double  = 0
    private(set) var teamGrossTotal:      Double  = 0
    private(set) var grossSkinsTotal:     Double  = 0
    private(set) var netSkinsTotal:       Double  = 0
    private(set) var placesPaid:          Int     = 3
    private(set) var placePcts:           [Double] = PayoutsSectionController.defaultPcts(for: 3)

    // MARK: Context from parent (changing these triggers onReload)

    var grossLeaderboard: Bool = false
    var grossSkinsEnabled: Bool = true
    var netSkinsEnabled: Bool = true

    // MARK: Player counts for per-player annotations

    var activePlayerCount: Int = 0      // unique active players (skins)
    var teamEnrollmentCount: Int = 0    // active team memberships; 0 = same as activePlayerCount

    // MARK: Callbacks

    var onReload: (() -> Void)?         // section needs full reload
    weak var tableView: UITableView?    // for inline label updates

    // MARK: - Load from saved rules

    func configure(from rules: ClubEventRules,
                   grossLeaderboard: Bool,
                   grossSkins: Bool,
                   netSkins: Bool) {
        payoutMode          = rules.payoutMode
        teamNetPerPlayer    = rules.teamNetPerPlayer
        teamGrossPerPlayer  = rules.teamGrossPerPlayer
        grossSkinsPerPlayer = rules.grossSkinsPerPlayer
        netSkinsPerPlayer   = rules.netSkinsPerPlayer
        teamNetTotal        = rules.teamNetTotal
        teamGrossTotal      = rules.teamGrossTotal
        grossSkinsTotal     = rules.grossSkinsTotal
        netSkinsTotal       = rules.netSkinsTotal
        placesPaid          = rules.teamPlacesPaid
        placePcts           = rules.placePcts.count == rules.teamPlacesPaid
                              ? rules.placePcts
                              : Self.defaultPcts(for: rules.teamPlacesPaid)
        self.grossLeaderboard  = grossLeaderboard
        self.grossSkinsEnabled = grossSkins
        self.netSkinsEnabled   = netSkins
    }

    // MARK: - Row kinds

    var rowKinds: [PayoutsRowKind] {
        var rows: [PayoutsRowKind] = [.payoutMode, .header("TEAM PAYOUTS")]
        rows.append(.teamNet)
        if grossLeaderboard { rows.append(.teamGross) }
        if payoutMode == "per_player" {
            rows.append(.entryFeeSum)
        } else {
            rows.append(.totalPotSum)
        }
        rows.append(.placesPaid)
        for i in 0..<placesPaid { rows.append(.pct(i)) }
        rows.append(.pctTotal)
        rows.append(.header("SKINS PAYOUTS"))
        if grossSkinsEnabled { rows.append(.grossSkins) }
        if netSkinsEnabled   { rows.append(.netSkins) }
        return rows
    }

    // MARK: - Computed

    private var effectiveTeamCount: Int {
        teamEnrollmentCount > 0 ? teamEnrollmentCount : activePlayerCount
    }

    var entryFeeSum: Double {
        var s = teamNetPerPlayer
        if grossLeaderboard  { s += teamGrossPerPlayer }
        if grossSkinsEnabled { s += grossSkinsPerPlayer }
        if netSkinsEnabled   { s += netSkinsPerPlayer }
        return s
    }

    var totalPotSum: Double {
        var s = teamNetTotal
        if grossLeaderboard  { s += teamGrossTotal }
        if grossSkinsEnabled { s += grossSkinsTotal }
        if netSkinsEnabled   { s += netSkinsTotal }
        return s
    }

    var pctTotal: Double { placePcts.reduce(0, +) }

    // MARK: - Default pcts

    static func defaultPcts(for n: Int) -> [Double] {
        switch n {
        case 1: return [100]
        case 2: return [60, 40]
        case 3: return [50, 30, 20]
        case 4: return [40, 30, 20, 10]
        case 5: return [35, 25, 20, 12, 8]
        default: return [100]
        }
    }

    // MARK: - Cell building

    func cell(for kind: PayoutsRowKind, in tv: UITableView) -> UITableViewCell {
        tableView = tv
        switch kind {
        case .payoutMode:
            return segmentedCell(items: ["Per Player", "Fixed Totals"],
                                 selected: payoutMode == "fixed_total" ? 1 : 0,
                                 tag: 50, in: tv)
        case .header(let title):
            return sectionHeaderCell(title: title, in: tv)
        case .teamNet:
            if payoutMode == "fixed_total" {
                return decimalCell(label: "Team Net Total $",
                                   value: teamNetTotal == 0 ? nil : teamNetTotal,
                                   tag: 40, in: tv)
            }
            return decimalCell(label: "Team Net / Player $",
                               value: teamNetPerPlayer == 0 ? nil : teamNetPerPlayer,
                               tag: 30, in: tv,
                               annotation: teamAnnotation(perPlayer: teamNetPerPlayer))
        case .teamGross:
            if payoutMode == "fixed_total" {
                return decimalCell(label: "Team Gross Total $",
                                   value: teamGrossTotal == 0 ? nil : teamGrossTotal,
                                   tag: 41, in: tv)
            }
            return decimalCell(label: "Team Gross / Player $",
                               value: teamGrossPerPlayer == 0 ? nil : teamGrossPerPlayer,
                               tag: 31, in: tv,
                               annotation: teamAnnotation(perPlayer: teamGrossPerPlayer))
        case .grossSkins:
            if payoutMode == "fixed_total" {
                return decimalCell(label: "Gross Skins Total $",
                                   value: grossSkinsTotal == 0 ? nil : grossSkinsTotal,
                                   tag: 42, in: tv)
            }
            return decimalCell(label: "Gross Skins / Player $",
                               value: grossSkinsPerPlayer == 0 ? nil : grossSkinsPerPlayer,
                               tag: 32, in: tv,
                               annotation: skinsAnnotation(perPlayer: grossSkinsPerPlayer))
        case .netSkins:
            if payoutMode == "fixed_total" {
                return decimalCell(label: "Net Skins Total $",
                                   value: netSkinsTotal == 0 ? nil : netSkinsTotal,
                                   tag: 43, in: tv)
            }
            return decimalCell(label: "Net Skins / Player $",
                               value: netSkinsPerPlayer == 0 ? nil : netSkinsPerPlayer,
                               tag: 33, in: tv,
                               annotation: skinsAnnotation(perPlayer: netSkinsPerPlayer))
        case .entryFeeSum:
            return summaryCell(label: "Entry Fee / Player",
                               value: entryFeeSum, tag: 998, in: tv)
        case .totalPotSum:
            return summaryCell(label: "Total Pot",
                               value: totalPotSum, tag: 998, in: tv)
        case .placesPaid:
            return stepperCell(label: "Places Paid",
                               value: Double(placesPaid),
                               step: 1, min: 1, max: 5,
                               format: { "\(Int($0))" }, tag: 11, in: tv)
        case .pct(let i):
            let labels = ["1st Place %", "2nd Place %", "3rd Place %", "4th Place %", "5th Place %"]
            let v = i < placePcts.count ? placePcts[i] : 0
            return decimalCell(label: labels[i], value: v == 0 ? nil : v,
                               tag: 100 + i, in: tv)
        case .pctTotal:
            return pctTotalCell(in: tv)
        }
    }

    // MARK: - Annotations

    private func teamAnnotation(perPlayer: Double) -> String? {
        guard payoutMode == "per_player", activePlayerCount > 0, perPlayer > 0 else { return nil }
        let n = effectiveTeamCount
        let pot = perPlayer * Double(n)
        return "× \(n) team spots = \(fmtMoney(pot))"
    }

    private func skinsAnnotation(perPlayer: Double) -> String? {
        guard payoutMode == "per_player", activePlayerCount > 0, perPlayer > 0 else { return nil }
        let pot = perPlayer * Double(activePlayerCount)
        return "× \(activePlayerCount) players = \(fmtMoney(pot))"
    }

    private func fmtMoney(_ v: Double) -> String {
        v == Double(Int(v)) ? "$\(Int(v))" : String(format: "$%.2f", v)
    }

    // MARK: - Control actions

    @objc func segmentedChanged(_ seg: UISegmentedControl) {
        guard seg.tag == 50 else { return }
        payoutMode = seg.selectedSegmentIndex == 1 ? "fixed_total" : "per_player"
        onReload?()
    }

    @objc func textFieldChanged(_ tf: UITextField) {
        let raw = tf.text ?? ""
        let v = Double(raw) ?? 0
        switch tf.tag {
        case 30:
            teamNetPerPlayer = v
            updateAnnotation(tag: 30)
            updateSummary()
        case 31:
            teamGrossPerPlayer = v
            updateAnnotation(tag: 31)
            updateSummary()
        case 32:
            grossSkinsPerPlayer = v
            updateAnnotation(tag: 32)
            updateSummary()
        case 33:
            netSkinsPerPlayer = v
            updateAnnotation(tag: 33)
            updateSummary()
        case 40:
            teamNetTotal = v
            updateSummary()
        case 41:
            teamGrossTotal = v
            updateSummary()
        case 42:
            grossSkinsTotal = v
            updateSummary()
        case 43:
            netSkinsTotal = v
            updateSummary()
        case 100...104:
            let i = tf.tag - 100
            if i < placePcts.count {
                placePcts[i] = v
                updatePctTotal()
            }
        default: break
        }
    }

    @objc func stepperChanged(_ stepper: UIStepper) {
        guard stepper.tag == 11 else { return }
        let n = Int(stepper.value)
        placesPaid = n
        placePcts  = Self.defaultPcts(for: n)
        if let lbl = tableView?.viewWithTag(1011) as? UILabel { lbl.text = "\(n)" }
        onReload?()
    }

    // MARK: - Inline label updates

    private func updateAnnotation(tag: Int) {
        guard let lbl = tableView?.viewWithTag(tag + 200) as? UILabel else { return }
        switch tag {
        case 30: lbl.text = teamAnnotation(perPlayer: teamNetPerPlayer)
        case 31: lbl.text = teamAnnotation(perPlayer: teamGrossPerPlayer)
        case 32: lbl.text = skinsAnnotation(perPlayer: grossSkinsPerPlayer)
        case 33: lbl.text = skinsAnnotation(perPlayer: netSkinsPerPlayer)
        default: break
        }
    }

    private func updateSummary() {
        guard let lbl = tableView?.viewWithTag(998) as? UILabel else { return }
        let val = payoutMode == "per_player" ? entryFeeSum : totalPotSum
        lbl.text = val == 0 ? "$0" : fmtMoney(val)
    }

    private func updatePctTotal() {
        guard let lbl = tableView?.viewWithTag(999) as? UILabel else { return }
        let total = pctTotal
        let isOK  = abs(total - 100) < 0.01
        lbl.text = isOK
            ? "✓  Total 100%"
            : String(format: "⚠  Total %.4g%% — must equal 100%%", total)
        lbl.textColor = isOK ? .systemGreen : .systemRed
    }

    // MARK: - Cell builders

    private func segmentedCell(items: [String], selected: Int, tag: Int, in tv: UITableView) -> UITableViewCell {
        let cell = dequeue(tv)
        let seg = UISegmentedControl(items: items)
        seg.selectedSegmentIndex = selected
        seg.tag = tag
        seg.addTarget(self, action: #selector(segmentedChanged), for: .valueChanged)
        seg.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(seg)
        NSLayoutConstraint.activate([
            seg.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            seg.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            seg.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
            seg.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        return cell
    }

    private func sectionHeaderCell(title: String, in tv: UITableView) -> UITableViewCell {
        let cell = dequeue(tv)
        let lbl = UILabel()
        lbl.text = title
        lbl.font = .preferredFont(forTextStyle: .footnote)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            lbl.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            lbl.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
            lbl.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
        ])
        return cell
    }

    private func decimalCell(label: String, value: Double?, tag: Int,
                              in tv: UITableView, annotation: String? = nil) -> UITableViewCell {
        let cell = dequeue(tv)

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .preferredFont(forTextStyle: .body)
        lbl.adjustsFontForContentSizeCategory = true
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let tf = UITextField()
        if let v = value { tf.text = v == Double(Int(v)) ? "\(Int(v))" : String(format: "%.2f", v) }
        tf.placeholder = "0"
        tf.font = .preferredFont(forTextStyle: .body)
        tf.textColor = .secondaryLabel
        tf.textAlignment = .right
        tf.keyboardType = .decimalPad
        tf.tag = tag
        tf.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        tf.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(lbl)
        cell.contentView.addSubview(tf)

        if let ann = annotation {
            let annLbl = UILabel()
            annLbl.text = ann
            annLbl.font = .preferredFont(forTextStyle: .caption2)
            annLbl.textColor = .secondaryLabel
            annLbl.textAlignment = .right
            annLbl.tag = tag + 200
            annLbl.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(annLbl)
            NSLayoutConstraint.activate([
                lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                lbl.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                tf.leadingAnchor.constraint(greaterThanOrEqualTo: lbl.trailingAnchor, constant: 8),
                tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                tf.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
                annLbl.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                annLbl.topAnchor.constraint(equalTo: tf.bottomAnchor, constant: 2),
                annLbl.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            ])
        } else {
            NSLayoutConstraint.activate([
                lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                lbl.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                tf.leadingAnchor.constraint(greaterThanOrEqualTo: lbl.trailingAnchor, constant: 8),
                tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                tf.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            ])
        }
        return cell
    }

    private func summaryCell(label: String, value: Double, tag: Int, in tv: UITableView) -> UITableViewCell {
        let cell = dequeue(tv)

        let lbl = UILabel()
        lbl.text = label
        lbl.font = .preferredFont(forTextStyle: .body)
        lbl.setContentHuggingPriority(.required, for: .horizontal)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let valLbl = UILabel()
        valLbl.text = value == 0 ? "$0" : fmtMoney(value)
        valLbl.font = .preferredFont(forTextStyle: .body)
        valLbl.textColor = .secondaryLabel
        valLbl.textAlignment = .right
        valLbl.tag = tag
        valLbl.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(lbl)
        cell.contentView.addSubview(valLbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            valLbl.leadingAnchor.constraint(greaterThanOrEqualTo: lbl.trailingAnchor, constant: 8),
            valLbl.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            valLbl.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        return cell
    }

    private func stepperCell(label: String, value: Double, step: Double,
                              min: Double, max: Double, format: (Double) -> String,
                              tag: Int, in tv: UITableView) -> UITableViewCell {
        let cell = dequeue(tv)

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
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
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

    private func pctTotalCell(in tv: UITableView) -> UITableViewCell {
        let cell = dequeue(tv)
        let total = pctTotal
        let isOK  = abs(total - 100) < 0.01

        let lbl = UILabel()
        lbl.tag = 999
        lbl.text = isOK
            ? "✓  Total 100%"
            : String(format: "⚠  Total %.4g%% — must equal 100%%", total)
        lbl.font = .preferredFont(forTextStyle: .footnote)
        lbl.textColor = isOK ? .systemGreen : .systemRed
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            lbl.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            lbl.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            lbl.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
        ])
        return cell
    }

    private func dequeue(_ tv: UITableView) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell")
            ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .none
        cell.accessoryType  = .none
        return cell
    }
}
