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
        
        // Keep WolfMore at top of its section later
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
    
    private func sectionTitle(for c: CourseProfile) -> String {
        if isUSA(c.country) {
            let st = (c.state ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return st.isEmpty ? "USA (No State)" : st
        } else {
            let ct = (c.country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return ct.isEmpty ? "International" : ct
        }
    }
    
    
    private func buildSections() {
        
        let grouped = Dictionary(grouping: filtered, by: sectionTitle(for:))
        
        var built: [(title: String, items: [CourseProfile])] = grouped.map { title, items in
            let sortedItems = items.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return (title: title, items: sortedItems)
        }
        
        // Pin WolfMore to top of its section
        for i in built.indices {
            if let idx = built[i].items.firstIndex(where: {
                $0.name.caseInsensitiveCompare("WolfMore") == .orderedSame
            }) {
                let w = built[i].items.remove(at: idx)
                built[i].items.insert(w, at: 0)
            }
        }
        
        // 🔥 THIS is the important part:
        built.sort { a, b in
            
            let aIsUSAState = isUSAStateTitle(a.title)
            let bIsUSAState = isUSAStateTitle(b.title)
            
            // USA states always first
            if aIsUSAState != bIsUSAState {
                return aIsUSAState && !bIsUSAState
            }
            
            // Alphabetical inside their group
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
        
        sections = built
    }
    private func isUSAStateTitle(_ title: String) -> Bool {
        // If it's 2 letters and not "USA (No State)", treat as state
        return title.count == 2 && title != "USA (No State)"
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

        // ✓ Selected course
        cell.accessoryType = (c.id == CourseLibrary.shared.selectedCourseID) ? .checkmark : .none

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
            parts.append(state)
        }

        var iconText = ""

        if c.hasPhone { iconText += "  📞" }
        if c.hasWebsite { iconText += "  🌐" }
        if c.isApproved { iconText += "  🐺" }

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
    
    // Swipe actions: Home ⭐, Edit ✏️, Delete 🗑️
    // Swipe actions: Home ⭐, Edit ✏️, Delete 🗑️
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let c = course(at: indexPath)
        var actions: [UIContextualAction] = []

        let home = UIContextualAction(style: .normal, title: "Home") { [weak self] _, _, done in
            self?.setHomeCourse(c.id)
            tableView.reloadData()
            done(true)
        }
        home.backgroundColor = .systemYellow
        home.image = UIImage(systemName: "star.fill")
        actions.append(home)

        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
            self?.editCourse(c)
            done(true)
        }
        edit.backgroundColor = .systemBlue
        edit.image = UIImage(systemName: "pencil")
        actions.append(edit)

        let info = UIContextualAction(style: .normal, title: "Info") { [weak self] _, _, done in
            self?.showCourseInfo(c)
            done(true)
        }
        info.backgroundColor = .systemTeal
        info.image = UIImage(systemName: "info.circle")
        actions.append(info)

        if c.hasPhone {
            let phone = UIContextualAction(style: .normal, title: "Call") { _, _, done in
                let cleaned = (c.phone ?? "").filter { "0123456789+".contains($0) }
                if let url = URL(string: "tel://\(cleaned)"),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                done(true)
            }
            phone.backgroundColor = .systemGreen
            phone.image = UIImage(systemName: "phone.fill")
            actions.append(phone)
        }

        if c.hasWebsite {
            let web = UIContextualAction(style: .normal, title: "Web") { _, _, done in
                var text = c.website?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
                    text = "https://\(text)"
                }
                if let url = URL(string: text) {
                    UIApplication.shared.open(url)
                }
                done(true)
            }
            web.backgroundColor = .systemIndigo
            web.image = UIImage(systemName: "globe")
            actions.append(web)
        }

        if c.isApproved {
            let wolf = UIContextualAction(style: .normal, title: "Wolf") { [weak self] _, _, done in
                let ac = UIAlertController(
                    title: "WolfMore Approved",
                    message: "\(c.name) is marked as a WolfMore Approved course.",
                    preferredStyle: .alert
                )
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(ac, animated: true)
                done(true)
            }
            wolf.backgroundColor = .systemOrange
            wolf.image = UIImage(systemName: "checkmark.seal.fill")
            actions.append(wolf)
        }

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self else { done(false); return }

            if CourseLibrary.shared.isBuiltIn(id: c.id) {
                let ac = UIAlertController(
                    title: "Can’t Delete",
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
        actions.append(delete)

        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = false
        return config
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
        if c.isApproved {
            lines.append("WolfMore Approved")
        }

        let message = lines.isEmpty ? "No extra course details yet." : lines.joined(separator: "\n")

        let ac = UIAlertController(title: c.name, message: message, preferredStyle: .actionSheet)

        if let phone = c.phone, !phone.isEmpty {
            ac.addAction(UIAlertAction(title: "Call", style: .default) { _ in
                let cleaned = phone.filter { "0123456789+".contains($0) }
                if let url = URL(string: "tel://\(cleaned)"),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
        }

        if let website = c.website, !website.isEmpty {
            ac.addAction(UIAlertAction(title: "Open Website", style: .default) { _ in
                var text = website.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
                    text = "https://\(text)"
                }
                if let url = URL(string: text) {
                    UIApplication.shared.open(url)
                }
            })
        }

        if let address = c.address, !address.isEmpty {
            ac.addAction(UIAlertAction(title: "Open in Maps", style: .default) { _ in
                let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
                if let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
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
