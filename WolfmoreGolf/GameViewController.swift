//
//  GameViewController.swift
//  Wolfmore-5Man

import UIKit

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
final class GameViewController: UIViewController {
    
    // MARK: - Outlets
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
    @IBOutlet private var playerNameFields: [UITextField]!
    
    @IBOutlet weak var pressedPushed2: UIButton!
    
    @IBOutlet weak var rerollPushed: UIButton!
    
    @IBOutlet weak var rollPushed: UIButton!
    @IBOutlet weak var w0: UIButton!
    @IBOutlet weak var w1: UIButton!
    @IBOutlet weak var w2: UIButton!
    @IBOutlet weak var w3: UIButton!
    @IBOutlet weak var w4: UIButton!
   
    private var wolfButtons: [UIButton] { [w0, w1, w2, w3, w4] }
   
    @IBOutlet private weak var p0: UIButton!
    @IBOutlet private weak var p1: UIButton!
    @IBOutlet private weak var p2: UIButton!
    @IBOutlet private weak var p3: UIButton!
    @IBOutlet private weak var p4: UIButton!

    @IBOutlet weak var UpdateScores: UIButton!
    
    // Do NOT connect this in IB — it’s computed from the 5 outlets above.
    private var proxButtons: [UIButton] { [p0, p1, p2, p3, p4] }

    private var currentHole: Int = 0

    var hole = (0)
 
    var playersFallback: [Player]?
    
    private var game: GameData? { GameManager.shared.currentGame }

    
    // MARK: - State
    
    private var isUmbrellaOn = false
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scoreFields.forEach {
                $0.keyboardType = .numberPad
                $0.inputAccessoryView = makeDoneToolbar()   // adds a Done button above the pad
            }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        totalMoneyLabels = totalMoneyLabels.sorted { $0.tag < $1.tag } // if using tags
           refreshTotalMoneyLabels()
        
        setupToggleButton(rollPushed,    onColor: .black, offColor: .systemOrange, onTitle: "Roll On",    offTitle: "Roll")
           setupToggleButton(rerollPushed,  onColor: .black, offColor: .systemOrange, onTitle: "Re-Roll On", offTitle: "Re-Roll")
           setupToggleButton(alonePushed,   onColor: .black, offColor: .systemOrange, onTitle: "Alone On",   offTitle: "Alone")
           setupToggleButton(pressedPushed2,onColor: .black, offColor: .systemOrange, onTitle: "Press On",   offTitle: "Press")

        // Fallback only (SceneDelegate should have loaded/normalized already)
        if GameManager.shared.currentGame == nil {
            GameManager.shared.startNewGame()
            GameManager.shared.normalizeCurrentIfNeeded()
        }
        
        // Wire score fields to persist on edit end
        for (i, f) in scoreFields.enumerated() {
            f.tag = i
            f.keyboardType = .numberPad
            f.addTarget(self, action: #selector(scoreEdited(_:)), for: .editingDidEnd)
        }
        
        for (i, tf) in playerMoneyFields.enumerated() {
            tf.tag = i                     // seat index 0…4
            tf.isUserInteractionEnabled = true
            tf.textAlignment = .right
            tf.keyboardType = .decimalPad
            tf.addTarget(self, action: #selector(moneyChanged(_:)), for: .editingChanged)
        }

        // Button tags for seats
        for (i, b) in wolfButtons.enumerated() { b.tag = i }
        for (i, b) in proxButtons.enumerated() { b.tag = i }
        styleWolfButtons()
        
        // One observer (once)
        
        // First paint: single canonical painter
        paintEverythingForCurrentHole()
        
        // Optional debugging
        // debugStrokes("GameVC viewDidLoad")
        refreshForCurrentHole()
        // Map seat index 0…4 to the Wolf/Prox UI; scores match seats 0…4 as well.
         for (i, b) in wolfButtons.enumerated() { b.tag = i }
         for (i, b) in proxButtons.enumerated() { b.tag = i }
         for (i, tf) in scoreFields.enumerated() {
             tf.tag = i
             tf.keyboardType = .numberPad
             tf.addTarget(self, action: #selector(scoreChanged(_:)), for: .editingChanged)
         }

         if GameManager.shared.currentGame == nil {
             GameManager.shared.startNewGame()
         }
        refreshForCurrentHole()
        paintEverythingForCurrentHole()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .reloadUI, object: nil)
    }

    

    
    @inline(__always)
    private func moneyStringNoMinus(_ x: Double) -> String {
        plainMoneyFmt.string(from: NSNumber(value: abs(x))) ?? String(format: "%.1f", abs(x))
    }

    @inline(__always)
    private func setTotalMoneyLabel(_ label: UILabel, _ value: Double) {
        label.text = moneyStringNoMinus(value)           // e.g., "212.3"
        label.textColor = (value < 0) ? .systemRed : .label
    }

    func refreshTotalMoneyLabels() {
        guard let g = GameManager.shared.currentGame else { return }

        // seat × hole matrix
        let money: [[Double]] = !g.playerMoney.isEmpty
            ? g.playerMoney
            : Array(repeating: Array(repeating: 0.0, count: 18), count: 9)

        // totals per seat (sum holes 0…17)
        let totals: [Double] = money.map { row in row.prefix(18).reduce(0.0, +) }

        // paint labels in order (or use label.tag as seat index if you sorted by tag)
        let seatsToPaint = min(totalMoneyLabels.count, totals.count)
        for i in 0..<seatsToPaint {
            setTotalMoneyLabel(totalMoneyLabels[i], totals[i])
        }
    }

    private let plainMoneyFmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1   // ← one decimal
        f.maximumFractionDigits = 1   // ← one decimal
        return f
    }()


