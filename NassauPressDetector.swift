// Pure-logic press detection for Remote Nassau.
// Extracted from LiveNassauViewController so it can be unit-tested without UIKit.
enum NassauPressDetector {

    struct Press {
        let startPos: Int    // 1-based overall position (front: 1–9, back: 10–18)
        let endPos: Int      // end of the nine segment
        let stake: Double
        var runningStatus: [Int]

        init(startPos: Int, endPos: Int, stake: Double) {
            self.startPos     = startPos
            self.endPos       = endPos
            self.stake        = stake
            self.runningStatus = []
        }
    }

    // MARK: - Shared helpers

    static func runningStatus(from pairs: [PairedHole]) -> [Int] {
        var current = 0
        var result: [Int] = []
        for ph in pairs {
            guard ph.hostScore != nil, ph.opponentScore != nil else { continue }
            current += ph.netResult
            result.append(current)
        }
        return result
    }

    static func segmentMoney(status: [Int], complete: Bool, stake: Double) -> Double {
        guard complete, let last = status.last else { return 0 }
        if last > 0 { return  stake }
        if last < 0 { return -stake }
        return 0
    }

    // MARK: - Legacy algorithm (matches without press_v2)
    // Only the original nine's score triggers presses; max 3 per segment.

    static func detectLegacy(
        pairs: [PairedHole],
        holeOffset: Int,
        segmentEndPos: Int,
        trigger: Int,
        stake: Double
    ) -> [Press] {
        let maxPresses = 3
        var presses: [Press] = []
        var current = 0
        var prevAbs = 0

        for (idx, ph) in pairs.enumerated() {
            guard ph.hostScore != nil, ph.opponentScore != nil else { continue }
            current += ph.netResult
            let pos1Based  = holeOffset + idx + 1
            let currentAbs = abs(current)

            if prevAbs < trigger && currentAbs >= trigger && presses.count < maxPresses {
                let startPos = pos1Based + 1
                if startPos <= segmentEndPos {
                    presses.append(Press(startPos: startPos, endPos: segmentEndPos, stake: stake))
                }
            }
            prevAbs = currentAbs
        }
        return withRunningStatus(presses, pairs: pairs, holeOffset: holeOffset)
    }

    // MARK: - press_v2 algorithm
    // Each active segment (original nine + every press) tracks its own running score.
    // Any segment crossing trigger starts a new press on the next hole. No cap.
    // 18-hole overall is never passed here — caller uses the nine segments only.

    static func detectV2(
        pairs: [PairedHole],
        holeOffset: Int,
        segmentEndPos: Int,
        trigger: Int,
        stake: Double
    ) -> [Press] {
        struct ActiveSeg {
            let startIdx: Int
            var cum: Int = 0
            var prevAbs: Int = 0
        }
        var presses: [Press] = []
        var segments = [ActiveSeg(startIdx: 0)]

        for (idx, ph) in pairs.enumerated() {
            guard ph.hostScore != nil, ph.opponentScore != nil else { continue }
            // Snapshot count: segments appended this iteration start next hole.
            let segCount = segments.count
            for i in 0..<segCount {
                guard segments[i].startIdx <= idx else { continue }
                segments[i].cum += ph.netResult
                let cur = abs(segments[i].cum)
                if segments[i].prevAbs < trigger && cur >= trigger {
                    let startPos = holeOffset + idx + 2   // next-hole rule
                    if startPos <= segmentEndPos {
                        presses.append(Press(startPos: startPos, endPos: segmentEndPos, stake: stake))
                        segments.append(ActiveSeg(startIdx: idx + 1))
                    }
                }
                segments[i].prevAbs = cur
            }
        }

        // Sort by start position; ties keep insertion order so both devices agree
        // (original nine fires before earlier presses, which fire before later ones).
        let sorted = presses
            .enumerated()
            .sorted { a, b in
                a.element.startPos == b.element.startPos
                    ? a.offset < b.offset
                    : a.element.startPos < b.element.startPos
            }
            .map { $0.element }

        return withRunningStatus(sorted, pairs: pairs, holeOffset: holeOffset)
    }

    // MARK: - Private

    private static func withRunningStatus(
        _ presses: [Press], pairs: [PairedHole], holeOffset: Int
    ) -> [Press] {
        presses.map { p in
            var info = p
            let si = max(0, p.startPos - 1 - holeOffset)
            let ei = min(pairs.count - 1, p.endPos - 1 - holeOffset)
            if si <= ei { info.runningStatus = runningStatus(from: Array(pairs[si...ei])) }
            return info
        }
    }
}
