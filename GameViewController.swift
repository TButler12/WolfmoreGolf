//
//  GameViewController.swift
//  Wolfmore-7 Man

import UIKit
import MessageUI

extension UIImage {
    static func pixel(of color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        color.setFill(); UIRectFill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
    }
}
final class GameViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
     var isUmbrella: Bool = false   // true = mute double for ENTIRE game
    @IBAction private func closeTapped(_ sender: Any) {
        // capture the presenter BEFORE dismiss
        let presenter = navigationController?.presentingViewController ?? presentingViewController

        dismiss(animated: true) {
            // if presenter (ManagePlayers) is on a nav stack, pop to Home
            presenter?.navigationController?.popToRootViewController(animated: true)
        }
    }

    // MARK: - Outlets
    
    
    @IBOutlet private weak var umbrellaButton: UIButton!

    @IBOutlet weak var holeStatsTapped: UIView!
    
    @IBOutlet private weak var plusPointDollars: UIButton!
    @IBOutlet private weak var minusPointDollars: UIButton!
    @IBOutlet private weak var updateDollars: UIButton!
    
    @IBOutlet private weak var gameDollarsField: UILabel!
   
    
    @IBOutlet private weak var parOfHole: UILabel!
    
    @IBOutlet private weak var holePlaying: UILabel!
    
    @IBOutlet weak var alonePushed: UIButton!
    @IBOutlet private var scoreFields: [UITextField]!
    @IBOutlet private var playerMoneyFields: [UITextField]!
    
    @IBOutlet private var totalMoneyLabels: [UILabel]!
    
    @IBOutlet private var playerStrokesFields: [UITextField]!
    @IBOutlet private var playerNameLabels: [UILabel]!

    
    @IBOutlet weak var pressedPushed2: UIButton!
    
    @IBOutlet weak var rerollPushed: UIButton!
    
    @IBOutlet weak var rollPushed: UIButton!
    @IBOutlet weak var w0: UIButton!
    @IBOutlet weak var w1: UIButton!
    @IBOutlet weak var w2: UIButton!
    @IBOutlet weak var w3: UIButton!
    @IBOutlet weak var w4: UIButton!
    @IBOutlet weak var w5: UIButton!
    @IBOutlet weak var w6: UIButton!
    @IBOutlet weak var w7: UIButton!
    @IBOutlet weak var w8: UIButton!
    
    private var wolfButtons: [UIButton] { [w0, w1, w2, w3, w4] }
   
    @IBOutlet private weak var p0: UIButton!
    @IBOutlet private weak var p1: UIButton!
    @IBOutlet private weak var p2: UIButton!
    @IBOutlet private weak var p3: UIButton!
    @IBOutlet private weak var p4: UIButton!
    @IBOutlet private weak var p5: UIButton!
    @IBOutlet private weak var p6: UIButton!
    @IBOutlet private weak var p7: UIButton!
    
    @IBOutlet private weak var p8: UIButton!
    
    @IBOutlet weak var UpdateScores: UIButton!
    
    @IBOutlet weak var hammerButton: UIButton!
   // @IBOutlet weak var hammerLabel: UILabel!

    @IBOutlet weak var rejectHammerButton: UIButton!
    
    @IBAction private func hammerTapped(_ sender: UIButton) {
        var newCount = 0

        GameManager.shared.update { g in
            g.normalize(holes: STANDARD_HOLES)

            let h = max(0, min(17, g.hole))

            if g.hammerCountPerHole == nil || g.hammerCountPerHole?.count != STANDARD_HOLES {
                g.hammerCountPerHole = Array(repeating: 0, count: STANDARD_HOLES)
            }

            g.hammerCountPerHole![h] += 1
            newCount = g.hammerCountPerHole![h]
        }

        updateHammerButton(hammerButton, hammerCount: newCount)
        refreshDollarsLabel()
        setRejectHammerEnabled(newCount > 0)
    }

    @IBOutlet private weak var wolfControlsStack: UIStackView!
    @IBOutlet private weak var scotchControlsStack: UIStackView!

    
    @IBAction private func rejectHammerTapped(_ sender: UIButton) {
        var newCount = 0

        GameManager.shared.update { g in
            g.normalize(holes: STANDARD_HOLES)

            let h = max(0, min(17, g.hole))

            if g.hammerCountPerHole == nil || g.hammerCountPerHole?.count != STANDARD_HOLES {
                g.hammerCountPerHole = Array(repeating: 0, count: STANDARD_HOLES)
            }

            g.hammerCountPerHole![h] = max(0, g.hammerCountPerHole![h] - 1)
            newCount = g.hammerCountPerHole![h]
        }

        updateHammerButton(hammerButton, hammerCount: newCount)
        refreshDollarsLabel()
        setRejectHammerEnabled(newCount > 0)
    }
    private let holeStatsSwitch = UISwitch()
    private var hasPromptedForThisHole = false
    private var proxButtons: [UIButton] { [p0, p1, p2, p3, p4] }

    private var currentHole: Int = 0

    // Programmatic header labels replacing the fixed "Hole / Par" storyboard labels
    private weak var holeInfoLabel: UILabel?
    private weak var courseHeaderLabel: UILabel?

    var hole = (0)
 
    var playersFallback: [Player]?
    
    private var game: GameData? { GameManager.shared.currentGame }

    
    // MARK: - State
    
    private var isUmbrellaOn = false
    
    @IBAction private func textHubTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TextVC") // your Storyboard ID

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]      // collapsible sizes
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 18
        }

        present(nav, animated: true)
    }
   
    @IBAction func nassauTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NassauViewController") as! NassauViewController
        vc.gameData = GameManager.shared.currentGame

        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    @IBOutlet private weak var gameModeSegment: UISegmentedControl!
    @IBOutlet weak var nassauButton: UIButton?

    // MARK: - Player Sort
    private var isSortedByDollarGame = false
    private weak var sortButton: UIButton?
    private var sortButtonInstalled = false

    private var displayOrder: [Int] {
        let all = Array(0..<MAX_PLAYERS)
        guard isSortedByDollarGame,
              let g = GameManager.shared.currentGame else { return all }
        let active = all.filter { i in
            (g.playerActivated[safe: i] ?? false) &&
            !(g.playerNames[safe: i] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let inactive = all.filter { !active.contains($0) }
        let current = max(0, min(17, g.hole))
        let start   = max(0, min(17, g.startHole ?? current))
        let holes: [Int] = start <= current
            ? Array(start...current)
            : Array(start..<STANDARD_HOLES) + Array(0...current)
        let sorted = active.sorted { a, b in
            let ta = holes.reduce(0.0) { acc, h in acc + (g.playerMoney[safe: a]?[safe: h] ?? 0) }
            let tb = holes.reduce(0.0) { acc, h in acc + (g.playerMoney[safe: b]?[safe: h] ?? 0) }
            return ta < tb
        }
        return sorted + inactive
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        installUmbieHelp()
        
        installLongPressHelp()
        
        // ✅ Ensure we have a game loaded, then normalize (one time)
        if GameManager.shared.currentGame == nil {
            GameManager.shared.startNewGame()
        }
        GameManager.shared.normalizeCurrentIfNeeded()
        
        // Seed any missing scores with pars (only affects nils)
        GameManager.shared.seedScoresWithParsForActivePlayers()
        
        // ✅ Apply mode-based visibility (Wolf vs 6-point)
        applyGameTypeUI()
        
        // --- Keyboard / tap-to-dismiss ---
        scoreFields.forEach {
            $0.keyboardType = .numberPad
            $0.inputAccessoryView = makeDoneToolbar()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // --- Totals labels ---
        totalMoneyLabels = totalMoneyLabels.sorted { $0.tag < $1.tag }
        refreshTotalMoneyLabels()
        
        // --- Toggle button styling (these may be hidden depending on mode) ---
        setupToggleButton(rollPushed,     onColor: .label, offColor: .systemOrange, onTitle: "Roll",    offTitle: "Roll")
        setupToggleButton(rerollPushed,   onColor: .label, offColor: .systemOrange, onTitle: "Re-Roll", offTitle: "Re-Roll")
        setupToggleButton(alonePushed,    onColor: .label, offColor: .systemOrange, onTitle: "Double",   offTitle: "Alone")
        setupToggleButton(pressedPushed2, onColor: .label, offColor: .systemOrange, onTitle: "Press On",   offTitle: "Press")
        
        // --- Score fields ---
        for (i, f) in scoreFields.enumerated() {
            f.tag = i
            f.keyboardType = .numberPad
            f.addTarget(self, action: #selector(scoreEdited(_:)), for: .editingDidEnd)
            f.addTarget(self, action: #selector(scoreChanged(_:)), for: .editingChanged)
        }
        
        // --- Player money fields ---
        for (i, tf) in playerMoneyFields.enumerated() {
            tf.tag = i
            tf.isUserInteractionEnabled = true
            tf.textAlignment = .right
            tf.keyboardType = .decimalPad
            tf.addTarget(self, action: #selector(moneyChanged(_:)), for: .editingChanged)
        }
        
        // --- Button tags + styles ---
        for (i, b) in wolfButtons.enumerated() { b.tag = i }
        for (i, b) in proxButtons.enumerated() { b.tag = i }
        styleWolfButtons()
        
        // --- Initial paint ---
        refreshForCurrentHole()
        paintEverythingForCurrentHole()
        refreshTotalMoneyLabels()
        
       
              
           
        // 👇 Take over back behavior
       
        addHoldRulesToGameModeSegment()
       
         //   let longPress = UILongPressGestureRecognizer(
          //      target: self,
           //     action: #selector(showNassauInfo(_:))
         //   )
         //   longPress.minimumPressDuration = 0.5
         //   nassauButton.addGestureRecognizer(longPress)
        
    
        navigationItem.backButtonTitle = "Players"
        holeStatsSwitch.isOn = !AppSettings.holeStatsPromptMuted
        holeStatsSwitch.addTarget(self, action: #selector(holeStatsSwitchChanged), for: .valueChanged)

        // S column replaced by inline stroke indicators on name labels
        playerStrokesFields.forEach { $0.isHidden = true }

        // Elements moved to Stats/Settings screen
        gameModeSegment.isHidden = true

        NotificationCenter.default.addObserver(self, selector: #selector(handleReloadUI), name: .reloadUI, object: nil)
    }

    @objc private func handleReloadUI() {
        applyGameTypeUI()
        paintEverythingForCurrentHole()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Sync local currentHole from the model every time the screen appears
        // so returning to an active game always shows the correct hole.
        if let g = GameManager.shared.currentGame {
            currentHole = g.hole
        }
        refreshForCurrentHole()
        paintEverythingForCurrentHole()
        refreshTotalMoneyLabels()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showGameOnboardingIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        installSortButtonIfNeeded()
        installHoleInfoHeaderIfNeeded()
    }

    // MARK: - Combined hole/par/HC header

    private var holeInfoHeaderInstalled = false

    private func installHoleInfoHeaderIfNeeded() {
        guard !holeInfoHeaderInstalled else { return }
        holeInfoHeaderInstalled = true

        // Hide the storyboard number labels; the static "Hole" / "Par" text
        // labels are already hidden via storyboard hidden="YES"
        holePlaying.isHidden = true
        parOfHole.isHidden = true

        let infoLabel = UILabel()
        infoLabel.textAlignment = .center
        infoLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        infoLabel.adjustsFontSizeToFitWidth = true
        infoLabel.minimumScaleFactor = 0.6
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        let courseLabel = UILabel()
        courseLabel.textAlignment = .center
        courseLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        courseLabel.textColor = .secondaryLabel
        courseLabel.adjustsFontSizeToFitWidth = true
        courseLabel.minimumScaleFactor = 0.7
        courseLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(infoLabel)
        view.addSubview(courseLabel)

        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: holePlaying.centerYAnchor),
            infoLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 108),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -108),

            courseLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            courseLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 3),
            courseLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 108),
            courseLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -108),
        ])

        holeInfoLabel = infoLabel
        courseHeaderLabel = courseLabel

        refreshHoleInfoHeader()
    }

    private func refreshHoleInfoHeader() {
        guard let g = GameManager.shared.currentGame else { return }
        let h = max(0, min(17, g.hole))
        let par = g.courseParToPass[safe: h] ?? 4
        let rawSI = g.course.holeHandicaps[safe: h] ?? (h + 1)
        let si = max(1, min(STANDARD_HOLES, rawSI == 0 ? (h + 1) : rawSI))

        holeInfoLabel?.text = "Hole \(h + 1)  ·  Par \(par)  ·  HC \(si)"

        let courseName: String
        let currentPars = Array(g.course.pars.prefix(STANDARD_HOLES))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(STANDARD_HOLES))
        if let match = CourseLibrary.shared.courses.first(where: {
            Array($0.pars.prefix(STANDARD_HOLES)) == currentPars &&
            Array($0.hcs.prefix(STANDARD_HOLES)) == currentHCs
        }) {
            courseName = match.name
        } else {
            courseName = "Custom Course"
        }
        courseHeaderLabel?.text = courseName
    }

    private func installSortButtonIfNeeded() {
        guard !sortButtonInstalled,
              let firstLabel = playerNameLabels.sorted(by: { $0.tag < $1.tag }).first,
              let superview = firstLabel.superview else { return }
        sortButtonInstalled = true

        let btn = UIButton(type: .custom)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = UIColor.systemGray6
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemGray3.cgColor
        btn.layer.masksToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        btn.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)
        superview.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.centerYAnchor.constraint(equalTo: firstLabel.topAnchor, constant: -19),
            btn.leadingAnchor.constraint(equalTo: firstLabel.leadingAnchor),
            btn.heightAnchor.constraint(equalToConstant: 28)
        ])

        sortButton = btn
        updateSortButtonTitle()
    }

    @objc private func sortButtonTapped() {
        isSortedByDollarGame.toggle()
        updateSortButtonTitle()
        paintEverythingForCurrentHole()
        refreshTotalMoneyLabels()
    }

    private func updateSortButtonTitle() {
        sortButton?.setTitle(isSortedByDollarGame ? "Sort: $ Game ▲" : "Sort: Order", for: .normal)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .reloadUI, object: nil)
    }
    @objc private func holeStatsSwitchChanged(_ sender: UISwitch) {
        AppSettings.holeStatsPromptMuted = !sender.isOn
    }
    private func addHoldRulesToGameModeSegment() {
        let lp = UILongPressGestureRecognizer(target: self,
                                              action: #selector(gameModeSegmentHeld(_:)))
        lp.minimumPressDuration = 0.5
        lp.cancelsTouchesInView = false   // keeps normal taps working
        gameModeSegment.addGestureRecognizer(lp)
    }
    @objc private func showNassauInfo(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let message = """
  Nassau is a side game that runs in parallel with whatever main game you are playing.

  It tracks separate match-play bets for:
  • Front 9
  • Back 9
  • 18-hole total

  Nassau does not replace Wolf, Skins, Hammer, or other formats. It simply runs automtically, alongside them as an additional side game.

  WolfMore uses a default $1 Nassau bet. Players can apply any multiplier they choose to match their group's usual stakes.

  WolfMore automatically starts a Nassau press bet whenever a side falls 2-down. A press creates an additional parallel bet and does not replace the original Nassau bet.

  Press bets apply separately to the Front 9 and Back 9 matches.
  """

        let alert = UIAlertController(
            title: "How Nassau Works",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Got It", style: .default))
        present(alert, animated: true)
    }
    @objc private func gameModeSegmentHeld(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }

        let ac = UIAlertController(
            title: "Scoring Rules",
            message: allThreeGameRulesText(),
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    private func allThreeGameRulesText() -> String {
        """
        • Teams of two vs two or three
        
        6-Point Scotch 
        • 2 points low ball
        • 2 points low team total
        • 1 point prox
        • 1 point birdie
        • Sweep all 6 points and points double. Umbie button can mute this double. 
        
        2-Point 
        • 1 point team low ball
        • 1 point team low total
        
        1-Point 
        • 1-Point team low ball
        
        """
    }
    private func sixPointRules() -> String {
        """
        • Teams of two vs two or three
        • 2 points low ball
        • 2 points low team total
        • 1 point prox
        • 1 point birdie
        • Sweep all 6 points and points double unless muted by umbie button
        """
    }

    private func twoPointRules() -> String {
        """
        • Teams of two vs two or three
        • 1 point low ball
        • 1 point low team total
        """
    }

    private func onePointRules() -> String {
        """
        • Teams of two vs two or three
        • 1 point low ball
        """
    }

    private func allRules() -> String {
        """
        6-Point Scotch:
        \(sixPointRules())

        2-Point:
        \(twoPointRules())

        1-Point:
        \(onePointRules())
        """
    }

 
    

    private func presentRules(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    @objc private func gameBackTapped() {
        // If Game is inside a navigation controller that was presented modally
        // (your RoundNav), close that whole flow.
        if let nav = navigationController, nav.presentingViewController != nil {
            nav.dismiss(animated: true)
            return
        }

        // If Game itself was presented modally, just dismiss it
        if presentingViewController != nil {
            dismiss(animated: true)
            return
        }

        // Fallback: if it's on a push stack somewhere, just pop
        navigationController?.popViewController(animated: true)
    }

    private func setRejectHammerEnabled(_ on: Bool) {
        rejectHammerButton.isEnabled = on
        rejectHammerButton.alpha = on ? 1.0 : 0.35
    }

    
    @inline(__always)
    private func moneyStringNoMinus(_ x: Double) -> String {
        plainMoneyFmt.string(from: NSNumber(value: abs(x))) ?? String(format: "%.1f", abs(x))
    }

    @inline(__always)
    

    private func refreshTotalMoneyLabels() {
        guard let g = GameManager.shared.currentGame else { return }
     

        let current = max(0, min(17, g.hole))
        // If not set yet, treat current hole as the start (so hole 10 shows only hole 10)
        let start = max(0, min(17, g.startHole ?? current))

        func holesFrom(_ start: Int, to end: Int) -> [Int] {
            return (start <= end) ? Array(start...end)
                                  : Array(start..<STANDARD_HOLES) + Array(0...end)
        }
        let holesToSum = holesFrom(start, to: current)

        // Seat × hole matrix padded to 18
        let money: [[Double]] = g.playerMoney.isEmpty
            ? Array(repeating: Array(repeating: 0.0, count: STANDARD_HOLES), count: MAX_PLAYERS)
            : g.playerMoney.map { row in
                row.count >= STANDARD_HOLES ? Array(row.prefix(STANDARD_HOLES))
                                : row + Array(repeating: 0.0, count: STANDARD_HOLES - row.count)
            }

        let totals: [Double] = money.map { row in
            holesToSum.reduce(0.0) { $0 + row[$1] }
        }
        
        let order = displayOrder
        let seatsToPaint = min(totalMoneyLabels.count, totals.count)
        for i in 0..<seatsToPaint {
            let seat = order[safe: i] ?? i
            setTotalMoneyLabel(totalMoneyLabels[i], seat < totals.count ? totals[seat] : 0)
        }
    }

    private let plainMoneyFmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1   // ← one decimal
        f.maximumFractionDigits = 1   // ← one decimal
        return f
    }()

    // Plain integer formatter (with thousands separators, no decimals)
    private let integer0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        nf.usesGroupingSeparator = true
        return nf
    }()

    private func moneyBgColor(for value: Double) -> UIColor {
        if value > 0 { return UIColor.systemYellow.withAlphaComponent(0.18) }
        if value < 0 { return UIColor.systemRed.withAlphaComponent(0.10) }
        return .clear
    }

    private func setTotalMoneyLabel(_ label: UILabel, _ value: Double) {
        let rounded = value.rounded(.toNearestOrAwayFromZero)
        let isNegative = rounded < 0
        let display = abs(rounded)

        label.text = integer0.string(from: NSNumber(value: display)) ?? String(format: "%.0f", display)
        label.textColor = isNegative ? .systemRed : .label
        label.backgroundColor = moneyBgColor(for: rounded)
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
    }

    @inline(__always)
    private func setMoneyLabel(_ label: UILabel, _ value: Double) {
        label.text = moneyStringNoMinus(value)            // no minus sign
        label.textColor = (value < 0) ? .systemRed : .label
    }

    // Paint all 7 Wolf buttons from the saved model state (multiple Wolves allowed)
    
    // One place to set the ON/OFF look
    private func applyWolfStyle(_ button: UIButton, isOn: Bool) {
        if #available(iOS 15.0, *) {
            var c = button.configuration ?? .filled()
            c.baseForegroundColor = isOn ? .systemBackground : .white
            c.baseBackgroundColor = isOn ? .label : .systemGreen
            c.cornerStyle = .large
            button.configuration = c
        } else {
            button.setTitleColor(isOn ? .systemBackground : .white, for: .normal)
            button.backgroundColor = isOn ? .label : .systemGreen
            button.layer.cornerRadius = 10
            button.layer.masksToBounds = true
        }
        button.accessibilityValue = isOn ? "On" : "Off"
    }

    // Cosmetic only: rounds corners + sets readable default colors
    private func styleWolfButtons() {
        for b in wolfButtons {
            if #available(iOS 15.0, *) {
                var c = b.configuration ?? .filled()
                c.baseForegroundColor = .white       // title color
                c.baseBackgroundColor = .systemGreen // default OFF color
                c.cornerStyle = .large
                b.configuration = c
            } else {
                b.setTitleColor(.white, for: .normal)
                b.backgroundColor = .systemGreen     // default OFF color
                b.layer.cornerRadius = 10
                b.layer.masksToBounds = true
            }
            b.accessibilityTraits.insert(.button)
        }
    }
    @objc private func dismissKeyboard() { view.endEditing(true) }

   
    
    private func makeDoneToolbar() -> UIToolbar {
        let bar = UIToolbar(); bar.sizeToFit()
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        bar.items = [flex, done]
        return bar
    }
    private func stepDollars(by delta: Double) {
        GameManager.shared.update { g in
            // ✅ Always safe / consistent
            g.normalize(holes: STANDARD_HOLES)
            if g.gameHoleDollarsArray.count != STANDARD_HOLES {
                g.gameHoleDollarsArray = Array(repeating: 2.0, count: STANDARD_HOLES)
            }

            // ✅ Use the model hole (0...(STANDARD_HOLES-1))
            let h = max(0, min(17, g.hole))
            self.currentHole = h   // keep your VC’s currentHole in sync (prevents “sometimes”)

            // ✅ Start from current value (fallback to 2.0)
            var amount = g.gameHoleDollarsArray[h]
            if amount <= 0 { amount = 2.0 }

            // ✅ Apply delta, clamp, snap to 0.5
            amount = max(1.0, amount + delta)
            amount = (amount * 2.0).rounded() / 2.0

            g.gameHoleDollarsArray[h] = amount
        }

        // ✅ Repaint everything that shows dollars
        DispatchQueue.main.async {
            self.refreshForCurrentHole()
            self.paintEverythingForCurrentHole()
        }
    }

    private func refreshPlayerNameLabels() {
        guard let g = GameManager.shared.currentGame else { return }
        let order = displayOrder
        let hole  = max(0, min(17, g.hole))

        let rawSI = g.course.holeHandicaps[safe: hole] ?? STANDARD_HOLES
        let si    = max(1, min(STANDARD_HOLES, rawSI == 0 ? STANDARD_HOLES : rawSI))
        let capacity = min(g.playerNames.count, g.hcPlayers.count, g.playerActivated.count)
        let activeSeats = (0..<capacity).filter {
            g.playerActivated[$0] &&
            !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let baseHC = activeSeats.map { g.hcPlayers[$0] }.min() ?? 0

        for (i, label) in playerNameLabels.sorted(by: { $0.tag < $1.tag }).enumerated() {
            let seat = order[safe: i] ?? i
            let name = (seat < g.playerNames.count) ? g.playerNames[seat] : ""

            var displayText = name
            let isActive = activeSeats.isEmpty
                ? !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                : (seat < g.playerActivated.count && g.playerActivated[seat] &&
                   !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            var hasStroke = false
            if isActive {
                let delta = max(0, (seat < g.hcPlayers.count ? g.hcPlayers[seat] : 0) - baseHC)
                let p = pops(for: delta, strokeIndex: si)
                if p > 0 {
                    displayText += " •\(p)"
                    hasStroke = true
                }
            }

            label.text = displayText
            label.lineBreakMode = .byTruncatingMiddle
            label.numberOfLines = 1
            label.font = hasStroke
                ? UIFont.boldSystemFont(ofSize: label.font.pointSize)
                : UIFont.systemFont(ofSize: label.font.pointSize, weight: .regular)
            label.textColor = hasStroke ? .systemGreen : .label
        }
    }

  
    private func syncAloneButtonForHole(_ hole: Int) {
        guard let g = GameManager.shared.currentGame else { return }
        let on = (hole < g.aloneApplied.count) ? g.aloneApplied[hole] : false
        alonePushed.isSelected = on
        alonePushed.backgroundColor = on ? .label : .systemOrange
        alonePushed.setTitleColor(on ? .systemBackground : .white, for: .normal)
        alonePushed.setTitle(on ? "Alone On" : "Alone", for: .normal)
    }
    // Paint all 5 buttons from the saved model (multiple Wolves allowed)
    private func refreshWolfButtons() {
        guard let g = GameManager.shared.currentGame else { return }
        let hole = max(0, min(17, g.hole))
        let order = displayOrder

        for (slot, b) in wolfButtons.enumerated() {
            let seat = order[safe: slot] ?? slot
            b.tag = seat
            guard (0..<MAX_PLAYERS).contains(seat),
                  g.wolfButtonStatus.count == MAX_PLAYERS,
                  g.wolfButtonStatus[seat].count == STANDARD_HOLES else { continue }
            let isOn = g.wolfButtonStatus[seat][hole]
            applyWolfStyleDirect(b, isOn: isOn)
        }
    }

    // Simple, reliable painting
    private func applyWolfStyleDirect(_ button: UIButton, isOn: Bool) {
        button.backgroundColor = isOn ? .label : .systemGreen
        button.setTitleColor(isOn ? .systemBackground : .white, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.setNeedsLayout()
        button.layoutIfNeeded()
    }
   
   
    private func baseStake(for hole: Int, in g: GameData) -> Double {
        let raw = g.gameHoleDollarsArray[safe: hole] ?? 2.0
        return raw == 0 ? 2.0 : raw
    }
    private func installUmbieHelp() {
        addHelp(to: umbrellaButton, title: "Umbie (Sweep)", message: """
    Six-Point only.
    If a team wins all 6 points, the hole automatically doubles.
    Tap Umbie to mute/enable the sweep doubling.
    """)
    }

    private func hammerCount(for hole: Int, in g: GameData) -> Int {
        max(0, g.hammerCountPerHole?[safe: hole] ?? 0)
    }

    private func effectiveStake(for hole: Int, in g: GameData) -> Double {
        let base = baseStake(for: hole, in: g)
        let c = hammerCount(for: hole, in: g)
        let mult = Double(1 << c)              // 1,2,4,8...
        return roundToHalf(base * mult)
    }

    private func paintHammerUIForCurrentHole() {
        guard let g = GameManager.shared.currentGame else { return }
        let h = max(0, min(17, g.hole))

        let count = hammerCount(for: h, in: g)
        updateHammerButton(hammerButton, hammerCount: count)
        setRejectHammerEnabled(count > 0)

        let shown = effectiveStake(for: h, in: g)
        gameDollarsField.text = String(format: "%.2f", shown)
    }
    private func refreshForCurrentHole() {
        applyGameTypeUI()
        guard let g = GameManager.shared.currentGame else { return }
        let h = max(0, min(17, g.hole))

        // Money fields
        let order = displayOrder
        for (slot, tf) in playerMoneyFields.enumerated() {
            let seat = order[safe: slot] ?? slot
            let amt = g.moneyFor(hole: h, player: seat)
            tf.text = amt == 0 ? "" : String(format: "%.2f", amt)
            tf.backgroundColor = amt == 0 ? .clear : moneyBgColor(for: amt)
            let isActive = g.playerActivated[safe: seat] ?? true
            tf.isEnabled = isActive
            tf.alpha = isActive ? 1.0 : 0.4
            tf.tag = seat
        }

        paintReRoll(g, hole: h)
        paintBetButtons(g, hole: h)

        // Header (hidden storyboard labels kept in sync; new combined label updated below)
        holePlaying.text = "\(h + 1)"
        parOfHole.text   = "\(g.courseParToPass[safe: h] ?? 4)"
        refreshHoleInfoHeader()

        // ❌ DO NOT set gameDollarsField from base dollars here

        // Wolf
        let wolfSeat = g.wolfIndexPerHole[safe: h] ?? nil
        for (slot, b) in wolfButtons.enumerated() {
            let seat = order[safe: slot] ?? slot
            b.tag = seat
            let isWolf = (wolfSeat == seat)
            b.isSelected = isWolf
            b.backgroundColor = isWolf ? .label : .systemGreen
            b.setTitleColor(isWolf ? .systemBackground : .white, for: .normal)
        }

        // Prox
        let proxSeat = g.proxWinnerPerHole[safe: h] ?? nil
        for (slot, b) in proxButtons.enumerated() {
            let seat = order[safe: slot] ?? slot
            b.tag = seat
            let on = (proxSeat == seat)
            b.isSelected = on
            b.backgroundColor = on ? .systemGreen : .systemGray
        }

        // Scores
        for (slot, tf) in scoreFields.enumerated() {
            let seat = order[safe: slot] ?? slot
            let v = g.scores[safe: seat]?[safe: h] ?? nil
            tf.text = v.map(String.init) ?? ""
            let isActive = g.playerActivated[safe: seat] ?? true
            tf.isEnabled = isActive
            tf.alpha = isActive ? 1.0 : 0.4
            tf.tag = seat
        }

        paintHolePops(blankZeros: false)

        // ✅ ONE call paints hammer button + reject + dollars label (effective)
        paintHammerUIForCurrentHole()
    }

    private func paintHolePops(blankZeros: Bool = false) {
        refreshPlayerNameLabels()
    }
    // Single source-of-truth pop formula (standard):
    // +floor(S/18) on every hole, plus +1 on SI 1…(S % STANDARD_HOLES).
   
    private func pops(for delta: Int, strokeIndex: Int) -> Int {
        let si = max(1, min(STANDARD_HOLES, strokeIndex == 0 ? STANDARD_HOLES : strokeIndex))  // clamp SI to 1…18; 0 → 18
        let d  = max(0, delta)
        let full = d / STANDARD_HOLES
        let rem  = d % STANDARD_HOLES
        return full + ((rem > 0 && si <= rem) ? 1 : 0)
    }
   
    private func siAt(_ hole: Int, in course: Course) -> Int {
        let raw = course.holeHandicaps.indices.contains(hole) ? course.holeHandicaps[hole] : STANDARD_HOLES
        // clamp 0→18, then into 1…18
        return max(1, min(STANDARD_HOLES, raw == 0 ? STANDARD_HOLES : raw))
    }
    private func parAt(_ hole: Int, in course: Course) -> Int {
        return course.pars.indices.contains(hole) ? course.pars[hole] : 4
    }

    private func makeReadOnly(_ fields: [UITextField]?) {
        fields?.forEach {
            $0.isEnabled = false
            $0.isUserInteractionEnabled = false
            $0.borderStyle = .none
            $0.textColor = .label
            $0.backgroundColor = .clear
        }
    }
    @IBAction func skinsTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = sb.instantiateViewController(withIdentifier: "SkinsViewController") as? SkinsViewController else {
            print("❌ Could not load SkinsViewController")
            return
        }

        vc.gameData = GameManager.shared.currentGame
        navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction private func gameModeChanged(_ sender: UISegmentedControl) {
        let newType: GameType
        switch sender.selectedSegmentIndex {
        case 0: newType = .sixPointScotch
        case 1: newType = .wolf
        default: newType = .wolfLowBall
        }

        GameManager.shared.update { g in
            g.gameType = newType
            g.normalize()
            if newType != .sixPointScotch { g.isUmbrella = false }  // 6-Point only
        }

        applyGameTypeUI()
        paintEverythingForCurrentHole()
    }


    private func applyGameTypeUI() {
        guard let g = GameManager.shared.currentGame else { return }
        let t = g.resolvedGameType

        wolfControlsStack.isHidden   = !t.isWolf
        scotchControlsStack.isHidden = !t.isScotch

        // Umbrella is 6-point only
        if !t.isScotch, g.isUmbrella {
            GameManager.shared.update { $0.isUmbrella = false }
        }

        // keep segment in sync
        switch t {
        case .sixPointScotch: gameModeSegment.selectedSegmentIndex = 0
        case .wolf:           gameModeSegment.selectedSegmentIndex = 1
        case .wolfLowBall:    gameModeSegment.selectedSegmentIndex = 2
        case .hammer:         gameModeSegment.selectedSegmentIndex = 0   // since we treat as scotch
        }
    }
    
    private func roundToHalf(_ x: Double) -> Double {
        (x * 2.0).rounded() / 2.0
    }

    private func baseStakeForHole(_ h: Int, g: GameData) -> Double {
        // IMPORTANT: treat 0 as "unset" -> 2.0 (do NOT clamp 0 to 1 for display)
        let raw = g.gameHoleDollarsArray[safe: h] ?? 2.0
        return (raw == 0) ? 2.0 : raw
    }

    private func hammerCountForHole(_ h: Int, g: GameData) -> Int {
        max(0, g.hammerCountPerHole?[safe: h] ?? 0)
    }

    private func effectiveStakeForHole(_ h: Int, g: GameData) -> Double {
        let base = baseStakeForHole(h, g: g)
        let c = hammerCountForHole(h, g: g)
        let mult = Double(1 << c) // 1,2,4,8...
        return roundToHalf(base * mult)
    }

    private func refreshDollarsLabel() {
        guard let g = GameManager.shared.currentGame else { return }
        let h = max(0, min(17, g.hole))
        let shown = effectiveStakeForHole(h, g: g)
        gameDollarsField.text = String(format: "%.2f", shown)
    }


    @IBAction private func holeStatsTapped(_ sender: UIButton) {
        guard let g = GameManager.shared.currentGame else { return }

        // 1) Make sure we have a home / tracking course set
        guard
            let homeUUID = UUID(uuidString: ProfileStore.homeCourseID),
            let homeCourse = CourseLibrary.shared.get(id: homeUUID)
        else {
            let alert = UIAlertController(
                title: "Non-Tracked Course",
                message: "Hole stats are only tracked for your home course.\nSet a home course in Course Setup first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // 2) Compare current game layout to the home course layout
        let currentPars = Array(g.course.pars.prefix(STANDARD_HOLES))
        let currentHCs  = Array(g.course.holeHandicaps.prefix(STANDARD_HOLES))

        let homePars = Array(homeCourse.pars.prefix(STANDARD_HOLES))
        let homeHCs  = Array(homeCourse.hcs.prefix(STANDARD_HOLES))

        let isHomeCourse = (currentPars == homePars && currentHCs == homeHCs)

        // 3) If NOT the home course → show message instead of stats
        guard isHomeCourse else {
            let alert = UIAlertController(
                title: "Non-Tracked Course",
                message: "Hole stats are only tracked for your home course.\nThis round is on a different layout.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // 4) If we get here, we ARE on the home course → show Hole Stats
        let holeIndex = g.hole

        let sb = storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "HoleStatsVC")
                as? HoleStatsViewController else { return }

        vc.holeIndex = holeIndex
        vc.modalPresentationStyle = (UIDevice.current.userInterfaceIdiom == .pad) ? .fullScreen : .pageSheet
        present(vc, animated: true)

    }


    @IBAction func pressedPush2(_ sender: UIButton) {
        GameManager.shared.update { g in
            // Ensure arrays exist (old save safety)
            if g.pressMask.count != STANDARD_HOLES        { g.pressMask        = Array(repeating: false, count: STANDARD_HOLES) }
            if g.pressBaseDollars.count != STANDARD_HOLES { g.pressBaseDollars = Array(repeating: 0.0,  count: STANDARD_HOLES) }
            if g.gameHoleDollarsArray.count != STANDARD_HOLES { g.gameHoleDollarsArray = Array(repeating: 2.0, count: STANDARD_HOLES) }

            func roundToHalf(_ x: Double) -> Double { (x * 2).rounded() / 2.0 }

            // Restore any currently pressed holes back to their remembered base
            func restorePressedRange() {
                let limit = min(STANDARD_HOLES, g.gameHoleDollarsArray.count)
                for i in 0..<limit where g.pressMask[i] {
                    let base = (g.pressBaseDollars[i] == 0 ? g.gameHoleDollarsArray[i] : g.pressBaseDollars[i])
                    g.gameHoleDollarsArray[i] = roundToHalf(max(1.0, base))
                    g.pressMask[i] = false
                    g.pressBaseDollars[i] = 0
                }
            }

            let count = min(STANDARD_HOLES, g.gameHoleDollarsArray.count)
            let idx   = max(0, min(g.hole, max(0, count - 1)))
            let isPressedHere = (g.pressMask.indices.contains(idx) ? g.pressMask[idx] : false)

            if isPressedHere {
                // Currently ON at this hole -> turn OFF (restore the whole pressed window)
                restorePressedRange()
            } else {
                // Currently OFF -> turn ON from this hole forward, up to 9 holes (no wrap)
                restorePressedRange() // clear any old window first

                let start = idx
                let endExclusive = min(start + 9, count)
                for i in start..<endExclusive {
                    let base = (g.gameHoleDollarsArray[i] == 0 ? 2.0 : g.gameHoleDollarsArray[i])
                    g.pressBaseDollars[i] = base
                    g.pressMask[i] = true
                    g.gameHoleDollarsArray[i] = roundToHalf(max(1.0, base * 2.0))
                }
            }
        }

        // Paint UI from model (brown ON / green OFF)
        refreshForCurrentHole()

        // Optional debug
        if let g = GameManager.shared.currentGame {
            let pretty = g.gameHoleDollarsArray.map { String(format: "%.2f", $0) }.joined(separator: ", ")
            print("Press: hole \(g.hole + 1), dollars = [\(pretty)]")
        }
        
        refreshForCurrentHole()
        paintEverythingForCurrentHole()
    }

    
    @IBAction private func rerollPushedTapped(_ sender: UIButton) {
        GameManager.shared.update { g in
            // (Ideally migrate/sanitize sizes once at load, but keeping your guards)
            if g.rerollApplied.count != STANDARD_HOLES     { g.rerollApplied     = Array(repeating: false, count: STANDARD_HOLES) }
            if g.rerollBaseAmount.count != STANDARD_HOLES  { g.rerollBaseAmount  = Array(repeating: 0.0,  count: STANDARD_HOLES) }
            if g.gameHoleDollarsArray.count != STANDARD_HOLES { g.gameHoleDollarsArray = Array(repeating: 2.0, count: STANDARD_HOLES) }

            let h = max(0, min(g.hole, 17))

            // Re-roll is only valid if Roll is ON
            guard g.rollApplied[h] else {
                // ensure the persisted state is OFF if roll is off
                if g.rerollApplied[h] {
                    // optional: restore dollars back to reroll base if you want strict coupling
                    let base = (g.rerollBaseAmount[h] == 0 ? g.gameHoleDollarsArray[h] : g.rerollBaseAmount[h])
                    g.gameHoleDollarsArray[h] = roundToHalf(max(1.0, base))
                }
                g.rerollApplied[h] = false
                return
            }

            // Compute new state FROM MODEL (not from sender)
            let turningOn = !g.rerollApplied[h]

            if turningOn {
                // TURN ON: remember base, then double once
                let current = (g.gameHoleDollarsArray[h] == 0 ? 2.0 : g.gameHoleDollarsArray[h])
                g.rerollBaseAmount[h] = current
                g.gameHoleDollarsArray[h] = roundToHalf(max(1.0, current * 2.0))
                g.rerollApplied[h] = true
            } else {
                // TURN OFF: restore to saved base
                let base = (g.rerollBaseAmount[h] == 0 ? g.gameHoleDollarsArray[h] : g.rerollBaseAmount[h])
                g.gameHoleDollarsArray[h] = roundToHalf(max(1.0, base))
                g.rerollApplied[h] = false
            }
        }

        // Repaint strictly from persisted model
      
        refreshForCurrentHole()
        paintEverythingForCurrentHole()
    }

    @IBAction private func rollPushedTapped(_ sender: UIButton) {
        sender.isSelected.toggle()

        GameManager.shared.update { g in
            // Safety for old saves
            if g.rollApplied.count != STANDARD_HOLES { g.rollApplied = Array(repeating: false, count: STANDARD_HOLES) }
            if g.rollBaseAmount.count != STANDARD_HOLES { g.rollBaseAmount = Array(repeating: 0.0, count: STANDARD_HOLES) }
            if g.rerollApplied.count != STANDARD_HOLES { g.rerollApplied = Array(repeating: false, count: STANDARD_HOLES) }
            if g.rerollBaseAmount.count != STANDARD_HOLES { g.rerollBaseAmount = Array(repeating: 0.0, count: STANDARD_HOLES) }
            if g.gameHoleDollarsArray.count != STANDARD_HOLES { g.gameHoleDollarsArray = Array(repeating: 2.0, count: STANDARD_HOLES) }

            let hole = max(0, min(g.hole, 17))

            if sender.isSelected {
                if !g.rollApplied[hole] {
                    let current = (g.gameHoleDollarsArray[hole] == 0 ? 2.0 : g.gameHoleDollarsArray[hole])
                    g.rollBaseAmount[hole] = current
                    let doubled = roundToHalf(max(1.0, current * 2.0))
                    g.gameHoleDollarsArray[hole] = doubled
                    g.rollApplied[hole] = true
                }
            } else {
                // Turning Roll OFF: restore to base and also clear Re-Roll
                if g.rollApplied[hole] {
                    let base = (g.rollBaseAmount[hole] == 0 ? g.gameHoleDollarsArray[hole] : g.rollBaseAmount[hole])
                    g.gameHoleDollarsArray[hole] = roundToHalf(max(1.0, base))
                    g.rollApplied[hole] = false

                    // Clear Re-Roll if it was on
                    if g.rerollApplied[hole] {
                        g.rerollApplied[hole] = false
                        g.rerollBaseAmount[hole] = 0.0
                    }
                }
            }
        }
        // Button look
        if sender.isSelected {
            sender.backgroundColor = .label
            sender.setTitleColor(.systemBackground, for: .normal)
            sender.setTitle("Roll On", for: .normal)
        } else {
            sender.backgroundColor = .systemOrange
            sender.setTitleColor(.white, for: .normal)
            sender.setTitle("Roll", for: .normal)
        }

        refreshForCurrentHole()
        paintEverythingForCurrentHole()
    }
    // MARK: - Persist-as-you-type
    @objc private func scoreEdited(_ tf: UITextField) {
        guard let g = GameManager.shared.currentGame else { return }
        let hole = g.hole
        let seat = tf.tag
        let val  = Int(tf.text ?? "")  // Int? (nil if blank)

        GameManager.shared.update { m in
            if m.scores.count != MAX_PLAYERS || m.scores.first?.count != STANDARD_HOLES {
                m.scores = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
            }
            if (0..<MAX_PLAYERS).contains(seat), (0..<STANDARD_HOLES).contains(hole) {
                m.scores[seat][hole] = val
            }
        }
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        //    self?.maybePromptForHoleStats()
       // }
    }
    // MARK: - Quick Help (Long-press)

    private struct HelpItem {
        let title: String
        let message: String
    }

    private func installLongPressHelp() {
        // Hammer / Reject
        addHelp(to: hammerButton, title: "Hammer", message: """
    Doubles the current hole stake each tap (1× → 2× → 4× → 8×…).
    Applies only to this hole.
    Use Reject to undo the most recent hammer.
    Money updates when you press Update Scores.
    """)

        addHelp(to: rejectHammerButton, title: "Reject Hammer", message: """
    Undo the most recent Hammer tap for this hole.
    (Stake drops one step: 8× → 4× → 2× → 1×.)
    """)

        // Roll / Re-Roll / Press / Alone
        addHelp(to: rollPushed, title: "Roll", message: """
    Doubles the hole stake for this hole.
    Often used when teams want to raise the action on a single hole.
    """)

        addHelp(to: rerollPushed, title: "Re-Roll", message: """
    Doubles the stake again on this hole.
    Only available if Roll is already ON.
    """)

        addHelp(to: pressedPushed2, title: "Press", message: """
    Persistent double.
    Starts at the current hole and stays ON for up to 9 holes.
    Press affects stake going forward until the pressed window ends or is turned off.
    """)

        addHelp(to: alonePushed, title: "Alone (Lone Wolf)", message: """
    Player goes solo (no partner).
    Doubles the stake for this hole.
    Only tap if you want Lone Wolf wager to double. Otherwise. Alone calculation will be the same but without the double.
    Note: Alone Team Total calculation uses a ghost partner score: (player score + bogey) ÷ 2.
    """)

        // Umbie (if you have an umbrella button outlet, attach help there too)
        // If your Umbie button is called something else, just wire it below.
    }
    private func addHelp(to view: UIView?, title: String, message: String) {
        guard let view else { return }
        view.isUserInteractionEnabled = true

        // Store text on the view itself (simple and reliable)
        view.accessibilityLabel = title
        view.accessibilityValue = message

        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleHelpLongPress(_:)))
        lp.minimumPressDuration = 0.45
        view.addGestureRecognizer(lp)
    }

    @objc private func handleHelpLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began, let source = gr.view else { return }

        let title = source.accessibilityLabel ?? "Help"
        let message = source.accessibilityValue ?? ""

        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Got it", style: .cancel))

        // iPad anchor safety
        if let pop = ac.popoverPresentationController {
            pop.sourceView = source
            pop.sourceRect = source.bounds
        }

        present(ac, animated: true)
    }

    private func effectiveHCs(_ hc: [Int], activeSeats: [Int]) -> [Int] {
        guard !activeSeats.isEmpty else { return hc }
        let maxActive = activeSeats.map { hc[$0] }.max() ?? 0
        var out = hc
        for (i, _) in hc.enumerated() where !activeSeats.contains(i) {
            out[i] = maxActive      // push inactives up so they can’t be the low man
        }
        return out
    }
    private func recalcMoneyForCurrentHole() {
        guard let g = GameManager.shared.currentGame else { return }
        let hole = g.hole

        // 👇 GLOBAL — not per-hole
        let muted = g.isUmbrella

        var payouts = GameManager.shared.computeHolePayout(
            hole: hole,
            umbePressed: muted
        )

        // ✅ HAMMER overlay (doubles the RESULT for this hole)
        



        GameManager.shared.update { g in
            if g.playerMoney.count < MAX_PLAYERS {
                g.playerMoney = Array(repeating: Array(repeating: 0.0, count: STANDARD_HOLES), count: MAX_PLAYERS)
            }
            for s in 0..<payouts.count {
                if g.playerMoney[s].count < STANDARD_HOLES {
                    g.playerMoney[s] = Array(repeating: 0.0, count: STANDARD_HOLES)
                }
                g.playerMoney[s][hole] = payouts[s]
            }
        }

        refreshMoneyFieldsForCurrentHole()
    }
    private var hasSavedThisOpen = false

    private func debugStrokes(_ tag: String) {
        guard let g = GameManager.shared.currentGame else { return }
        print("🧮[\(tag)] names:", g.playerNames)
        print("🧮[\(tag)] actives:", g.playerActivated)
        print("🧮[\(tag)] HCs:", g.hcPlayers)
    }

    private func refreshScoreFieldsForCurrentHole() {
        guard let g = GameManager.shared.currentGame else { return }
        let h = g.hole
        let order = displayOrder
        let slots = min(scoreFields.count, MAX_PLAYERS)
        for s in 0..<slots {
            let seat = order[safe: s] ?? s
            let v = (seat < g.scores.count && h < g.scores[seat].count) ? g.scores[seat][h] : nil
            scoreFields[s].text = v.map(String.init) ?? ""
            scoreFields[s].tag = seat
        }
    }

       
    @IBAction private func updateDollarsTapped(_ sender: UIButton) {
        // quick flash
        let oldColor = sender.backgroundColor
        sender.backgroundColor = .systemGray
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            sender.backgroundColor = oldColor ?? .systemGreen
        }
        
        // copy current hole's amount to ALL holes
        GameManager.shared.update { g in
            let hole = max(0, min(g.hole, g.gameHoleDollarsArray.count - 1))
            var amount = g.gameHoleDollarsArray[hole]
            if amount == 0 { amount = 2.0 }             // default if somehow unset
            amount = max(1.0, amount)                   // minimum 1.0
            amount = (amount * 2.0).rounded() / 2.0     // snap to 0.50
            g.gameHoleDollarsArray = Array(repeating: amount, count: STANDARD_HOLES)
        }
        
        // repaint label
        refreshForCurrentHole()

        // debug print of the full dollars array
        if let arr = GameManager.shared.currentGame?.gameHoleDollarsArray {
            let pretty = arr.map { String(format: "%.2f", $0) }.joined(separator: ", ")
            print("Dollars per hole: [\(pretty)]")
        } else {
            print("Dollars per hole: (no current game)")
        }
    }
    
    @IBAction private func umbrellaTapped(_ sender: UIButton) {
        // ✅ block in Wolf
        guard GameManager.shared.currentGame?.resolvedGameType == .sixPointScotch else { return }

        GameManager.shared.update { $0.isUmbrella.toggle() }

        // repaint everything that might overwrite styles…
        paintEverythingForCurrentHole()

        // ✅ …then force Umbie UI LAST so it wins
        refreshUmbrellaButtonUI(sender)
    }


    
    @IBAction func previousHoleTapped(_ sender: UIButton) {
        currentHole = (currentHole - 1 + STANDARD_HOLES) % STANDARD_HOLES
        GameManager.shared.update { $0.hole = currentHole }
        refreshForCurrentHole()
        paintEverythingForCurrentHole()
        refreshWolfButtons()
      
        refreshTotalMoneyLabels()
        hasPromptedForThisHole = false
        
    }
    
    @IBAction func nextHoleTapped(_ sender: UIButton) {
        currentHole = (currentHole + 1) % STANDARD_HOLES
        GameManager.shared.update { $0.hole = currentHole }   // ← sync to model
        refreshForCurrentHole()
        
        refreshWolfButtons()
        paintEverythingForCurrentHole()
        refreshTotalMoneyLabels()
        hasPromptedForThisHole = false
        
    }

    // Put near the top of GameViewController
    private let currencyFmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        // f.maximumFractionDigits = 0  // optional
        return f
    }()

    private func moneyString(_ x: Double) -> String {
        currencyFmt.string(from: NSNumber(value: abs(x))) ?? String(format: "$%.2f", abs(x))
    }
   
    private func refreshUmbrellaButtonUI(_ button: UIButton) {
        guard let g = GameManager.shared.currentGame else { return }
        let muted = g.isUmbrella   // true = OFF (muted)

        let title = muted ? "Umbrella: OFF" : "Umbrella: ON"
        let bg    = muted ? UIColor.systemBrown : UIColor.systemOrange

        if #available(iOS 15.0, *) {
            var cfg = button.configuration ?? UIButton.Configuration.filled()
            cfg.title = title
            cfg.baseBackgroundColor = bg

            cfg.baseForegroundColor = .label

            // ✅ slightly smaller font
            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold) // tweak
                outgoing.foregroundColor = UIColor.label
                return outgoing
            }

            button.configuration = cfg

            // extra safety for state changes
            button.setTitleColor(.label, for: .normal)
            button.setTitleColor(.label, for: .highlighted)
            button.setTitleColor(.label, for: .selected)
            button.setTitleColor(.label, for: .disabled)
        } else {
            button.setTitle(title, for: .normal)
            button.backgroundColor = bg
            button.setTitleColor(.label, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            button.alpha = 1.0
        }
    }



    private func refreshHeaderForCurrentHole() {
        DispatchQueue.main.async {
            guard let game = GameManager.shared.currentGame else { return }
            // Use the model's hole, not self.currentHole, so returning to an
            // active game always shows the correct hole immediately.
            let h = max(0, min(17, game.hole))
            let holeNo = h + 1

            let par = game.course.pars.indices.contains(h) ? game.course.pars[h] : 4

            self.holePlaying.text = "\(holeNo)"
            self.parOfHole.text   = "\(par)"
            self.refreshHoleInfoHeader()
        }
    }
 
    @IBAction func alonePushedTapped(_ sender: UIButton) {
        sender.isSelected.toggle()

        GameManager.shared.update { g in
            // Ensure arrays are correct length (handles old saves)
            if g.aloneApplied.count != STANDARD_HOLES     { g.aloneApplied     = Array(repeating: false, count: STANDARD_HOLES) }
            if g.aloneBaseAmount.count != STANDARD_HOLES  { g.aloneBaseAmount  = Array(repeating: 0.0,  count: STANDARD_HOLES) }
            if g.gameHoleDollarsArray.count != STANDARD_HOLES { g.gameHoleDollarsArray = Array(repeating: 2.0, count: STANDARD_HOLES) }

            let hole = max(0, min(g.hole, 17))

            if sender.isSelected {
                // TURN ON: double once (no stacking). Remember base so OFF can restore.
                if !g.aloneApplied[hole] {
                    let base = (g.gameHoleDollarsArray[hole] == 0 ? 2.0 : g.gameHoleDollarsArray[hole])
                    g.aloneBaseAmount[hole] = base
                    let doubled = roundToHalf(max(1.0, base * 2.0))
                    g.gameHoleDollarsArray[hole] = doubled
                    g.aloneApplied[hole] = true
                }
            } else {
                // TURN OFF: restore to base (no double)
                if g.aloneApplied[hole] {
                    let base = (g.aloneBaseAmount[hole] == 0 ? g.gameHoleDollarsArray[hole] : g.aloneBaseAmount[hole])
                    g.gameHoleDollarsArray[hole] = roundToHalf(max(1.0, base))
                    g.aloneApplied[hole] = false
                }
            }
        }

        // Button visuals: orange (off) ↔︎ label (on)
        if sender.isSelected {
            sender.backgroundColor = .label
            sender.setTitleColor(.systemBackground, for: .normal)
            sender.setTitle("Alone On", for: .normal)
        } else {
            sender.backgroundColor = .systemOrange
            sender.setTitleColor(.white, for: .normal)
            sender.setTitle("Alone", for: .normal)
        }

        refreshForCurrentHole()

        // (Optional) quick debug
        if let g = GameManager.shared.currentGame {
            let h = max(0, min(g.hole, 17))
            print(String(format: "Alone toggle → Hole %d dollars: %.2f", h + 1, g.gameHoleDollarsArray[h]))
        }
        
        refreshForCurrentHole()
        paintEverythingForCurrentHole()
    }
    @IBAction private func plusPointDollarsTapped(_ sender: UIButton) {
        stepDollars(by: 0.5)
    }

    @IBAction private func minusPointDollarsTapped(_ sender: UIButton) {
        stepDollars(by: -0.5)
    }
    // Call this when a score field edits
    
    @IBAction private func wolfButtonTapped(_ sender: UIButton) {
        let player = sender.tag
        guard (0..<MAX_PLAYERS).contains(player) else { return }

        GameManager.shared.update { g in
            let hole = max(0, min(17, g.hole))
            if g.wolfButtonStatus.count != MAX_PLAYERS || g.wolfButtonStatus.first?.count != STANDARD_HOLES {
                g.wolfButtonStatus = Array(repeating: Array(repeating: false, count: STANDARD_HOLES), count: MAX_PLAYERS)
            }
            g.wolfButtonStatus[player][hole].toggle()
        }

        // ← This ensures both (or all) Wolves paint black
        refreshWolfButtons()

        #if DEBUG
        if let g = GameManager.shared.currentGame {
            let h = max(0, min(17, g.hole))
            print("🐺 Hole \(h+1) wolves:", g.wolfButtonStatus.map { $0[h] })
        }
        #endif
    }
    // Currency with NO cents
    private let currency0: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 0
        nf.roundingMode = .halfUp
        return nf
    }()

    private func setScore(_ strokes: Int?, playerIndex: Int, holeIndex: Int) {
        GameManager.shared.update { g in
            guard playerIndex < g.playerNames.count,   // ✅ not g.players
                  holeIndex < g.courseParToPass.count else { return }  // ✅ not g.course.pars
            g.scores[playerIndex][holeIndex] = strokes
        }
    }


    // Exclusive prox winner per hole
    @IBAction private func proxButtonTapped(_ sender: UIButton) {
        guard let g = GameManager.shared.currentGame else { return }
        guard g.resolvedGameType == .sixPointScotch else { return } // ✅ block in Wolf

        let player = sender.tag
        guard (0..<MAX_PLAYERS).contains(player) else { return }

        GameManager.shared.update { g in
            if g.proxWinnerPerHole.count != STANDARD_HOLES { g.proxWinnerPerHole = Array(repeating: nil, count: STANDARD_HOLES) }
            let hole = max(0, min(17, g.hole))
            g.proxWinnerPerHole[hole] = (g.proxWinnerPerHole[hole] == player) ? nil : player
        }

        refreshProxButtons()
    }

    private struct HammerStyle {
        let color: UIColor
        let title: String
    }

    private func hammerMultiplier(for count: Int) -> Int {
        // doubles each hammer: 0→1x, 1→2x, 2→4x, 3→8x...
        return 1 << max(0, count)
    }

    private func hammerStyle(for count: Int) -> HammerStyle {
        // tweak colors/titles however you want
        switch count {
        case 0:  return .init(color: .systemGray5, title: "HAMMER (1x)")
        case 1:  return .init(color: .systemYellow, title: "HAMMER (2x)")
        case 2:  return .init(color: .systemOrange, title: "HAMMER (4x)")
        case 3:  return .init(color: .systemRed, title: "HAMMER (8x)")
        case 4:  return .init(color: .systemPurple, title: "HAMMER (16x)")
        default: return .init(color: .systemGray, title: "HAMMER (\(hammerMultiplier(for: count))x)")
        }
    }
    
    private func updateHammerButton(_ button: UIButton, hammerCount: Int) {
        let style = hammerStyle(for: hammerCount)

        if #available(iOS 15.0, *) {
            var cfg = button.configuration ?? UIButton.Configuration.filled()

            cfg.title = style.title
            cfg.baseBackgroundColor = style.color

            cfg.baseForegroundColor = .label

            // ✅ Slightly smaller font
            cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold) // tweak 12–14
                outgoing.foregroundColor = UIColor.label
                return outgoing
            }

            button.configuration = cfg

            // Extra safety for highlighted/selected states
            button.setTitleColor(.label, for: .normal)
            button.setTitleColor(.label, for: .highlighted)
            button.setTitleColor(.label, for: .selected)
            button.setTitleColor(.label, for: .disabled)
        } else {
            button.backgroundColor = style.color
            button.setTitle(style.title, for: .normal)
            button.setTitleColor(.label, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
        }
    }

    @IBAction func sendRemoteInviteTapped(_ sender: UIButton) {
        guard let g = GameManager.shared.currentGame else { return }
        guard let myIndex = myPlayerIndex(in: g) else { return }

        let round = SharedRoundBuilder.make(from: g, playerIndex: myIndex)

        guard let encoded = RemoteRoundCodec.encode(round) else {
            showRemoteImportError(message: "Could not create remote invite.")
            return
        }

        print("📤 SENDING round.playerName =", round.playerName)
        print("📤 SENDING encoded =")
        print(encoded)

        let messageBody = """
        WolfMore Remote Nassau Invite

        Player: \(round.playerName)
        Course: \(round.courseName)

        Paste this code into WolfMore:
        \(encoded)
        """

        if MFMessageComposeViewController.canSendText() {
            let composer = MFMessageComposeViewController()
            composer.messageComposeDelegate = self
            composer.body = messageBody
            present(composer, animated: true)
        } else {
            UIPasteboard.general.string = encoded

            let ac = UIAlertController(
                title: "Messages Unavailable",
                message: "This device cannot send texts. The invite code was copied to the clipboard instead.",
                preferredStyle: .alert
            )
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    private var onMessageComposeDismissed: (() -> Void)?

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        let failed = result == .failed
        controller.dismiss(animated: true) { [weak self] in
            if failed { self?.showRemoteImportError(message: "Message failed to send.") }
            self?.onMessageComposeDismissed?()
            self?.onMessageComposeDismissed = nil
        }
    }

    private func sendAcceptanceAndOpen(_ match: RemoteMatch, mode: RemoteCompareMode) {
        let body = buildAcceptanceMessage(match: match, mode: mode)
        if MFMessageComposeViewController.canSendText() {
            onMessageComposeDismissed = { [weak self] in
                self?.openRemoteMatch(match, mode: mode)
            }
            let composer = MFMessageComposeViewController()
            composer.messageComposeDelegate = self
            composer.body = body
            present(composer, animated: true)
        } else {
            openRemoteMatch(match, mode: mode)
        }
    }

    private func buildAcceptanceMessage(match: RemoteMatch, mode: RemoteCompareMode) -> String {
        let modeLabel: String
        switch mode {
        case .holeByHole:    modeLabel = "Hole by Hole"
        case .frontBackByHC: modeLabel = "Front/Back 9 by HC"
        case .all18ByHC:     modeLabel = "18 Holes by HC"
        }
        let opponentCourse = match.opponentRound?.courseName ?? "their course"
        return """
        WolfMore Remote Nassau — Challenge Accepted!
        \(match.myRound.playerName) @ \(match.myRound.courseName)
        vs \(match.opponentName) @ \(opponentCourse)
        Mode: \(modeLabel)
        Stake: $\(match.stakePerBet) per bet
        Game on!
        """
    }
    @IBAction func startRemoteNassauTapped(_ sender: UIButton) {
        guard let g = GameManager.shared.currentGame else { return }

        guard let myIndex = myPlayerIndex(in: g) else {
            print("❌ Could not find local player")
            return
        }

        let myRound = SharedRoundBuilder.make(from: g, playerIndex: myIndex)

        promptForRemoteStake { [weak self] stake in
            guard let self else { return }

            self.promptForRemoteRound { [weak self] opponentRound in
                guard let self else { return }

                if self.isSamePlayer(myRound.playerName, opponentRound.playerName) {
                    self.showRemoteImportError(
                        message: "You pasted your own remote round code. Paste your opponent’s code instead."
                    )
                    return
                }

                let savedMatch = RemoteMatch(
                    myRound: myRound,
                    opponentName: opponentRound.playerName,
                    stakePerBet: stake,
                    inviteCode: nil,
                    isAccepted: true,
                    opponentRound: opponentRound
                )

                RemoteMatchStore.shared.add(savedMatch)
                print("💾 Saved Remote Match vs \(opponentRound.playerName)")

                let ac = UIAlertController(title: "Compare Mode", message: nil, preferredStyle: .actionSheet)

                ac.addAction(UIAlertAction(title: "Hole by Hole", style: .default) { [weak self] _ in
                    self?.sendAcceptanceAndOpen(savedMatch, mode: .holeByHole)
                })

                ac.addAction(UIAlertAction(title: "Front / Back 9 by HC", style: .default) { [weak self] _ in
                    self?.sendAcceptanceAndOpen(savedMatch, mode: .frontBackByHC)
                })

                ac.addAction(UIAlertAction(title: "18 Holes by HC", style: .default) { [weak self] _ in
                    self?.sendAcceptanceAndOpen(savedMatch, mode: .all18ByHC)
                })

                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

                self.present(ac, animated: true)
            }
        }
    }
    private func openRemoteMatch(_ match: RemoteMatch, mode: RemoteCompareMode) {
        guard let opponentRound = match.opponentRound,
              let result = match.result else {
            showRemoteImportError(message: "Could not calculate Remote Nassau result.")
            return
        }

        let vc = RemoteNassauViewController()
        vc.myRound = match.myRound
        vc.opponentRound = opponentRound
        vc.result = result
        vc.compareMode = mode

        navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func remoteNassauTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Remote Nassau", message: nil, preferredStyle: .actionSheet)

        ac.addAction(UIAlertAction(title: "Send Invite", style: .default) { [weak self] _ in
            self?.sendRemoteInviteTapped(UIButton())
        })

        ac.addAction(UIAlertAction(title: "Import Invite", style: .default) { [weak self] _ in
            self?.startRemoteNassauTapped(UIButton())
        })

        ac.addAction(UIAlertAction(title: "View Matches", style: .default) { [weak self] _ in
            let vc = RemoteMatchesViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        })

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(ac, animated: true)
    }
    
    private func isSamePlayer(_ a: String, _ b: String) -> Bool {
          a.trimmingCharacters(in: .whitespacesAndNewlines)
              .localizedCaseInsensitiveCompare(
                  b.trimmingCharacters(in: .whitespacesAndNewlines)
              ) == .orderedSame
      }
    private func promptForRemoteStake(completion: @escaping (Int) -> Void) {
        let ac = UIAlertController(
            title: "Nassau Stake",
            message: "Enter the stake per bet (Front / Back / Overall)",
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            tf.placeholder = "10"
            tf.text = "10"
            tf.keyboardType = .numberPad
        }

        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        ac.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            let rawText = ac.textFields?.first?.text ?? "10"
            let stake = Int(rawText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 10
            completion(max(1, stake))
        })

        present(ac, animated: true)
    }
    private func myPlayerIndex(in g: GameData) -> Int? {
        let myName = (ProfileStore.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !myName.isEmpty else { return nil }

        return g.playerNames.firstIndex {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(myName) == .orderedSame
        }
    }
    private func nassauText(for value: Int) -> String {
        if value > 0 { return "\(value) up" }
        if value < 0 { return "\(-value) down" }
        return "All square"
    }
    // MARK: - Remote Nassau Import

    private func promptForRemoteRound(completion: @escaping (SharedRound) -> Void) {
        let vc = ImportRemoteRoundViewController()
        vc.modalPresentationStyle = .formSheet

        vc.onImport = { [weak self, weak vc] rawText in
            guard let self else { return }

            let cleaned = rawText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")

            let code: String
            if let range = cleaned.range(of: "WOLFMORE_REMOTE_NASSAU:") {
                code = String(cleaned[range.lowerBound...])
            } else {
                code = cleaned
            }

            print("📥 Raw typed text:")
            print(rawText)

            print("📥 Cleaned typed text:")
            print(cleaned)

            print("📥 Extracted code:")
            print(code)

            guard !code.isEmpty else {
                vc?.dismiss(animated: true) {
                    self.showRemoteImportError(message: "Paste a shared round code first.")
                }
                return
            }

            //
            // 🔥 SIMPLE TEST MODE (ADD THIS BLOCK)
            //
            if code.contains("-") {
                let parts = code.split(separator: "-")
                
                if parts.count == 2 {
                    let name = String(parts[0])
                    let scoreString = String(parts[1])
                    
                    let scores = scoreString.compactMap { Int(String($0)) }
                    
                    if scores.count == STANDARD_HOLES {
                        let round = SharedRound(
                            playerName: name,
                            courseName: "WolfMore",
                            pars: Array(repeating: 4, count: STANDARD_HOLES),
                            hcs: Array(1...STANDARD_HOLES),
                            scores: scores,
                            fairways: Array(repeating: nil, count: STANDARD_HOLES),
                            girs: Array(repeating: nil, count: STANDARD_HOLES),
                            putts: Array(repeating: nil, count: STANDARD_HOLES),
                            courseHandicap: 0
                        )

                        print("✅ SIMPLE IMPORT =", round.playerName)

                        vc?.dismiss(animated: true) {
                            completion(round)
                        }
                        return
                    }
                }
            }
            //
            // 🔥 END SIMPLE MODE
            //

            guard let round = RemoteRoundCodec.decode(code) else {
                vc?.dismiss(animated: true) {
                    self.showRemoteImportError(message: "That shared round code could not be read.")
                }
                return
            }

            vc?.dismiss(animated: true) {
                completion(round)
            }
        }

        present(vc, animated: true)
    }
    private func showRemoteImportError(message: String = "That shared round code could not be read.") {
        let ac = UIAlertController(
            title: "Import Failed",
            message: message,
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    private func importRemoteRoundFromClipboardOrPrompt(completion: @escaping (SharedRound) -> Void) {
        if let clipboard = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !clipboard.isEmpty {

            let cleaned = clipboard
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")

            let code: String
            if let range = cleaned.range(of: "WOLFMORE_REMOTE_NASSAU:") {
                code = String(cleaned[range.lowerBound...])
            } else {
                code = cleaned
            }

            print("📋 Clipboard text:")
            print(cleaned)

            if let round = RemoteRoundCodec.decode(code) {
                print("✅ Imported from clipboard =", round.playerName)
                completion(round)
                return
            }
        }

        promptForRemoteRound(completion: completion)
    }
    
    @IBAction func remoteMatchesTapped(_ sender: UIButton) {
        let vc = RemoteMatchesViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func updateScorePushed(_ sender: UIButton) {
        sender.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            sender.isEnabled = true
        }

        GameManager.shared.update { g in
            if g.startHole == nil {
                g.startHole = g.hole
            }
        }

        // 0) get current game / hole
        guard let snap = GameManager.shared.currentGame else { return }
        let hole = snap.hole
        guard (0..<STANDARD_HOLES).contains(hole) else { return }

        // ✅ use global flag (true = mute double everywhere)
        let umbrellaMuted = (snap.resolvedGameType == .sixPointScotch) ? snap.isUmbrella : false

        // keep your press logic
        let pressOnThisHole = (hole < snap.pressedPushedToggleArray.count)
            ? snap.pressedPushedToggleArray[hole]
            : false

        // 1) save scores from UI + mark hole committed
        GameManager.shared.update { g in
            if g.scores.count != MAX_PLAYERS || g.scores.contains(where: { $0.count != STANDARD_HOLES }) {
                g.scores = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
            }

            if g.holeCommitted.count != STANDARD_HOLES {
                g.holeCommitted = Array(repeating: false, count: STANDARD_HOLES)
            }

            let slots = min(MAX_PLAYERS, scoreFields.count)
            for s in 0..<slots {
                let seat = scoreFields[s].tag
                guard (0..<MAX_PLAYERS).contains(seat) else { continue }
                g.scores[seat][hole] = Int(scoreFields[s].text ?? "")
            }

            g.holeCommitted[hole] = true
        }

        // ✅ SAVE LAST ROUND after hole 18 score is actually stored
        if hole == 17 {
            GameManager.shared.saveCurrentRoundAsLastRound()
            print("✅ Last round saved at end of hole 18")
        }

        // 2) recalculate Nassau immediately
        GameManager.shared.update { g in
            if var ns = g.nassauState {
                NassauEngine.recalculate(state: &ns, gameData: g)
                g.nassauState = ns
            }
        }

        // 3) press carry-forward
        if pressOnThisHole {
            GameManager.shared.update { g in
                guard hole < g.gameHoleDollarsArray.count,
                      hole < g.pressedPushedToggleArray.count else { return }

                let end = (hole < 9) ? 9 : STANDARD_HOLES
                let base = g.gameHoleDollarsArray[hole]

                for idx in hole..<min(end, g.gameHoleDollarsArray.count) {
                    if idx < g.pressedPushedToggleArray.count {
                        g.pressedPushedToggleArray[idx] = true
                    }
                    g.gameHoleDollarsArray[idx] = base
                }
            }
        }

        // 4) compute payouts using GLOBAL umbrella
        let payouts = GameManager.shared.computeHolePayout(
            hole: hole,
            umbePressed: umbrellaMuted
        )

        // 5) save payouts
        GameManager.shared.update { g in
            if g.playerMoney.count != MAX_PLAYERS || g.playerMoney.contains(where: { $0.count != STANDARD_HOLES }) {
                g.playerMoney = Array(repeating: Array(repeating: 0, count: STANDARD_HOLES), count: MAX_PLAYERS)
            }

            let seats = min(MAX_PLAYERS, playerMoneyFields.count, g.playerMoney.count, payouts.count)
            for s in 0..<seats {
                g.playerMoney[s][hole] = payouts[s]
            }
        }

        // 6) paint
        let seatsToPaint = min(MAX_PLAYERS, playerMoneyFields.count, payouts.count)
        for s in 0..<seatsToPaint {
            setMoneyField(playerMoneyFields[s], to: payouts[s])
        }

        paintEverythingForCurrentHole()
        refreshTotalMoneyLabels()

        // 7) debug
        if let g = GameManager.shared.currentGame {
            let seats = min(MAX_PLAYERS, g.scores.count, g.playerNames.count)

            let scorePart = (0..<seats).map { s -> String in
                let name = g.playerNames[s].isEmpty ? "P\(s + 1)" : g.playerNames[s]
                let sc = g.scores[s][hole].map(String.init) ?? "-"
                return "\(name):\(sc)"
            }.joined(separator: "  ")

            let payoutPart = payouts.prefix(seats)
                .map { String(format: "%+.1f", Double($0)) }
                .joined(separator: "  ")

            print("H\(hole + 1)  umbMuted=\(umbrellaMuted)  \(scorePart)  |  $ \(payoutPart)")
            print("Hole \(hole + 1) Stats:")
            print("FW:", g.fairwayHit.map { $0[hole] })
            print("GIR:", g.girHit.map { $0[hole] })
            print("PUTTS:", g.puttsPerHole.map { $0[hole] })
        }

        paintEverythingForCurrentHole()
        refreshTotalMoneyLabels()
        refreshHoleValueLabel()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            guard let game = GameManager.shared.currentGame else { return }
            guard !game.holeStatsPromptMuted else { return }

            self.presentStatsPrompt()
        }
    }
 
    private func presentStatsPrompt() {
        guard !(GameManager.shared.currentGame?.holeStatsPromptMuted ?? false) else { return }
        let ac = UIAlertController(
            title: "Add Hole Stats?",
            message: "Track Fairway, GIR, and Putts for this hole.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Add Stats", style: .default) { [weak self] _ in
            self?.openHoleStatsEntry()
        })

        ac.addAction(UIAlertAction(title: "Skip", style: .cancel))

        ac.addAction(UIAlertAction(title: "Don't Ask Again", style: .destructive) { _ in
            GameManager.shared.currentGame?.holeStatsPromptMuted = true
            GameManager.shared.saveCurrent()
        })

        present(ac, animated: true)
    }
    
    private func openHoleStatsEntry() {
        guard let game = GameManager.shared.currentGame else { return }

        let hole = max(0, min(17, game.hole))

        let myName = (ProfileStore.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let seats = 0..<min(game.playerNames.count, game.playerActivated.count)

        guard let playerIndex = seats.first(where: { i in
            game.playerActivated[i] &&
            game.playerNames[i]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(myName) == .orderedSame
        }) else {
            print("❌ Hole stats: could not match ProfileStore.name to active player")
            print("ProfileStore.name =", myName)
            print("Players =", game.playerNames)
            return
        }

        let vc = HoleStatsEntryViewController()
        vc.modalPresentationStyle = .overFullScreen

        vc.hasExistingStats =
            game.fairwayHit[safe: playerIndex]?[safe: hole] != nil ||
            game.girHit[safe: playerIndex]?[safe: hole] != nil ||
            game.puttsPerHole[safe: playerIndex]?[safe: hole] != nil ||
            game.scores[safe: playerIndex]?[safe: hole] != nil

        vc.existingFairway = game.fairwayHit[safe: playerIndex]?[safe: hole] ?? nil
        vc.existingGIR = game.girHit[safe: playerIndex]?[safe: hole] ?? nil
        vc.existingPutts = game.puttsPerHole[safe: playerIndex]?[safe: hole] ?? nil
        vc.existingScore = game.scores[safe: playerIndex]?[safe: hole] ?? nil

        vc.onSave = { fairwayHit, girHit, putts, score in
            GameManager.shared.update { g in
                g.normalize(holes: STANDARD_HOLES)

                if g.fairwayHit.count != MAX_PLAYERS || g.fairwayHit.contains(where: { $0.count != STANDARD_HOLES }) {
                    g.fairwayHit = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
                }

                if g.girHit.count != MAX_PLAYERS || g.girHit.contains(where: { $0.count != STANDARD_HOLES }) {
                    g.girHit = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
                }

                if g.puttsPerHole.count != MAX_PLAYERS || g.puttsPerHole.contains(where: { $0.count != STANDARD_HOLES }) {
                    g.puttsPerHole = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
                }

                if g.scores.count != MAX_PLAYERS || g.scores.contains(where: { $0.count != STANDARD_HOLES }) {
                    g.scores = Array(repeating: Array(repeating: nil, count: STANDARD_HOLES), count: MAX_PLAYERS)
                }

                g.fairwayHit[playerIndex][hole] = fairwayHit
                g.girHit[playerIndex][hole] = girHit
                g.puttsPerHole[playerIndex][hole] = putts
                g.scores[playerIndex][hole] = score
            }

            GameManager.shared.saveCurrent()
            self.refreshForCurrentHole()

            print("✅ Saved hole stats")
            print("Player:", playerIndex, "Hole:", hole + 1)
            print("FIR:", fairwayHit as Any, "GIR:", girHit as Any, "Putts:", putts as Any, "Score:", score as Any)
        }

        present(vc, animated: true)
    }
    private func refreshHoleValueLabel() {
        guard let g = GameManager.shared.currentGame else {
            gameDollarsField.text = "$0"
            return
        }

        let hole = g.hole
        guard hole >= 0, hole < g.gameHoleDollarsArray.count else {
            gameDollarsField.text = "$0"
            return
        }

        let value = g.gameHoleDollarsArray[hole]

        gameDollarsField.text = "$\(formatMoney(value))"
    }

    private func formatMoney(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }

    @IBAction func statsTapped(_ sender: UIButton) {
        let vc = StatsContainerViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    private func maybePromptForHoleStats() {
        guard let game = GameManager.shared.currentGame,
              !game.holeStatsPromptMuted else { return }
        guard !hasPromptedForThisHole else { return }

        hasPromptedForThisHole = true

        let ac = UIAlertController(
            title: "Add Hole Stats?",
            message: "Track Fairway, GIR, and Putts for this hole.",
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Skip", style: .cancel))

        ac.addAction(UIAlertAction(title: "Add Stats", style: .default) { [weak self] _ in
            self?.holeStatsTapped(UIButton())
        })

        ac.addAction(UIAlertAction(title: "Don't Ask Again", style: .destructive) { _ in
            GameManager.shared.currentGame?.holeStatsPromptMuted = true
            GameManager.shared.saveCurrent()
        })

        present(ac, animated: true)
    }
    @IBAction func statsButtonTapped(_ sender: UIButton) {
        let vc = GameStatsViewController()
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
    private func updateHoleUI() {
        guard let game = GameManager.shared.currentGame else { return }
        guard (0..<STANDARD_HOLES).contains(currentHole) else { return }

        let fields = scoreFields.sorted { $0.tag < $1.tag }
        let seats = min(MAX_PLAYERS, fields.count, game.scores.count)

        for player in 0..<seats {
            let val = game.scores[player][currentHole]
            fields[player].text = val.map(String.init) ?? ""
        }

        if fields.count > seats {
            for i in seats..<fields.count {
                fields[i].text = ""
            }
        }

        // Optional:
        // holePlayingLabel.text = "Hole \(currentHole + 1)"
        // parLabel.text = "Par \(game.course.pars[currentHole])"
    }
    private func paintReRoll(_ g: GameData, hole h: Int) {
        let rollOn   = g.rollApplied[safe: h]   ?? false
        let rerollOn = (g.rerollApplied[safe: h] ?? false) && rollOn

        styleButton(rerollPushed,
                    isOn: rerollOn,
                    enabled: rollOn,
                    onTitle: "Re-Roll On",
                    offTitle: "Re-Roll",
                    onColor: .label,
                    offColor: .systemOrange)
    }
    private func styleButton(_ b: UIButton,
                             isOn: Bool,
                             enabled: Bool = true,
                             onTitle: String, offTitle: String,
                             onColor: UIColor, offColor: UIColor) {
        b.isEnabled = enabled
        b.isSelected = isOn

        if var cfg = b.configuration {
            cfg.baseBackgroundColor = isOn ? onColor : offColor
            cfg.baseForegroundColor = isOn ? .systemBackground : .white
            cfg.title = isOn ? onTitle : offTitle
            b.configuration = cfg
        } else {
            b.backgroundColor = isOn ? onColor : offColor
            b.setTitle(isOn ? onTitle : offTitle, for: .normal)
            b.setTitleColor(.white, for: .normal)
            b.setTitleColor(.systemBackground, for: .selected)
        }
        b.tintColor = isOn ? .systemBackground : .white
    }

    // MARK: - POPS (handicap strokes per hole)

    // 0, 1, 2 (3+ if delta ≥ 36...), standard allocation:
    // pops = floor(delta/18) + ((delta % STANDARD_HOLES) >= strokeIndex ? 1 : 0)
   
    
    func indexFor(hole: Int, player: Int) -> Int {
        return hole * MAX_PLAYERS + player   // 9 players per hole
    }

    
    private func paintEverythingForCurrentHole() {
        refreshHeaderForCurrentHole()          // ← paints Hole/Par/SI/$
        refreshPlayerNameLabels()
        refreshWolfButtons()
        refreshProxButtons()
        refreshScoreFieldsForCurrentHole()
        refreshMoneyFieldsForCurrentHole()
    }
    
    private func setMoneyField(_ field: UITextField, to value: Int) {
        field.text = "\(abs(value))"
        field.textColor = value < 0 ? .systemRed : .label
        field.backgroundColor = moneyBgColor(for: Double(value))
    }


    private func refreshMoneyFieldsForCurrentHole() {
        guard let g = GameManager.shared.currentGame else { return }
        let h = g.hole
        let order = displayOrder
        let slots = min(playerMoneyFields.count, MAX_PLAYERS)
        for s in 0..<slots {
            let seat = order[safe: s] ?? s
            let raw: Double = (seat < g.playerMoney.count && h < g.playerMoney[seat].count) ? g.playerMoney[seat][h] : 0.0
            let whole = Int(raw.rounded())
            setMoneyField(playerMoneyFields[s], to: whole)
            playerMoneyFields[s].tag = seat
        }
    }


    @objc private func scoreChanged(_ sender: UITextField) {
        let seat = sender.tag
        let val = Int(sender.text ?? "")          // nil if blank or non-numeric

        GameManager.shared.update { g in
            guard (0..<GameData.capacity).contains(seat),
                  (0..<GameData.holes).contains(g.hole) else { return }
            g.setScoreForCurrentHole(player: seat, val)
        }
        // Optional: if you show totals or derived UI, repaint here
        // refreshForCurrentHole()
    }

    private func paintBetButtons(_ g: GameData, hole h: Int) {
        let rollOn   = g.rollApplied[safe: h]   ?? false
        let rerollOn = (g.rerollApplied[safe: h] ?? false) && rollOn
        let aloneOn  = g.aloneApplied[safe: h]  ?? false
        let pressOn  = g.pressMask[safe: h]     ?? false

        rollPushed.isSelected    = rollOn
        rerollPushed.isSelected  = rerollOn
        rerollPushed.isEnabled   = rollOn      // disabled look when Roll is off
        alonePushed.isSelected   = aloneOn
        pressedPushed2.isSelected = pressOn
    }
    private func showGameOnboardingIfNeeded() {
        let key = "onboarding_game_shown"
        let defaults = UserDefaults.standard

        if defaults.bool(forKey: key) { return }

        let ac = UIAlertController(
            title: "How to Score a Hole",
            message: """
    Enter each player’s score.

    Set Prox if needed and choose the Wolf player.

    Tap Update Scores to calculate the hole.
    """,
            preferredStyle: .alert
        )

        ac.addAction(UIAlertAction(title: "Got It", style: .default))

        ac.addAction(UIAlertAction(title: "Later", style: .cancel))

        ac.addAction(UIAlertAction(title: "Don't Show Again", style: .destructive) { _ in
            defaults.set(true, forKey: key)
        })

        present(ac, animated: true)
    }
    @objc private func moneyChanged(_ sender: UITextField) {
        let seat = sender.tag
        let amount = Double(sender.text ?? "") ?? 0.0
        GameManager.shared.update { g in
            g.setMoneyForCurrentHole(player: seat, amount: amount)
        }
    }


    private func setMoneyField(_ field: UITextField?, to value: Double) {
        guard let f = field else { return }
        let shown = abs(value)                    // ← no minus sign
        f.text = String(format: "%.1f", shown)
        f.textColor = value < 0 ? .systemRed : .label
    }
    private func setupToggleButton(_ b: UIButton?,
                                   onColor: UIColor,
                                   offColor: UIColor,
                                   onTitle: String,
                                   offTitle: String) {
        guard let b = b else { return }
        b.configuration = nil                           // kill config override
        b.setBackgroundImage(.pixel(of: onColor),  for: .selected)
        b.setBackgroundImage(.pixel(of: offColor), for: .normal)
        b.setTitle(onTitle,  for: .selected)
        b.setTitle(offTitle, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.setTitleColor(.systemBackground, for: .selected)
        b.layer.cornerRadius = 10
        b.clipsToBounds = true
    }
    // Simple/direct painting (no UIButton.Configuration)
    private func refreshProxButtons() {
        guard let g = GameManager.shared.currentGame else { return }
        let hole = max(0, min(17, g.hole))
        let winner = (0..<g.proxWinnerPerHole.count).contains(hole) ? g.proxWinnerPerHole[hole] : nil
        let order = displayOrder

        for (slot, b) in proxButtons.enumerated() {
            let seat = order[safe: slot] ?? slot
            b.tag = seat
            let isOn = (winner == seat)
            b.backgroundColor = isOn ? .label : .systemGreen
            b.setTitleColor(isOn ? .systemBackground : .white, for: .normal)
            b.layer.cornerRadius = 10
            b.layer.masksToBounds = true
        }
    }
    // MARK: - Debug Tests
    private enum AppSettingsKeys {
        static let holeStatsPromptMuted = "holeStatsPromptMuted"
    }

    enum AppSettings {
        static var holeStatsPromptMuted: Bool {
            get { UserDefaults.standard.bool(forKey: AppSettingsKeys.holeStatsPromptMuted) }
            set { UserDefaults.standard.set(newValue, forKey: AppSettingsKeys.holeStatsPromptMuted) }
        }
    }
    @IBAction func testPasteParsingTapped(_ sender: UIButton) {
        let sharedText = """
        WolfMore Remote Round

        Copy this code into WolfMore:

        eyJwYXJzIjpbNCw0LDQsNCw0LDQsNCw0LDQsNCw0LDQsNCw0LDQsNCw0LDRdLCJoY3MiOlsxLDIsMyw0LDUsNiw3LDgsOSwxMCwxMSwxMiwxMywxNCwxNSwxNiwxNywxOF0sInNjb3JlcyI6WzMsNCw0LDQsNCw0LDQsNCw0LDQsNCw0LDQsNCw0LDQsNCw0XSwiZmFpcndheXMiOltudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbF0sInBsYXllck5hbWUiOiJCdWNreSIsImNvdXJzZU5hbWUiOiJXb2xmTW9yZSIsImdpcnMiOltudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbF0sInB1dHRzIjpbbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGwsbnVsbCxudWxsLG51bGxdfQ==
        """

        let lines = sharedText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let code = lines.last ?? sharedText

        print("Extracted code:", code.prefix(50))

        if let round = RemoteRoundCodec.decode(code) {
            print("✅ Parsed player:", round.playerName)
        } else {
            print("❌ Failed to parse pasted share text")
        }
    }
}
   

