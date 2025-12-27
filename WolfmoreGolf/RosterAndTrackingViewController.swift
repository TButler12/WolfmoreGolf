//
//  RosterAndTrackingViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/24/25.
//
import UIKit

// MARK: - Cell

final class RosterPlayerCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var hcField: UITextField!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var trackButton: UIButton!

    /// Called when the star is tapped; Bool is the NEW on/off value.
    var trackToggled: ((Bool) -> Void)?
    /// Called when the active switch changes; Bool is the NEW on/off value.
    var activeToggled: ((Bool) -> Void)?

    @IBAction private func trackButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        trackToggled?(sender.isSelected)
    }

    @IBAction private func activeSwitchChanged(_ sender: UISwitch) {
        activeToggled?(sender.isOn)
    }
}

// MARK: - View controller

final class RosterAndTrackingViewController: UIViewController,
                                             UITableViewDataSource,
                                             UITableViewDelegate,
                                             UITextFieldDelegate {

    // Table view in the scene
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Row model

    private struct RowModel {
        var friend: Friend
        var hc: Int
        var isActive: Bool
        var isTracked: Bool
    }

    private var rows: [RowModel] = []
    private let trackLimit = 30

    // Use the same key everywhere for tracking
    private var courseID: String {
        let stored = ProfileStore.homeCourseID
        return stored.isEmpty ? "HOME-COURSE" : stored
    }

    // MARK: - Outlets

    @IBOutlet private weak var goToGameButton: UIButton!
    @IBOutlet private weak var courseLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Players & Tracking"

        // Hook up table
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()

        // Make sure we have a game
        if GameManager.shared.currentGame == nil {
            if !GameManager.shared.loadLastOpened() {
                GameManager.shared.startNewGame()
            }
        }

        // Seed FriendStore once if needed
        seedFriendsFromCurrentGameIfNeeded()

        rebuildRowsFromStores()
        updateGoButtonState()
        updateCourseLabel()
    }
    // MARK: - User interaction

    @objc private func activeToggled(_ sender: UISwitch) {
        let idx = sender.tag
        guard rows.indices.contains(idx) else { return }

        // Update our row model
        rows[idx].isActive = sender.isOn

        // Enable / disable the Go To Game button
        updateGoButtonState()
    }

    // MARK: - Seed + Build rows

    /// If there are no friends yet, seed from the current game’s card.
    private func seedFriendsFromCurrentGameIfNeeded() {
        guard FriendStore.shared.friends.isEmpty,
              let g = GameManager.shared.currentGame else { return }

        let names = g.playerNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !names.isEmpty {
            FriendStore.shared.merge(names: names)
        }
    }

    /// Rebuild row models from FriendStore + current game + FriendTrackStore.
    private func rebuildRowsFromStores() {
        let friends = FriendStore.shared.friends.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        let g = GameManager.shared.currentGame

        rows = friends.map { friend in
            var hc = 0
            var isActive = false

            if let g = g {
                let seats = 0..<min(
                    5,
                    min(g.playerNames.count,
                        min(g.playerActivated.count, g.hcPlayers.count))
                )

                if let seat = seats.first(where: { i in
                    g.playerNames[i]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .caseInsensitiveCompare(friend.name) == .orderedSame
                }) {
                    hc = g.hcPlayers[seat]
                    isActive = g.playerActivated[seat]
                }
            }

            let tracked = FriendTrackStore.shared.isTracked(friend.id, on: courseID)

            return RowModel(friend: friend,
                            hc: hc,
                            isActive: isActive,
                            isTracked: tracked)
        }

        tableView.reloadData()
    }
    private func showTrackLimitAlert() {
        let ac = UIAlertController(
            title: "Limit Reached",
            message: "You can track up to \(trackLimit) friends for this course.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func updateCourseLabel() {
        guard let g = GameManager.shared.currentGame else {
            courseLabel.text = "Course: (none)"
            return
        }

        let currentPars = Array(g.course.pars.prefix(18))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(18))

        let match = CourseLibrary.shared.courses.first { c in
            Array(c.pars.prefix(18)) == currentPars &&
            Array(c.hcs.prefix(18))  == currentHCs
        }

        if let course = match {
            let isHome = (course.id.uuidString == ProfileStore.homeCourseID)
            courseLabel.text = isHome ? "Course: ⭐ \(course.name)"
                                      : "Course: \(course.name)"
        } else {
            courseLabel.text = "Course: Custom"
        }
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "RosterPlayerCell",
            for: indexPath
        ) as? RosterPlayerCell else {
            return UITableViewCell()
        }

        let row = rows[indexPath.row]

        // Name
        cell.nameLabel?.text = row.friend.name

        // HC field
        cell.hcField?.text = row.hc == 0 ? "" : String(row.hc)
        cell.hcField?.keyboardType = .numberPad
        cell.hcField?.delegate = self
        cell.hcField?.tag = indexPath.row

        // Active switch
        cell.activeSwitch?.isOn = row.isActive
        cell.activeSwitch?.tag = indexPath.row
        cell.activeSwitch?.addTarget(self,
                                     action: #selector(activeToggled(_:)),
                                     for: .valueChanged)

        // ⭐ tracking star
        cell.trackButton?.isSelected = row.isTracked
        let rowIndex = indexPath.row

        cell.trackToggled = { [weak self, weak cell] isOn in
            guard let self = self else { return }
            guard self.rows.indices.contains(rowIndex) else { return }

            let previous = self.rows[rowIndex].isTracked
            let friend = self.rows[rowIndex].friend

            let changed = FriendTrackStore.shared.toggle(
                friend.id,
                courseID: self.courseID,
                limit: self.trackLimit
            )

            if changed {
                self.rows[rowIndex].isTracked = isOn
            } else {
                self.rows[rowIndex].isTracked = previous
                cell?.trackButton?.isSelected = previous
                self.showTrackLimitAlert()
            }
        }

        return cell
    }


    private func updateGoButtonState() {
        // For now: always allow going to the game.
        goToGameButton.isEnabled = true
        goToGameButton.alpha = 1.0
    }

    // MARK: - Go to Game

    @IBAction private func goToGameTapped(_ sender: UIButton) {
        print("✅ goToGameTapped fired")

        let activeRows = rows.filter { $0.isActive }
        guard !activeRows.isEmpty else {
            print("⚠️ No active rows")
            return
        }
      
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showGame" else { return }

        if let nav = segue.destination as? UINavigationController,
           let dest = nav.topViewController as? GameViewController {
            dest.playersFallback = nil
        } else if let dest = segue.destination as? GameViewController {
            dest.playersFallback = nil
        }
    }
}

