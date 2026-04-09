//
//
//  //
//  //
//  CoursePickerViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/19/26.
//


import UIKit

final class CoursePickerViewController: UITableViewController, UISearchResultsUpdating {

    // MARK: - Types

    private enum SortMode {
        case groupedLocation
        case nameAZ
    }

    private enum CourseFilter: Equatable {
        case all
        case resort
        case privateClub
        case publicCourse
        case rtj
        case resortBrand
        case trump
        case omni
    }
    private enum LocationGrouping {
        case state
        case region
    }

    // MARK: - Callbacks

    var onPickCourse: ((UUID) -> Void)?
    var onTapAddCourse: (() -> Void)?

    // MARK: - Data

    private var all: [CourseProfile] = []
    private var filtered: [CourseProfile] = []
    private var sections: [(title: String, items: [CourseProfile])] = []

    // MARK: - UI State

    private var sortMode: SortMode = .groupedLocation
    private var activeFilter: CourseFilter = .all
    private var locationGrouping: LocationGrouping = .state

    private let searchController = UISearchController(searchResultsController: nil)

    private var searchText: String {
        (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var homeCourseUUID: UUID? {
        let raw = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: raw)
    }

    private let summaryHeader = UIView()
    private let summaryLabel1 = UILabel()
    private let summaryLabel2 = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Choose Course"
        tableView = UITableView(frame: .zero, style: .insetGrouped)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filterTapped))
        ]

        configureSummaryHeader()
        configureSearch()
        reloadCourses()
    }

    // MARK: - Setup

    private func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search courses"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func configureSummaryHeader() {
        summaryHeader.backgroundColor = .clear

        summaryLabel1.font = .systemFont(ofSize: 13, weight: .semibold)
        summaryLabel1.textColor = .secondaryLabel

        summaryLabel2.font = .systemFont(ofSize: 13, weight: .regular)
        summaryLabel2.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [summaryLabel1, summaryLabel2])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        summaryHeader.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: summaryHeader.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: summaryHeader.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: summaryHeader.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: summaryHeader.bottomAnchor, constant: -10)
        ])

        summaryHeader.frame.size.height = 52
        tableView.tableHeaderView = summaryHeader
    }

    private func updateSummaryHeader() {
        let total = all.count
        let builtInCount = all.filter { CourseLibrary.shared.isBuiltIn(id: $0.id) }.count
        let customCount = total - builtInCount

        summaryLabel1.text = "Loaded courses: \(total)"
        summaryLabel2.text = "Built-in: \(builtInCount) • Custom: \(customCount)"

        summaryHeader.setNeedsLayout()
        summaryHeader.layoutIfNeeded()

        let target = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = summaryHeader.systemLayoutSizeFitting(target).height

        if summaryHeader.frame.height != height {
            var frame = summaryHeader.frame
            frame.size.height = height
            summaryHeader.frame = frame
            tableView.tableHeaderView = summaryHeader
        }
    }

    // MARK: - Data

    private func reloadCourses() {
        all = CourseLibrary.shared.allSorted()
        applySearchSortAndFilter()
        updateSummaryHeader()
    }

    // MARK: - Filter Menu

    @objc private func filterTapped() {
        let ac = UIAlertController(title: "Sort / Filter", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(
            title: sortMode == .groupedLocation ? "✓ Sort: Grouped (Location)" : "Sort: Grouped (Location)",
            style: .default
        ) { [weak self] _ in
            self?.sortMode = .groupedLocation
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: sortMode == .nameAZ ? "✓ Sort: Name (A–Z)" : "Sort: Name (A–Z)",
            style: .default
        ) { [weak self] _ in
            self?.sortMode = .nameAZ
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: activeFilter == .all ? "✓ Filter: All Courses" : "Filter: All Courses",
            style: .default
        ) { [weak self] _ in
            self?.activeFilter = .all
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: activeFilter == .resort ? "✓ Type: Resort" : "Type: Resort",
            style: .default
        ) { [weak self] _ in
            self?.activeFilter = .resort
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: activeFilter == .privateClub ? "✓ Type: Private" : "Type: Private",
            style: .default
        ) { [weak self] _ in
            self?.activeFilter = .privateClub
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: activeFilter == .publicCourse ? "✓ Type: Public" : "Type: Public",
            style: .default
        ) { [weak self] _ in
            self?.activeFilter = .publicCourse
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: activeFilter == .rtj ? "✓ Special: RTJ Trail" : "Special: RTJ Trail",
            style: .default
        ) { [weak self] _ in
            self?.activeFilter = .rtj
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: activeFilter == .resortBrand ? "✓ Special: Resort Brand" : "Special: Resort Brand",
            style: .default
        ) { [weak self] _ in
            self?.activeFilter = .resortBrand
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: locationGrouping == .state ? "✓ Group By: State" : "Group By: State",
            style: .default
        ) { [weak self] _ in
            self?.locationGrouping = .state
            self?.sortMode = .groupedLocation
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(
            title: locationGrouping == .region ? "✓ Group By: Region" : "Group By: Region",
            style: .default
        ) { [weak self] _ in
            self?.locationGrouping = .region
            self?.sortMode = .groupedLocation
            self?.applySearchSortAndFilter()
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.last
        }

        present(ac, animated: true)
    }

    // MARK: - Search / Sort / Filter

    private func applySearchSortAndFilter() {
        let q = searchText.lowercased()

        var working = all.filter { course in
            guard !q.isEmpty else { return true }

            return course.name.lowercased().contains(q)
                || (course.state ?? "").lowercased().contains(q)
                || (course.country ?? "").lowercased().contains(q)
                || (course.region ?? "").lowercased().contains(q)
                || (course.type ?? "").lowercased().contains(q)
        }

        working = working.filter { matchesFilter($0) }
        filtered = working

        switch sortMode {
        case .nameAZ:
            let sorted = working.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            sections = [("All Courses", sorted)]

        case .groupedLocation:
            buildSections(from: working)
        }

        tableView.reloadData()
        updateSummaryHeader()
    }

    private func matchesFilter(_ course: CourseProfile) -> Bool {
        switch activeFilter {
        case .all:
            return true
        case .resort:
            return normalizedType(course.type) == "Resort"
        case .privateClub:
            return normalizedType(course.type) == "Private"
        case .publicCourse:
            return normalizedType(course.type) == "Public"
        case .rtj:
            return isRTJCourse(course)
        case .resortBrand:
            return resortBrandName(for: course) != nil
        case .trump:
            return isTrumpCourse(course)
        case .omni:
            return isOmniCourse(course)
        }
    }
    // MARK: - Grouping

    private func buildSections(from courses: [CourseProfile]) {
        var grouped: [String: [CourseProfile]] = [:]

        for course in courses {
            let country = cleaned(course.country)
            let state = cleaned(course.state)
            let region = cleaned(course.region)

            let sectionTitle: String

            // International always grouped by country
            if !(country.isEmpty || country.caseInsensitiveCompare("USA") == .orderedSame) {
                let internationalCountry = country.isEmpty ? "Unknown" : country
                sectionTitle = "International • \(internationalCountry)"
            } else {
                // USA courses
                let stateTitle = state.isEmpty ? "Unknown" : state

                if locationGrouping == .region, !region.isEmpty {
                    // Region is only shown as a subcategory of state
                    sectionTitle = "\(stateTitle) • \(region)"
                } else {
                    sectionTitle = stateTitle
                }
            }

            grouped[sectionTitle, default: []].append(course)
        }

        let titles = grouped.keys.sorted { lhs, rhs in
            func rank(_ title: String) -> Int {
                if title == "Unknown" { return 98 }
                if title.hasPrefix("International • ") { return 99 }
                return 10
            }

            let lRank = rank(lhs)
            let rRank = rank(rhs)

            if lRank != rRank { return lRank < rRank }

            // Keep state groups together nicely
            let lBase = lhs.components(separatedBy: " • ").first ?? lhs
            let rBase = rhs.components(separatedBy: " • ").first ?? rhs

            if lBase != rBase {
                return lBase.localizedCaseInsensitiveCompare(rBase) == .orderedAscending
            }

            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }

        sections = titles.map { title in
            let items = (grouped[title] ?? []).sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return (title: title, items: items)
        }
    }
    // MARK: - Helpers
    private func isTrumpCourse(_ course: CourseProfile) -> Bool {
        let name = course.name.lowercased()
        return name.contains("trump")
    }

    private func isOmniCourse(_ course: CourseProfile) -> Bool {
        let name = course.name.lowercased()
        return name.contains("omni")
    }
    private func cleaned(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedType(_ raw: String?) -> String {
        let value = cleaned(raw).lowercased()

        switch value {
        case "resort":
            return "Resort"
        case "private":
            return "Private"
        case "public", "daily-fee", "daily fee", "municipal", "semi-private", "semi private":
            return "Public"
        default:
            return cleaned(raw)
        }
    }

    private func isRTJCourse(_ course: CourseProfile) -> Bool {
        let name = course.name.lowercased()
        let type = (course.type ?? "").lowercased()

        return type.contains("rtj")
            || name.contains("rtj")
            || name.contains("robert trent jones")
    }

    private func resortBrandName(for course: CourseProfile) -> String? {
        let name = course.name.lowercased()

        let brands = [
            "omni": "Omni",
            "pinehurst": "Pinehurst",
            "bandon": "Bandon",
            "streamsong": "Streamsong",
            "trump": "Trump",
            "kiawah": "Kiawah",
            "boyne": "Boyne",
            "kohler": "Kohler",
            "sea island": "Sea Island",
            "sand valley": "Sand Valley",
            "big cedar": "Big Cedar"
        ]

        for (key, brand) in brands {
            if name.contains(key) {
                return brand
            }
        }
        return nil
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func addTapped() {
        onTapAddCourse?()
    }

    private func course(at indexPath: IndexPath) -> CourseProfile {
        sections[indexPath.section].items[indexPath.row]
    }

    private func setHomeCourse(_ id: UUID) {
        ProfileStore.homeCourseID = id.uuidString
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseID = "CourseCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseID)

        let course = course(at: indexPath)
        let isBuiltIn = CourseLibrary.shared.isBuiltIn(id: course.id)
        let isSelectedCourse = (course.id == CourseLibrary.shared.selectedCourseID)

        cell.textLabel?.text = course.name
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)

        var parts: [String] = []
        parts.append(isBuiltIn ? "Built-in" : "Custom")

        let type = normalizedType(course.type)
        if !type.isEmpty {
            parts.append(type)
        }

        if let region = course.region, !region.isEmpty, locationGrouping == .region {
            parts.append(region)
        } else if let state = course.state, !state.isEmpty {
            parts.append(state)
        }

        cell.detailTextLabel?.text = parts.joined(separator: " • ")
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 2

        if course.id == homeCourseUUID {
            cell.imageView?.image = UIImage(systemName: "star.fill")
            cell.imageView?.tintColor = .systemYellow
        } else {
            cell.imageView?.image = nil
        }

        cell.accessoryType = .none
        cell.accessoryView = makeAccessoryView(for: course, isSelected: isSelectedCourse)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onPickCourse?(course(at: indexPath).id)
    }

    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let c = course(at: indexPath)

        let home = UIContextualAction(style: .normal, title: "Home") { [weak self] _, _, done in
            self?.setHomeCourse(c.id)
            tableView.reloadData()
            done(true)
        }

        home.backgroundColor = .systemYellow
        home.image = UIImage(systemName: "star.fill")

        let config = UISwipeActionsConfiguration(actions: [home])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let c = course(at: indexPath)

        let info = UIContextualAction(style: .normal, title: "Info") { [weak self] _, _, done in
            self?.showCourseInfo(c)
            done(true)
        }
        info.backgroundColor = .systemTeal
        info.image = UIImage(systemName: "info.circle")

        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
            self?.editCourse(c)
            done(true)
        }
        edit.backgroundColor = .systemBlue
        edit.image = UIImage(systemName: "pencil")

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self else {
                done(false)
                return
            }

            if CourseLibrary.shared.isBuiltIn(id: c.id) {
                let ac = UIAlertController(
                    title: "Can't Delete",
                    message: "\(c.name) is a built-in course.",
                    preferredStyle: .alert
                )
                ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in done(false) })
                self.present(ac, animated: true)
                return
            }

            self.confirmDeleteCourse(c) { didDelete in
                done(didDelete)
            }
        }
        delete.image = UIImage(systemName: "trash")

        let config = UISwipeActionsConfiguration(actions: [delete, edit, info])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // MARK: - Accessory View

    private func makeAccessoryView(for course: CourseProfile, isSelected: Bool) -> UIView? {
        if let promo = course.promo, promo.isActive, promo.type == .deal {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 58, height: 24))
            label.font = .systemFont(ofSize: 10, weight: .bold)
            label.textAlignment = .center
            label.layer.cornerRadius = 7
            label.clipsToBounds = true
            label.text = "DEAL"
            label.backgroundColor = .systemGreen
            label.textColor = .white
            return label
        }

        guard isSelected else { return nil }

        let iv = UIImageView(image: UIImage(systemName: "checkmark"))
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        return iv
    }

    // MARK: - Course Actions

    private func editCourse(_ course: CourseProfile) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as! CourseSetupViewController
        vc.loadCourseID = course.id
        navigationController?.pushViewController(vc, animated: true)
    }

    private func confirmDeleteCourse(_ course: CourseProfile, completion: @escaping (Bool) -> Void) {
        if course.name.caseInsensitiveCompare("WolfMore") == .orderedSame {
            let ac = UIAlertController(
                title: "Can’t Delete",
                message: "WolfMore is the built-in default.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion(false) })
            present(ac, animated: true)
            return
        }

        let ac = UIAlertController(
            title: "Delete \(course.name)?",
            message: "This removes the course from your device.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion(false) })

        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else {
                completion(false)
                return
            }

            if ProfileStore.homeCourseID == course.id.uuidString {
                ProfileStore.homeCourseID = ""
            }

            CourseLibrary.shared.delete(id: course.id)
            self.reloadCourses()
            completion(true)
        })

        present(ac, animated: true)
    }

    private func showCourseInfo(_ c: CourseProfile) {
        var lines: [String] = []

        if let type = c.type, !type.isEmpty { lines.append("Type: \(type)") }
        if let architect = c.architect, !architect.isEmpty { lines.append("Architect: \(architect)") }
        if let state = c.state, !state.isEmpty { lines.append("State: \(state)") }
        if let country = c.country, !country.isEmpty { lines.append("Country: \(country)") }
        if let address = c.address, !address.isEmpty { lines.append("Address: \(address)") }
        if let phone = c.phone, !phone.isEmpty { lines.append("Phone: \(phone)") }
        if let website = c.website, !website.isEmpty { lines.append("Website: \(website)") }
        if c.isWolfApproved == true { lines.append("WolfMore Approved") }

        let message = lines.isEmpty ? "No extra course details yet." : lines.joined(separator: "\n")

        let ac = UIAlertController(title: c.name, message: message, preferredStyle: .actionSheet)

        if let phone = c.phone?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty {
            ac.addAction(UIAlertAction(title: "Call Course", style: .default) { _ in
                let cleaned = phone.filter { "0123456789+".contains($0) }
                if let url = URL(string: "tel://\(cleaned)"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
        }

        if let website = c.website?.trimmingCharacters(in: .whitespacesAndNewlines), !website.isEmpty {
            ac.addAction(UIAlertAction(title: "Open Website", style: .default) { _ in
                var text = website
                if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
                    text = "https://\(text)"
                }
                if let url = URL(string: text), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
        }

        if let address = c.address?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty {
            ac.addAction(UIAlertAction(title: "Open in Maps", style: .default) { _ in
                let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
                if let url = URL(string: "http://maps.apple.com/?q=\(encoded)"),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
        }

        ac.addAction(UIAlertAction(title: "Close", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }

        present(ac, animated: true)
    }

    // MARK: - Search Updating

    func updateSearchResults(for searchController: UISearchController) {
        applySearchSortAndFilter()
    }
}