    @inline(__always)
    private func setMoneyLabel(_ label: UILabel, _ value: Double) {
        label.text = moneyStringNoMinus(value)            // no minus sign
        label.textColor = (value < 0) ? .systemRed : .label
    }

    // Paint all 5 Wolf buttons from the saved model state (multiple Wolves allowed)
    
    // One place to set the ON/OFF look
    private func applyWolfStyle(_ button: UIButton, isOn: Bool) {
        if #available(iOS 15.0, *) {
            var c = button.configuration ?? .filled()
            c.baseForegroundColor = .white
            c.baseBackgroundColor = isOn ? .black : .systemGreen
            c.cornerStyle = .large
            button.configuration = c
        } else {
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = isOn ? .black : .systemGreen
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
            let hole = max(0, min(g.hole, g.gameHoleDollarsArray.count - 1))
            guard hole < g.gameHoleDollarsArray.count else { return }

            // start from current (if somehow 0 from an old save, treat as default 2.0)
            var amount = g.gameHoleDollarsArray[hole]
            if amount == 0 { amount = 2.0 }

            amount += delta
            amount = max(1.0, amount)                 // ← minimum is $1
            amount = (amount * 2.0).rounded() / 2.0   // ← snap to .5 increments

            g.gameHoleDollarsArray[hole] = amount
        }

