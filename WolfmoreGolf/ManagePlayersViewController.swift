//
//  ManagePlayersViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/27/25.
//
import UIKit

final class ManagePlayersViewController: UIViewController,
                                         UITableViewDataSource,
                                         UITableViewDelegate,
                                         UITextFieldDelegate {

    
    private let maxActivePlayers = 9   // 👈 new

    @IBOutlet private weak var tableView: UITableView!
    
    // Read-only view into FriendStore
    private var friends: [Friend] {
        FriendStore.shared.friends
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Manage Players"
        tableView.dataSource = self
        tableView.delegate   = self

        // Tap anywhere to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false   // so table cells still receive taps
        view.addGestureRecognizer(tap)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addFriendTapped)
        )
        navigationItem.hidesBackButton = true

              // (Optional) also disable the swipe-to-go-back gesture
              navigationController?.interactivePopGestureRecognizer?.isEnabled = false
          
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()   // refresh if list changed elsewhere
    }

    @objc private func endEditingTap() {
        view.endEditing(true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    private func showActiveLimitAlert() {
        let ac = UIAlertController(
            title: "Player Limit",
            message: "You can only activate up to \(maxActivePlayers) players.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // MARK: - Add player

    @objc private func addFriendTapped() {
        let ac = UIAlertController(
            title: "Add Player",
            message: nil,
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            tf.placeholder = "Player name"
            tf.autocapitalizationType = .words
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let name = ac.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return }

            FriendStore.shared.add(name: name)
            self.tableView.reloadData()
        })

        present(ac, animated: true)
    }

    // MARK: - TableView Data Source

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        friends.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "FriendCell",
            for: indexPath
        ) as? ManagePlayerCell else {
            return UITableViewCell()
        }

        let friend = friends[indexPath.row]
        let friendID = friend.id

        // Configure UI
        cell.nameLabel.text = friend.name
        cell.hcField.text   = friend.defaultHC == 0 ? "" : String(friend.defaultHC)
        cell.activeSwitch.isOn = friend.preselectForRound

        // HC changed
        cell.hcChanged = { newHC in
            FriendStore.shared.update(friendID: friendID,
                                      defaultHC: newHC)
        }

        // 🔒 limit to 9 active players
        cell.activeChanged = { [weak self, weak cell] isOn in
            guard let self = self else { return }

            if isOn {
                // How many are currently active?
                let currentActive = FriendStore.shared.preselectedCount
                if currentActive >= self.maxActivePlayers {
                    // Over the limit – revert switch & show alert
                    cell?.activeSwitch.setOn(false, animated: true)
                    self.showActiveLimitAlert()
                    return
                }
            }

            // Within limit or turning OFF – save the new state
            FriendStore.shared.update(friendID: friendID,
                                      preselectForRound: isOn)
        }

        return cell
    }


    // MARK: - Delete (swipe to delete)

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else { return }

        let friend = friends[indexPath.row]
        FriendStore.shared.remove(friendID: friend.id)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    // MARK: - Start round from Manage Players
    @IBAction private func closeTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func startRoundTapped(_ sender: UIButton) {
        print("▶️ Start Round tapped (from Manage Players)")

        // 1. Collect selected players (preselectForRound == true)
        let selected = FriendStore.shared.friends.filter { $0.preselectForRound }
        guard !selected.isEmpty else {
            let ac = UIAlertController(
                title: "No Players Selected",
                message: "Turn on at least one Activate switch, then try again.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }

        // Cap at 9 seats
        let active = Array(selected.prefix(9))

        // 2. Push these into GameManager as the current card
        GameManager.shared.update { g in
            if g.playerNames.count != 9     { g.playerNames     = Array(repeating: "",    count: 9) }
            if g.hcPlayers.count != 9       { g.hcPlayers       = Array(repeating: 0,     count: 9) }
            if g.playerActivated.count != 9 { g.playerActivated = Array(repeating: false, count: 9) }

            for (seat, friend) in active.enumerated() {
                g.playerNames[seat]     = friend.name
                g.hcPlayers[seat]       = friend.defaultHC
                g.playerActivated[seat] = true
            }

            if active.count < 9 {
                for seat in active.count..<9 {
                    g.playerNames[seat]     = ""
                    g.hcPlayers[seat]       = 0
                    g.playerActivated[seat] = false
                }
            }

            g.hole = 0
        }

        // 3. Present the SAME round navigation flow that Home uses
        guard let roundNav = storyboard?.instantiateViewController(
            withIdentifier: "RoundNav"
        ) as? UINavigationController else {
            print("⚠️ Could not find RoundNav in storyboard")
            return
        }

        // Present modally, just like the Home "Play Game" button does
        present(roundNav, animated: true)
    }

}
