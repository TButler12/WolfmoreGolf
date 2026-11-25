import UIKit

/// Organizer-facing form to create a new Club Event.
/// Pushes ClubEventOrganizerHomeViewController on success.
final class ClubEventCreationViewController: UITableViewController {

    static let darkGreen = UIColor(red: 0.118, green: 0.227, blue: 0.165, alpha: 1.0)
    static let teal      = UIColor(red: 0.10, green: 0.42, blue: 0.42, alpha: 1.0)

    // MARK: - Form state

    private var eventName: String = ""
    private var courseName: String?
    private var selectedCourse: CourseProfile?
    private var startDate: Date = Date()

    private var handicapAllowance: Int = 100
    private var grossLeaderboard: Bool = false
    private var grossSkinsEnabled: Bool = true
    private var netSkinsEnabled: Bool = true
    private var skinsCarryover: Bool = false
    private var allowDualTeam: Bool = false

    private var datePickerExpanded = false

    // MARK: - Payouts controller

    private let payoutsCtrl = PayoutsSectionController()

    // MARK: - Lifecycle

    override init(style: UITableView.Style) { super.init(style: style) }
    required init?(coder: NSCoder) { fatalError() }
    convenience init() { self.init(style: .insetGrouped) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Club Event"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = true

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navigationItem.standardAppearance   = navAppearance
        navigationItem.scrollEdgeAppearance = navAppearance

        payoutsCtrl.grossLeaderboard  = grossLeaderboard
        payoutsCtrl.grossSkinsEnabled = grossSkinsEnabled
        payoutsCtrl.netSkinsEnabled   = netSkinsEnabled
        payoutsCtrl.onReload = { [weak self] in
            guard let self else { return }
            let section = Section.payouts.rawValue
            self.tableView.reloadSections(IndexSet(integer: section), with: .automatic)
        }

#if DEBUG
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Test", style: .plain,
            target: self, action: #selector(createDebugTestEvent))
#endif
    }

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case event
        case format
        case payouts
    }

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count + 1 }

    override func tableView(_ tv: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "EVENT"
        case 1: return "FORMAT"
        case 2: return "PAYOUTS"
        default: return nil
        }
    }

    override func tableView(_ tv: UITableView, titleForFooterInSection section: Int) -> String? {
        nil
    }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return datePickerExpanded ? 4 : 3
        case 1: return 6
        case 2: return payoutsCtrl.rowKinds.count
        default: return 1
        }
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return eventCell(row: indexPath.row)
        case 1: return formatCell(row: indexPath.row)
        case 2: return payoutsCtrl.cell(for: payoutsCtrl.rowKinds[indexPath.row], in: tv)
        default: return createCell()
        }
    }

    override func tableView(_ tv: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 3 && datePickerExpanded { return 220 }
        return UITableView.automaticDimension
    }

    override func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        if indexPath.section == Section.payouts.rawValue {
            (tv.cellForRow(at: indexPath)?.contentView
                .subviews.first { $0 is UITextField } as? UITextField)?.becomeFirstResponder()
            return
        }
        if indexPath.section == 0 {
            if indexPath.row == 1 { presentCoursePicker() }
            if indexPath.row == 2 {
                datePickerExpanded.toggle()
                tv.beginUpdates()
                if datePickerExpanded {
                    tv.insertRows(at: [IndexPath(row: 3, section: 0)], with: .fade)
                } else {
                    tv.deleteRows(at: [IndexPath(row: 3, section: 0)], with: .fade)
                }
                tv.endUpdates()
            }
        }
    }

    // MARK: - Event cells

    private func eventCell(row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.accessoryType = .none
            cell.selectionStyle = .none
            let tf = UITextField()
            tf.placeholder = "Event name"
            tf.text = eventName
            tf.font = .preferredFont(forTextStyle: .body)
            tf.adjustsFontForContentSizeCategory = true
            tf.autocapitalizationType = .words
            tf.returnKeyType = .done
            tf.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)
            tf.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(tf)
            NSLayoutConstraint.activate([
                tf.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                tf.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                tf.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                tf.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            ])
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "Course"
            cfg.secondaryText = courseName ?? "Choose course"
            cfg.secondaryTextProperties.color = courseName == nil ? .tertiaryLabel : .label
            cell.contentConfiguration = cfg
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            var cfg = cell.defaultContentConfiguration()
            cfg.text = "Date"
            let f = DateFormatter()
            f.dateStyle = .medium
            cfg.secondaryText = f.string(from: startDate)
            cell.contentConfiguration = cfg
            cell.accessoryType = datePickerExpanded ? .none : .disclosureIndicator
            cell.selectionStyle = .default
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            cell.accessoryType = .none
            cell.selectionStyle = .none
            let picker = UIDatePicker()
            picker.datePickerMode = .date
            picker.preferredDatePickerStyle = .inline
            picker.date = startDate
            picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
            picker.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(picker)
            NSLayoutConstraint.activate([
                picker.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 8),
                picker.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8),
                picker.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 0),
                picker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: 0),
            ])
            return cell
        default:
            return UITableViewCell()
        }
    }

    // MARK: - Format cells

    private func formatCell(row: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.accessoryType = .none
        cell.selectionStyle = .none

        switch row {
        case 0:
            let label = UILabel()
            label.text = "Handicap Allowance"
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false

            let valueLabel = UILabel()
            valueLabel.text = "\(handicapAllowance)%"
            valueLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
            valueLabel.textColor = .secondaryLabel
            valueLabel.tag = 9901
            valueLabel.translatesAutoresizingMaskIntoConstraints = false

            let stepper = UIStepper()
            stepper.minimumValue = 50
            stepper.maximumValue = 100
            stepper.stepValue = 5
            stepper.value = Double(handicapAllowance)
            stepper.addTarget(self, action: #selector(hcAllowanceChanged(_:)), for: .valueChanged)
            stepper.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(label)
            cell.contentView.addSubview(valueLabel)
            cell.contentView.addSubview(stepper)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                stepper.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                stepper.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                valueLabel.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -12),
                valueLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            ])
            return cell
        case 1: return toggleRow(title: "Gross Leaderboard",
                                 value: grossLeaderboard,
                                 action: #selector(grossLeaderboardChanged(_:)))
        case 2: return toggleRow(title: "Gross Skins",
                                 value: grossSkinsEnabled,
                                 action: #selector(grossSkinsChanged(_:)))
        case 3: return toggleRow(title: "Net Skins",
                                 value: netSkinsEnabled,
                                 action: #selector(netSkinsChanged(_:)))
        case 4: return toggleRow(title: "Skins Carryover",
                                 value: skinsCarryover,
                                 action: #selector(carryoverChanged(_:)))
        case 5: return toggleRow(title: "Allow a player on two teams",
                                 value: allowDualTeam,
                                 action: #selector(allowDualTeamChanged(_:)))
        default: return cell
        }
    }

    private func toggleRow(title: String, value: Bool, action: Selector) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.accessoryType = .none
        cell.selectionStyle = .none

        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false

        let sw = UISwitch()
        sw.isOn = value
        sw.addTarget(self, action: action, for: .valueChanged)
        sw.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(label)
        cell.contentView.addSubview(sw)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            sw.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            sw.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
        ])
        return cell
    }

    // MARK: - Create button footer

    private func createCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        var cfg = UIButton.Configuration.filled()
        cfg.baseBackgroundColor = Self.darkGreen
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        cfg.title = "Create Event"
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
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

    // MARK: - Actions

    @objc private func nameChanged(_ tf: UITextField) { eventName = tf.text ?? "" }

    @objc private func dateChanged(_ picker: UIDatePicker) {
        startDate = picker.date
        tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
    }

    @objc private func hcAllowanceChanged(_ s: UIStepper) {
        handicapAllowance = Int(s.value)
        if let lbl = tableView.viewWithTag(9901) as? UILabel {
            lbl.text = "\(handicapAllowance)%"
        }
    }

    @objc private func grossLeaderboardChanged(_ sw: UISwitch) {
        grossLeaderboard = sw.isOn
        payoutsCtrl.grossLeaderboard = sw.isOn
        tableView.reloadSections(IndexSet(integer: Section.payouts.rawValue), with: .automatic)
    }

    @objc private func grossSkinsChanged(_ sw: UISwitch) {
        grossSkinsEnabled = sw.isOn
        payoutsCtrl.grossSkinsEnabled = sw.isOn
        tableView.reloadSections(IndexSet(integer: Section.payouts.rawValue), with: .automatic)
    }

    @objc private func netSkinsChanged(_ sw: UISwitch) {
        netSkinsEnabled = sw.isOn
        payoutsCtrl.netSkinsEnabled = sw.isOn
        tableView.reloadSections(IndexSet(integer: Section.payouts.rawValue), with: .automatic)
    }

    @objc private func carryoverChanged(_ sw: UISwitch)     { skinsCarryover = sw.isOn }
    @objc private func allowDualTeamChanged(_ sw: UISwitch) { allowDualTeam = sw.isOn }

    private func presentCoursePicker() {
        let sheet = UIAlertController(title: "Select Course", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Search Online Courses…", style: .default) { [weak self] _ in
            self?.presentCourseSearch()
        })
        for course in CourseLibrary.shared.allSorted() {
            sheet.addAction(UIAlertAction(title: course.name, style: .default) { [weak self] _ in
                self?.courseName = course.name
                self?.selectedCourse = course
                self?.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            })
        }
        sheet.addAction(UIAlertAction(title: "No course", style: .destructive) { [weak self] _ in
            self?.courseName = nil
            self?.selectedCourse = nil
            self?.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(sheet)
    }

    private func presentCourseSearch() {
        let search = CourseSearchViewController()
        search.delegate = self
        let nav = UINavigationController(rootViewController: search)
        present(nav, animated: true)
    }

    @objc private func createTapped() {
        view.endEditing(true)
        let trimmed = eventName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showAlert("Please enter an event name.")
            return
        }
        let spinner = UIAlertController(title: nil, message: "Creating event…", preferredStyle: .alert)
        present(spinner, animated: true)

        let allowance = Double(handicapAllowance) / 100.0
        let p = payoutsCtrl

        Task {
            do {
                let event = try await SupabaseService.shared.createClubEvent(
                    name: trimmed,
                    courseName: courseName,
                    coursePars: selectedCourse?.pars,
                    courseHandicaps: selectedCourse?.hcs,
                    numDays: 1,
                    players: [],
                    startDate: startDate,
                    handicapAllowance: allowance,
                    grossLeaderboard: grossLeaderboard,
                    grossSkinsEnabled: grossSkinsEnabled,
                    netSkinsEnabled: netSkinsEnabled,
                    skinsCarryover: skinsCarryover,
                    teamPlacesPaid: p.placesPaid,
                    allowDualTeam: allowDualTeam,
                    payoutMode: p.payoutMode,
                    teamNetPerPlayer: p.teamNetPerPlayer,
                    teamGrossPerPlayer: p.teamGrossPerPlayer,
                    grossSkinsPerPlayer: p.grossSkinsPerPlayer,
                    netSkinsPerPlayer: p.netSkinsPerPlayer,
                    teamNetTotal: p.teamNetTotal,
                    teamGrossTotal: p.teamGrossTotal,
                    grossSkinsTotal: p.grossSkinsTotal,
                    netSkinsTotal: p.netSkinsTotal,
                    placePcts: p.placePcts
                )
                let entry = ClubEventOrganizerEntry(
                    id: event.id, code: event.code, name: event.name,
                    courseName: event.courseName, createdAt: Date()
                )
                ClubEventOrganizerStore.shared.save(entry)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let home = ClubEventOrganizerHomeViewController(event: event)
                        if let nav = self.navigationController {
                            var vcs = nav.viewControllers
                            if let idx = vcs.firstIndex(of: self) {
                                vcs[idx] = home
                                nav.setViewControllers(vcs, animated: true)
                            } else {
                                nav.pushViewController(home, animated: true)
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showAlert("Could not create event.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Debug

#if DEBUG
    @objc private func createDebugTestEvent() {
        let spinner = UIAlertController(title: nil, message: "Creating test event…", preferredStyle: .alert)
        present(spinner, animated: true)
        Task {
            do {
                let testPlayers: [(name: String, handicap: Double)] = [
                    ("Barrett, Michael",  8),
                    ("Collins, Brian",   15),
                    ("Evans, Patrick",   24),
                    ("Fletcher, David",   3),
                    ("Graham, Sean",     11),
                    ("Hughes, Tom",      19),
                    ("Kennedy, Mark",     6),
                    ("Lawson, James",    28),
                ]
                let event = try await SupabaseService.shared.createClubEvent(
                    name: "[TEST] Club Event",
                    courseName: "Biltmore Country Club",
                    numDays: 1,
                    players: testPlayers)
                let entry = ClubEventOrganizerEntry(
                    id: event.id, code: event.code, name: event.name,
                    courseName: event.courseName, createdAt: Date()
                )
                ClubEventOrganizerStore.shared.save(entry)
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        let ac = UIAlertController(
                            title: "Test Event Created",
                            message: "Code: \(event.code)\n\n8 test players added.",
                            preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "Copy Code", style: .default) { _ in
                            UIPasteboard.general.string = event.code
                        })
                        ac.addAction(UIAlertAction(title: "Open Event", style: .default) { [weak self] _ in
                            guard let self else { return }
                            let home = ClubEventOrganizerHomeViewController(event: event)
                            self.navigationController?.pushViewController(home, animated: true)
                        })
                        ac.addAction(UIAlertAction(title: "Done", style: .cancel))
                        self.present(ac, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    spinner.dismiss(animated: false) {
                        self.showAlert("Could not create test event.\n\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }
#endif
}

// MARK: - CourseSearchDelegate

extension ClubEventCreationViewController: CourseSearchDelegate {
    func courseSearchDidImport(_ course: CourseProfile) {
        courseName = course.name
        selectedCourse = course
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
    }
}