        refreshForCurrentHole()
    }
    private func populateNames() {
        let names = game?.playerNames ?? []
        for (i, field) in playerNameFields.enumerated() {
            field.text = i < names.count ? names[i] : ""
        }
    }
    private func roundToHalf(_ x: Double) -> Double { (x * 2).rounded() / 2.0 }
    
    private func syncAloneButtonForHole(_ hole: Int) {
        guard let g = GameManager.shared.currentGame else { return }
        let on = (hole < g.aloneApplied.count) ? g.aloneApplied[hole] : false
        alonePushed.isSelected = on
        alonePushed.backgroundColor = on ? .black : .systemOrange
        alonePushed.setTitle(on ? "Alone On" : "Alone", for: .normal)
    }
    // Paint all 5 buttons from the saved model (multiple Wolves allowed)
    private func refreshWolfButtons() {
        guard let g = GameManager.shared.currentGame else { return }
        let hole = max(0, min(17, g.hole))

        for b in wolfButtons {
            let i = b.tag
            guard (0..<5).contains(i),
                  g.wolfButtonStatus.count == 5,
                  g.wolfButtonStatus[i].count == 18 else { continue }

            let isOn = g.wolfButtonStatus[i][hole]
            applyWolfStyleDirect(b, isOn: isOn)
        }
    }

    // Simple, reliable painting
    private func applyWolfStyleDirect(_ button: UIButton, isOn: Bool) {
        button.backgroundColor = isOn ? .black : .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.setNeedsLayout()
        button.layoutIfNeeded()
    }
   

    private func refreshForCurrentHole() {
        guard let g = GameManager.shared.currentGame else { return }
        let h = g.hole
        
        for (seat, tf) in playerMoneyFields.enumerated() {
               let amt = g.moneyFor(hole: h, player: seat)
               tf.text = amt == 0 ? "" : String(format: "%.2f", amt)
               tf.isEnabled = (g.playerActivated[safe: seat] ?? true)
               tf.alpha = tf.isEnabled ? 1.0 : 0.4
           }
        
        paintReRoll(g, hole: h)
        paintBetButtons(g, hole: h)
        // Header
        holePlaying.text = "\(h + 1)"
        parOfHole.text   = "\(g.courseParToPass[safe: h] ?? 4)"
        gameDollarsField.text = String(format: "%.2f", g.gameHoleDollarsArray[safe: h] ?? 2.0)

        // --- Your existing roll / re-roll / alone / PRESS paint here (unchanged) ---

        // Wolf
        let wolfSeat = g.wolfIndexPerHole[safe: h] ?? nil
        for (i, b) in wolfButtons.enumerated() {
            let isWolf = (wolfSeat == i)
            b.isSelected = isWolf
            b.backgroundColor = isWolf ? .black : .systemGreen
        }

        // Prox (single winner)
        let proxSeat = g.proxWinnerPerHole[safe: h] ?? nil
        for (i, b) in proxButtons.enumerated() {
            let on = (proxSeat == i)
            b.isSelected = on
            b.backgroundColor = on ? .systemGreen : .systemGray
        }

        // Scores (hole-first view)
        let holeScores = g.scoresByHole[safe: h] ?? []    // ✅

        for (i, tf) in scoreFields.enumerated() {
            tf.text = (holeScores[safe: i] ?? nil).map(String.init) ?? ""
            tf.isEnabled = (g.playerActivated[safe: i] ?? true)
            tf.alpha = tf.isEnabled ? 1.0 : 0.4
        }

        // Pops painter (unchanged)
        paintHolePops(blankZeros: false)
    }

    // Paint per-hole POPS into playerStrokesFields
    private func paintHolePops(blankZeros: Bool = false) {
        guard let g = GameManager.shared.currentGame else { return }

        let hole = max(0, min(17, g.hole))

        // SI from new course arrays, clamped to 1…18 (treat 0 as 18)
        let rawSI = g.course.holeHandicaps[safe: hole] ?? 18
        let si    = max(1, min(18, rawSI == 0 ? 18 : rawSI))

        // Seats we can actually show
        let seats = min(9, g.playerNames.count, g.hcPlayers.count, g.playerActivated.count)

        // Baseline = lowest HC among ACTIVE, named seats (fallback to all named if none active)
        let activeSeats = (0..<seats).filter {
            g.playerActivated[$0] &&
            !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let baselineSeats = activeSeats.isEmpty
            ? (0..<seats).filter { !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            : activeSeats
        //let baseHC = baselineSeats.map { g.hcPlayers[$0] }.min() ?? 0
        let baseHC = activeSeats.map { g.hcPlayers[$0] }.min() ?? 0

        // Paint pops to the stroke fields
        let limit = min(playerStrokesFields.count, seats)
        for seat in 0..<limit {
            let hasName  = !g.playerNames[seat].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let showRow  = activeSeats.isEmpty ? hasName : (hasName && g.playerActivated[seat])

            if showRow {
                let delta = max(0, g.hcPlayers[seat] - baseHC)      // S column value for this seat
                let p = pops(for: delta, strokeIndex: si)           // uses your single pop formula
                playerStrokesFields[seat].text = (blankZeros && p == 0) ? "" : String(p)
            } else {
                playerStrokesFields[seat].text = ""
            }
        }

        // Optional debug
        // print("POPS H\(hole+1) SI=\(si) baseHC=\(baseHC)")
    }
    // Single source-of-truth pop formula (standard):
    // +floor(S/18) on every hole, plus +1 on SI 1…(S % 18).
   
    private func pops(for delta: Int, strokeIndex: Int) -> Int {
        let si = max(1, min(18, strokeIndex == 0 ? 18 : strokeIndex))  // clamp SI to 1…18; 0 → 18
        let d  = max(0, delta)
        let full = d / 18
        let rem  = d % 18
        return full + ((rem > 0 && si <= rem) ? 1 : 0)
    }
   
    private func siAt(_ hole: Int, in course: Course) -> Int {
        let raw = course.holeHandicaps.indices.contains(hole) ? course.holeHandicaps[hole] : 18
        // clamp 0→18, then into 1…18
        return max(1, min(18, raw == 0 ? 18 : raw))
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
    
   
   
    @IBAction func pressedPush2(_ sender: UIButton) {
        GameManager.shared.update { g in
            // Ensure arrays exist (old save safety)
            if g.pressMask.count != 18        { g.pressMask        = Array(repeating: false, count: 18) }
            if g.pressBaseDollars.count != 18 { g.pressBaseDollars = Array(repeating: 0.0,  count: 18) }
            if g.gameHoleDollarsArray.count != 18 { g.gameHoleDollarsArray = Array(repeating: 2.0, count: 18) }

            func roundToHalf(_ x: Double) -> Double { (x * 2).rounded() / 2.0 }

            // Restore any currently pressed holes back to their remembered base
            func restorePressedRange() {
                let limit = min(18, g.gameHoleDollarsArray.count)
                for i in 0..<limit where g.pressMask[i] {
                    let base = (g.pressBaseDollars[i] == 0 ? g.gameHoleDollarsArray[i] : g.pressBaseDollars[i])
                    g.gameHoleDollarsArray[i] = roundToHalf(max(1.0, base))
                    g.pressMask[i] = false
                    g.pressBaseDollars[i] = 0
                }
            }

            let count = min(18, g.gameHoleDollarsArray.count)
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
            if g.rerollApplied.count != 18     { g.rerollApplied     = Array(repeating: false, count: 18) }
            if g.rerollBaseAmount.count != 18  { g.rerollBaseAmount  = Array(repeating: 0.0,  count: 18) }
            if g.gameHoleDollarsArray.count != 18 { g.gameHoleDollarsArray = Array(repeating: 2.0, count: 18) }

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
            if g.rollApplied.count != 18 { g.rollApplied = Array(repeating: false, count: 18) }
            if g.rollBaseAmount.count != 18 { g.rollBaseAmount = Array(repeating: 0.0, count: 18) }
            if g.rerollApplied.count != 18 { g.rerollApplied = Array(repeating: false, count: 18) }
            if g.rerollBaseAmount.count != 18 { g.rerollBaseAmount = Array(repeating: 0.0, count: 18) }
            if g.gameHoleDollarsArray.count != 18 { g.gameHoleDollarsArray = Array(repeating: 2.0, count: 18) }

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
            sender.backgroundColor = .black
            sender.setTitle("Roll On", for: .normal)
        } else {
            sender.backgroundColor = .systemOrange
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
            if m.scores.count != 9 || m.scores.first?.count != 18 {
                m.scores = Array(repeating: Array(repeating: nil, count: 18), count: 9)
            }
            if (0..<9).contains(seat), (0..<18).contains(hole) {
                m.scores[seat][hole] = val
            }
        }
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
    private func recalcStrokesFromModel() {
        guard let g = GameManager.shared.currentGame else { return }

        let hole = max(0, min(17, g.hole))
        // Use your course SI array; clamp 1…18; treat 0 as 18
        let rawSI = (hole < g.courseHCToPass.count) ? g.courseHCToPass[hole] : 18
        let si    = max(1, min(18, rawSI == 0 ? 18 : rawSI))

        // Seats we can show
        let seats = min(9, g.playerNames.count, g.hcPlayers.count, g.playerActivated.count)

        // ACTIVE seats with non-empty name
        let activeSeats: [Int] = (0..<seats).filter {
            g.playerActivated[$0] &&
            !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !activeSeats.isEmpty else {
            // nothing active -> clear UI and bail
            for tf in playerStrokesFields { tf.text = "" }
            return
        }

        // Baseline = lowest HC among ACTIVE players
        let baseHC = activeSeats.map { g.hcPlayers[$0] }.min() ?? 0

        // Local helper so it’s in scope
        func strokesGiven(delta S: Int, strokeIndex: Int) -> Int {
            let d = max(0, S)
            let base  = d / 18          // +1 on every hole per full 18
            let rem   = d % 18          // +1 on SI 1…rem
            let extra = (strokeIndex <= rem) ? 1 : 0
            return base + extra
        }

        // Paint pops to UI (only for active seats; others blank)
        let limit = min(playerStrokesFields.count, seats)
        for i in 0..<limit {
            let hasName = !g.playerNames[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let isActive = hasName && (g.playerActivated[i])
            if isActive {
                let S = max(0, g.hcPlayers[i] - baseHC)
                let pops = strokesGiven(delta: S, strokeIndex: si)
                playerStrokesFields[i].text = String(pops)
            } else {
                playerStrokesFields[i].text = ""
            }
        }

        // Debug
        print("🟠 recalcStrokesFromModel → H\(hole+1) SI=\(si) baseHC(active)=\(baseHC) activeSeats=\(activeSeats)")
    }

    private func debugStrokes(_ tag: String) {
        guard let g = GameManager.shared.currentGame else { return }
        print("🧮[\(tag)] names:", g.playerNames)
        print("🧮[\(tag)] actives:", g.playerActivated)
        print("🧮[\(tag)] HCs:", g.hcPlayers)
    }

    private func refreshScoreFieldsForCurrentHole() {
        guard let g = GameManager.shared.currentGame else { return }
        let h = g.hole
        let seats = min(scoreFields.count, g.scores.count)
        for s in 0..<seats {
            let v = (h < g.scores[s].count) ? g.scores[s][h] : nil
            scoreFields[s].text = v.map(String.init) ?? ""
        }
    }

    private func refreshMoneyFieldsForCurrentHole() {
        guard let g = GameManager.shared.currentGame else { return }
        let h = g.hole
        let seats = min(playerMoneyFields.count, g.playerMoney.count)
        for s in 0..<seats {
            let val = (h < g.playerMoney[s].count) ? g.playerMoney[s][h] : 0
            setMoneyField(playerMoneyFields[s], to: val) // uses abs + red for negatives
        }
    }

       
    @IBAction private func updateDollarsTapped(_ sender: UIButton) {
        // quick flash
        let oldColor = sender.backgroundColor
        sender.backgroundColor = .black
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
            g.gameHoleDollarsArray = Array(repeating: amount, count: 18)
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
        isUmbrellaOn.toggle()
        UIView.animate(withDuration: 0.25) {
            sender.backgroundColor = self.isUmbrellaOn ? .green : .systemOrange
            sender.setTitle(self.isUmbrellaOn ? "Umbrella - Off -" : "Umbrella - On -", for: .normal)
        }
        UserDefaults.standard.set(isUmbrellaOn, forKey: "isUmbrellaOn")
    }
    @IBAction func previousHoleTapped(_ sender: UIButton) {
        currentHole = (currentHole - 1 + 18) % 18
        GameManager.shared.update { $0.hole = currentHole }
        refreshForCurrentHole()
        paintEverythingForCurrentHole()
        refreshWolfButtons()
      
        refreshTotalMoneyLabels()

        
    }
    
    @IBAction func nextHoleTapped(_ sender: UIButton) {
        currentHole = (currentHole + 1) % 18
        GameManager.shared.update { $0.hole = currentHole }   // ← sync to model
        refreshForCurrentHole()
        
        refreshWolfButtons()
        paintEverythingForCurrentHole()
        refreshTotalMoneyLabels()

        
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
   
 

    private func refreshHeaderForCurrentHole() {
        DispatchQueue.main.async {
            guard let game = GameManager.shared.currentGame else { return }
            let h = self.currentHole
            let holeNo = h + 1

            let pars = game.course.pars
            let hcs  = game.course.holeHandicaps
            let par  = pars.indices.contains(h) ? pars[h] : 4
            let si   = hcs.indices.contains(h)  ? hcs[h]  : holeNo

            let dollarsArray = game.gameHoleDollarsArray
            let dollars = dollarsArray.indices.contains(h) ? dollarsArray[h] : 0.0

            // ✅ Numbers only (no "Hole"/"Par" prefixes)
            self.holePlaying.text = "\(holeNo)"
            self.parOfHole.text   = "\(par)"

            // (If you want numbers only for these too, uncomment:)
            // self.strokeIndexLabel?.text = "\(si)"
            // self.dollarsPerHoleLabel?.text = String(format: "%.2f", dollars)

            print("Header -> hole \(holeNo), par \(par), si \(si), $\(dollars)")
        }
    }

    @IBAction func alonePushedTapped(_ sender: UIButton) {
        sender.isSelected.toggle()

        GameManager.shared.update { g in
            // Ensure arrays are correct length (handles old saves)
            if g.aloneApplied.count != 18     { g.aloneApplied     = Array(repeating: false, count: 18) }
            if g.aloneBaseAmount.count != 18  { g.aloneBaseAmount  = Array(repeating: 0.0,  count: 18) }
            if g.gameHoleDollarsArray.count != 18 { g.gameHoleDollarsArray = Array(repeating: 2.0, count: 18) }

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

        // Button visuals: orange (off) ↔︎ brown (on)
        if sender.isSelected {
            sender.backgroundColor = .black
            sender.setTitle("Alone On", for: .normal)
        } else {
            sender.backgroundColor = .systemOrange
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
        guard (0..<5).contains(player) else { return }

        GameManager.shared.update { g in
            let hole = max(0, min(17, g.hole))
            if g.wolfButtonStatus.count != 5 || g.wolfButtonStatus.first?.count != 18 {
                g.wolfButtonStatus = Array(repeating: Array(repeating: false, count: 18), count: 5)
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

    private func setScore(_ strokes: Int?, playerIndex: Int, holeIndex: Int) {
        GameManager.shared.update { g in
            guard playerIndex < g.playerNames.count,   // ✅ not g.players
                  holeIndex < g.courseParToPass.count else { return }  // ✅ not g.course.pars
            g.scores[playerIndex][holeIndex] = strokes
        }
    }


    // Exclusive prox winner per hole
    @IBAction private func proxButtonTapped(_ sender: UIButton) {
        let player = sender.tag
        guard (0..<5).contains(player) else { return }

        GameManager.shared.update { g in
            if g.proxWinnerPerHole.count != 18 {
                g.proxWinnerPerHole = Array(repeating: nil, count: 18)
            }
            let hole = max(0, min(17, g.hole))
            g.proxWinnerPerHole[hole] = (g.proxWinnerPerHole[hole] == player) ? nil : player
        }

        refreshProxButtons()
    }
   

    @IBAction func updateScorePushed(_ sender: UIButton) {
        sender.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { sender.isEnabled = true }

        paintEverythingForCurrentHole()

        // Snapshot what we need once
        guard let snap = GameManager.shared.currentGame else { return }
        let hole = snap.hole
        guard (0..<18).contains(hole) else { return }
        let pressOnThisHole = (hole < snap.pressedPushedToggleArray.count) ? snap.pressedPushedToggleArray[hole] : false
        let isUmbrella = snap.isUmbrella

        // 1) Persist visible scores
        GameManager.shared.update { g in
            // Ensure shape [seats][18]
            if g.scores.count != 9 || g.scores.first?.count != 18 {
                g.scores = Array(repeating: Array(repeating: nil, count: 18), count: 9)
            }
            let seats = min(5, scoreFields.count, g.scores.count)
            for s in 0..<seats {
                g.scores[s][hole] = Int(scoreFields[s].text ?? "")
            }
        } // ← don't touch `g` after this

        // 2) Optional press carry-forward (if that hole was pressed)
        if pressOnThisHole {
            GameManager.shared.update { g in
                // Guards for safety
                guard hole < g.gameHoleDollarsArray.count,
                      hole < g.pressedPushedToggleArray.count else { return }
                let end  = (hole < 9) ? 9 : 18
                let base = g.gameHoleDollarsArray[hole]
                for idx in hole..<min(end, g.gameHoleDollarsArray.count) {
                    if idx < g.pressedPushedToggleArray.count {
                        g.pressedPushedToggleArray[idx] = true
                    }
                    g.gameHoleDollarsArray[idx] = base
                }
            }
        }

        // 3) Compute payouts for this hole from current model
        let payouts = GameManager.shared.computeHolePayout(hole: hole, umbePressed: isUmbrella)

        // 4) Persist payouts
        GameManager.shared.update { g in
            // Ensure shape [seats][18]
            if g.playerMoney.count != 9 || g.playerMoney.first?.count != 18 {
                g.playerMoney = Array(repeating: Array(repeating: 0, count: 18), count: 9)
            }
            let seats = min(5, playerMoneyFields.count, g.playerMoney.count, payouts.count)
            for s in 0..<seats {
                // If payouts are Double, change playerMoney to [[Double]] or Int(Double.rounded()) here.
                g.playerMoney[s][hole] = payouts[s]
            }
        }

        // 5) Paint UI from payouts
        let seatsToPaint = min(5, min(playerMoneyFields.count, payouts.count))
        for s in 0..<seatsToPaint { setMoneyField(playerMoneyFields[s], to: payouts[s]) }
        refreshTotalMoneyLabels()

        // 6) Debug print
        if let g = GameManager.shared.currentGame {
            let h = g.hole
            let seats = min(5, g.scores.count, g.playerNames.count)
            let scorePart = (0..<seats).map { s -> String in
                let name = g.playerNames[s].isEmpty ? "P\(s+1)" : g.playerNames[s]
                let sc   = g.scores[s][h].map(String.init) ?? "-"
                return "\(name):\(sc)"
            }.joined(separator: "  ")

            let payoutPart = payouts.prefix(seats)
                .map { String(format: "%+.1f", Double($0)) }  // cast if payouts are Int
                .joined(separator: "  ")

            print("H\(h+1)  \(scorePart)  |  $ \(payoutPart)")
        }
        
    }

    private func updateHoleUI() {
        guard let game = GameManager.shared.currentGame else { return }
        let row = game.scores[currentHole]          // [Int?] for the current hole
        let fields = scoreFields.sorted { $0.tag < $1.tag }

        // Fill up to the number of visible fields (should be 5)
        for player in 0..<min(5, fields.count) {
            let val = row[safe: player] ?? nil
            fields[player].text = val.map(String.init) ?? ""
        }
        // Clear extras if any
        if fields.count > 5 {
            for i in 5..<fields.count { fields[i].text = "" }
        }

        // Update headers if you have them
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
                    onColor: .black,
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
            cfg.baseForegroundColor = .white
            cfg.title = isOn ? onTitle : offTitle          // ✅ use title (or use attributedTitle as shown above)
            b.configuration = cfg
        } else {
            b.backgroundColor = isOn ? onColor : offColor
            b.setTitle(isOn ? onTitle : offTitle, for: .normal)
            b.setTitleColor(.white, for: .normal)
            b.setTitleColor(.white, for: .selected)
        }
        b.tintColor = .white
    }

    // MARK: - POPS (handicap strokes per hole)

    // 0, 1, 2 (3+ if delta ≥ 36...), standard allocation:
    // pops = floor(delta/18) + ((delta % 18) >= strokeIndex ? 1 : 0)
   
    
    func indexFor(hole: Int, player: Int) -> Int {
        return hole * 5 + player   // 5 players per hole
    }

    
    private func paintEverythingForCurrentHole() {
        refreshHeaderForCurrentHole()          // ← paints Hole/Par/SI/$
        populateNames()
        refreshWolfButtons()
        refreshProxButtons()
        refreshScoreFieldsForCurrentHole()
        refreshMoneyFieldsForCurrentHole()
       
    }
    @objc private func scoreChanged(_ sender: UITextField) {
        let seat = sender.tag
        let val = Int(sender.text ?? "")          // nil if blank or non-numeric

        GameManager.shared.update { g in
            guard (0..<GameData.capacity).contains(seat),
                  (0..<GameData.holes).contains(g.hole) else { return }
            g.scores[seat][g.hole] = val          // store per player/per hole
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
        b.setTitleColor(.white, for: .selected)
        b.layer.cornerRadius = 10
        b.clipsToBounds = true
    }
    // Simple/direct painting (no UIButton.Configuration)
    private func refreshProxButtons() {
        guard let g = GameManager.shared.currentGame else { return }
        let hole = max(0, min(17, g.hole))
        let winner = (0..<g.proxWinnerPerHole.count).contains(hole) ? g.proxWinnerPerHole[hole] : nil

        for b in proxButtons {
            let isOn = (winner == b.tag)
            b.backgroundColor = isOn ? .black : .systemGreen
            b.setTitleColor(.white, for: .normal)
            b.layer.cornerRadius = 10
            b.layer.masksToBounds = true
        }
    }

}
   

