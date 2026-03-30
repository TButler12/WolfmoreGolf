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
    
    // Callbacks
    var onPickCourse: ((UUID) -> Void)?
    var onTapAddCourse: (() -> Void)?
    
    // Data
    private var all: [CourseProfile] = []
    private var filtered: [CourseProfile] = []
    
    // Sections (e.g., "IL", "WI", "FL", "Ireland", "Northern Ireland")
    
    private var sections: [(title: String, items: [CourseProfile])] = []
    // Search
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchText: String {
        (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Home course star
    private var homeCourseUUID: UUID? {
        let s = ProfileStore.homeCourseID.trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: s)
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
    @objc private func filterTapped() {
        let ac = UIAlertController(title: "Sort / Filter", message: nil, preferredStyle: .actionSheet)

        // Sort
        ac.addAction(UIAlertAction(title: "Sort: Grouped (Location)", style: .default) { [weak self] _ in
            self?.sortMode = .groupedLocation
            self?.applyFilter()
        })
        ac.addAction(UIAlertAction(title: "Sort: Name (A–Z)", style: .default) { [weak self] _ in
            self?.sortMode = .name
            self?.applyFilter()
        })

        ac.addAction(UIAlertAction(title: "Filter: All Types", style: .default) { [weak self] _ in
            self?.typeFilter = nil
            self?.applyFilter()
        })

        // Type options (build from your data so it never gets out of sync)
        let types = Set(all.compactMap { $0.type?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty })

        for t in types.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }) {
            ac.addAction(UIAlertAction(title: "Type: \(t)", style: .default) { [weak self] _ in
                self?.typeFilter = t
                self?.applyFilter()
            })
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safety
        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.last
        }

        present(ac, animated: true)
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

        // give it an initial height (we’ll also update it below)
        summaryHeader.frame.size.height = 52
        tableView.tableHeaderView = summaryHeader
    }

    private func updateSummaryHeader() {
        let total = all.count
        let builtInCount = all.filter { CourseLibrary.shared.isBuiltIn(id: $0.id) }.count
        let customCount = total - builtInCount

        summaryLabel1.text = "Loaded courses: \(total)"
        summaryLabel2.text = "Built-in: \(builtInCount)   •   Custom: \(customCount)"

        // Keep header height correct after text changes / rotations
        summaryHeader.setNeedsLayout()
        summaryHeader.layoutIfNeeded()
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = summaryHeader.systemLayoutSizeFitting(targetSize).height
        if summaryHeader.frame.height != height {
            var f = summaryHeader.frame
            f.size.height = height
            summaryHeader.frame = f
            tableView.tableHeaderView = summaryHeader
        }
    }
    private func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search courses"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    // MARK: - Data
    
    private func reloadCourses() {
        all = CourseLibrary.shared.allSorted()

        if let wj = all.first(where: { $0.name == "WJ Golf at Arboretum Golf Club" }) {
            print("RELOAD WJ:", wj.name, wj.promo?.title ?? "no promo")
        }

        applyFilter()
        updateSummaryHeader()
    }
    
    private func inferredType(for name: String) -> String? {

        let n = name.lowercased()

        if n.contains("resort") { return "Resort" }
        if n.contains("dunes") { return "Resort" }
        if n.contains("valley") { return "Resort" }
        if n.contains("national") { return "Private" }
        if n.contains("club") { return "Private" }
        if n.contains("country club") { return "Private" }
        if n.contains("municipal") { return "Daily-Fee" }
        if n.contains("golf course") { return "Daily-Fee" }

        return nil
    }
    private func applyFilter() {
        // 1) Start from all
        var list = all

        // 2) Filter by search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) }
        }

        // 3) Filter by type (Resort, Private, Daily-Fee, etc.)
        if let typeFilter = typeFilter?.lowercased() {
            list = list.filter { ($0.type ?? "").lowercased() == typeFilter }
        }

        filtered = list

        // 4) Sort / group
        switch sortMode {
        case .groupedLocation:
            buildSections()          // uses filtered
        case .name:
            sections = [("All Courses", filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            })]
        }

        tableView.reloadData()
        updateSummaryHeader() // if you added the header counts earlier
    }
    
    // MARK: - Grouping
    
    private func isUSA(_ country: String?) -> Bool {
        let t = (country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return true } // treat nil as USA default in your app
        return t.caseInsensitiveCompare("USA") == .orderedSame
        || t.caseInsensitiveCompare("United States") == .orderedSame
        || t.caseInsensitiveCompare("United States of America") == .orderedSame
    }

    private func sectionSortKey(_ title: String) -> (Int, String) {
        if title == "RTJ Trail" {
            return (0, title)
        }
        return (1, title)
    }
   
    private func buildSections() {
        let source = filtered

        let rtjCourses = source.filter {
            ($0.type ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == "RTJ Trail"
        }

        let nonRTJ = source.filter {
            ($0.type ?? "").trimmingCharacters(in: .whitespacesAndNewlines) != "RTJ Trail"
        }

        var newSections: [(title: String, items: [CourseProfile])] = []

        if !rtjCourses.isEmpty {
            let sortedRTJ = rtjCourses.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            newSections.append(("AL • RTJ Trail", sortedRTJ))
        }

        let groupedByState = Dictionary(grouping: nonRTJ) { course in
            let state = (course.state ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return state.isEmpty ? "Other" : state
        }

        let sortedStates = groupedByState.keys.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }

        for state in sortedStates {
            let stateItems = groupedByState[state] ?? []

            let groupedByRegion = Dictionary(grouping: stateItems) { course -> String in
                if course.venueType == .indoorGolf {
                    return "Indoor"
                }

                let region = (course.region ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return region
            }

            let sortedRegions = groupedByRegion.keys.sorted { lhs, rhs in
                let lhsIsIndoor = lhs.caseInsensitiveCompare("Indoor") == .orderedSame
                let rhsIsIndoor = rhs.caseInsensitiveCompare("Indoor") == .orderedSame

                if lhsIsIndoor != rhsIsIndoor { return lhsIsIndoor }

                if lhs.isEmpty && !rhs.isEmpty { return false }
                if !lhs.isEmpty && rhs.isEmpty { return true }

                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }

            for region in sortedRegions {
                let items = (groupedByRegion[region] ?? []).sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }

                let title: String
                if region.isEmpty {
                    title = state
                } else {
                    title = "\(state) • \(region)"
                }

                newSections.append((title: title, items: items))
            }
        }

        sections = newSections
    }
    private enum CourseRow {
        case regionHeader(String)
        case course(CourseProfile)
    }
    private func isUSAStateTitle(_ title: String) -> Bool {
        if title == "USA (No State)" { return false }
        if title.count == 2 { return true }
        if title.hasPrefix("CA — ") { return true }
        return false
    }
    private func course(at indexPath: IndexPath) -> CourseProfile {
        sections[indexPath.section].items[indexPath.row]
    }
    
    private func setHomeCourse(_ id: UUID) {
        ProfileStore.homeCourseID = id.uuidString
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func addTapped() { onTapAddCourse?() }
    
    // MARK: - UITableView
    
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

        let c = course(at: indexPath)
        cell.textLabel?.text = c.name
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        print(c.name, c.promo?.type.rawValue ?? "no promo", c.promo?.isActive ?? false)
        let isSelectedCourse = (c.id == CourseLibrary.shared.selectedCourseID)

        // Do NOT use accessoryType anymore if showing promo badge
        cell.accessoryType = .none
        cell.accessoryView = makeAccessoryView(for: c, isSelected: isSelectedCourse)

        // ⭐ Home course
        if c.id == homeCourseUUID {
            cell.imageView?.image = UIImage(systemName: "star.fill")
            cell.imageView?.tintColor = .systemYellow
        } else {
            cell.imageView?.image = nil
        }

        let isBuiltIn = CourseLibrary.shared.isBuiltIn(id: c.id)

        var parts: [String] = []
        parts.append(isBuiltIn ? "Built-in" : "Custom")

        if let type = c.type, !type.isEmpty {
            parts.append(type)
        }

        if let state = c.state, !state.isEmpty {
            if state == "CA", let region = c.region, !region.isEmpty {
                parts.append(region)
            } else {
                parts.append(state)
            }
        }
        print(c.name, c.promo?.type.rawValue ?? "no promo", c.promo?.isActive ?? false)
        var iconText = ""

        //if c.hasPhone { iconText += "  📞" }
       // if c.hasWebsite { iconText += "  🌐" }
       // if c.hasAddress { iconText += "  📍" }
       // if c.isApproved { iconText += "  🐺" }
        
     
        cell.detailTextLabel?.text = parts.joined(separator: " • ") + iconText
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 2

        return cell
    }
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let c = course(at: indexPath)
        onPickCourse?(c.id)
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
    // Swipe actions: Home ⭐, Edit ✏️, Delete 🗑️
 
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
                ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    done(false)
                })
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
    
    private func promoText(for course: CourseProfile) -> String? {
        guard let promo = course.promo, promo.isActive else { return nil }

        let kind: String
        switch promo.type {
        case .deal: kind = "Deal"
        case .event: kind = "Event"
        case .featured: kind = "Featured"
        }

        if let subtitle = promo.subtitle, !subtitle.isEmpty {
            return "\(kind): \(promo.title)\n\(subtitle)"
        } else {
            return "\(kind): \(promo.title)"
        }
    }

    private func makeAccessoryView(for course: CourseProfile, isSelected: Bool) -> UIView? {
        if let promo = course.promo,
           promo.isActive,
           promo.type == .deal {
            return makeDealBadge(for: promo)
        }

        guard isSelected else { return nil }

        let iv = UIImageView(image: UIImage(systemName: "checkmark"))
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        return iv
    }

    private func makeDealBadge(for promo: LocationPromo) -> UIView {
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
    final class PaddingLabel: UILabel {
        var textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.inset(by: textInsets))
        }

        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            return CGSize(
                width: size.width + textInsets.left + textInsets.right,
                height: size.height + textInsets.top + textInsets.bottom
            )
        }
    }
    private func showCourseInfo(_ c: CourseProfile) {
        var lines: [String] = []

        if let type = c.type, !type.isEmpty {
            lines.append("Type: \(type)")
        }
        if let architect = c.architect, !architect.isEmpty {
            lines.append("Architect: \(architect)")
        }
        if let state = c.state, !state.isEmpty {
            lines.append("State: \(state)")
        }
        if let country = c.country, !country.isEmpty {
            lines.append("Country: \(country)")
        }
        if let address = c.address, !address.isEmpty {
            lines.append("Address: \(address)")
        }
        if let phone = c.phone, !phone.isEmpty {
            lines.append("Phone: \(phone)")
        }
        if let website = c.website, !website.isEmpty {
            lines.append("Website: \(website)")
        }

        if let promo = promoText(for: c) {
            lines.append("")
            lines.append(promo)
        }

        if c.isApproved {
            lines.append("WolfMore Approved")
        }

        let message = lines.isEmpty ? "No extra course details yet." : lines.joined(separator: "\n")

        let ac = UIAlertController(title: c.name, message: message, preferredStyle: .actionSheet)

        if let phone = c.phone?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty {
            ac.addAction(UIAlertAction(title: "Call Course", style: .default) { _ in
                let cleaned = phone.filter { "0123456789+".contains($0) }
                if let url = URL(string: "tel://\(cleaned)"),
                   UIApplication.shared.canOpenURL(url) {
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
                if let url = URL(string: text),
                   UIApplication.shared.canOpenURL(url) {
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
    // MARK: - Edit / Delete helpers
    private enum SortMode { case groupedLocation, name }
    private var sortMode: SortMode = .groupedLocation

    private var typeFilter: String? = nil  // nil = All
    private func editCourse(_ c: CourseProfile) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "CourseSetupVC") as! CourseSetupViewController
        vc.loadCourseID = c.id
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func confirmDeleteCourse(_ c: CourseProfile, completion: @escaping (Bool) -> Void) {
        
        if c.name.caseInsensitiveCompare("WolfMore") == .orderedSame {
            let ac = UIAlertController(
                title: "Can’t Delete",
                message: "WolfMore is the built-in default.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion(false)
            })
            present(ac, animated: true)
            return
        }
        
        let ac = UIAlertController(
            title: "Delete \(c.name)?",
            message: "This removes the course from your device.",
            preferredStyle: .alert
        )
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { completion(false); return }
            
            if ProfileStore.homeCourseID == c.id.uuidString {
                ProfileStore.homeCourseID = ""
            }
            
            CourseLibrary.shared.delete(id: c.id)
            self.reloadCourses()
            completion(true)
        })
        
        present(ac, animated: true)
    }
    
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter()
    }
}
private extension CourseProfile {
    var hasPhone: Bool {
        !(phone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var hasWebsite: Bool {
        !(website?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var hasAddress: Bool {
        !(address?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var isApproved: Bool {
        isWolfApproved == true
    }
}
