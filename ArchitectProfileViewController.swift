import UIKit

final class ArchitectProfileViewController: UITableViewController {

    private let profile: ArchitectProfile

    init(profile: ArchitectProfile) {
        self.profile = profile
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = profile.name
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BioCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CourseCell")
        tableView.estimatedRowHeight = 60
    }

    // MARK: - Sections

    private var hasBio: Bool { profile.bio != nil }

    private enum Section { static let bio = 0; static let courses = 1 }

    override func numberOfSections(in tableView: UITableView) -> Int { hasBio ? 2 : 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasBio && section == Section.bio { return 1 }
        return profile.courses.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if hasBio && section == Section.bio { return "About" }
        let n = profile.courses.count
        return n == 1 ? "1 Course in WolfMore" : "\(n) Courses in WolfMore"
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if hasBio && indexPath.section == Section.bio {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BioCell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = profile.bio
            config.textProperties.numberOfLines = 0
            config.textProperties.font = .systemFont(ofSize: 15)
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseCell", for: indexPath)
        let course = profile.courses[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = course.name
        config.textProperties.font = .systemFont(ofSize: 16, weight: .medium)

        var parts: [String] = []
        if let state = course.state, !state.isEmpty { parts.append(state) }
        if let country = course.country, country != "USA", !country.isEmpty { parts.append(country) }
        if let type = course.type, !type.isEmpty { parts.append(type) }
        config.secondaryText = parts.joined(separator: " • ")
        config.secondaryTextProperties.color = .secondaryLabel

        cell.contentConfiguration = config
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        (hasBio && indexPath.section == Section.bio) ? UITableView.automaticDimension : 50
    }
}
