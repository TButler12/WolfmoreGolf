import Foundation

// Shared pairing engine for Remote Nassau.
//
// Same course  → slot index == physical hole index (index 0 = hole 1, etc.).
// Different    → each nine is sorted by HC rank; hardest vs hardest.
//                All 9 front + 9 back slots are always returned.
//                Unplayed holes have nil grossA/grossB and winner == .noResult.
//
// Use this in both the live view and the final scorer so mid-round pairings
// never shift as holes are added, and live / final results always agree.

enum RemoteNassauPairing {

    struct Slot {
        let hcRank: Int         // 1-based within the nine (1 = hardest)
        let indexA: Int         // 0-based hole array index in round A
        let indexB: Int         // 0-based hole array index in round B
        let grossA: Int?
        let grossB: Int?
        let netA: Int?
        let netB: Int?
        let parA: Int?
        let parB: Int?
        let strokesA: Int       // HC strokes A receives on this hole
        let strokesB: Int       // HC strokes B receives on this hole
        let winner: RemoteHoleWinner
    }

    /// Build all 18 fixed slots for a pair of rounds.
    /// `sameCourse` true  → slots are in physical hole order.
    /// `sameCourse` false → slots are in HC-rank order within each nine.
    static func buildSlots(a: SharedRound, b: SharedRound, sameCourse: Bool) -> [Slot] {
        let lowerCH  = min(a.courseHandicap, b.courseHandicap)
        let aStrokes = max(0, a.courseHandicap - lowerCH)
        let bStrokes = max(0, b.courseHandicap - lowerCH)
        return buildNineSlots(a: a, b: b, range: 0..<9,  aStrokes: aStrokes, bStrokes: bStrokes, sameCourse: sameCourse)
             + buildNineSlots(a: a, b: b, range: 9..<18, aStrokes: aStrokes, bStrokes: bStrokes, sameCourse: sameCourse)
    }

    /// Indices within `range` sorted by ascending HC value (hardest first).
    /// Used by the live view to look up which physical hole occupies each fixed slot.
    static func hcSortedIndices(hcs: [Int], range: Range<Int>) -> [Int] {
        range.sorted { i, j in
            let hi = hcs[safe: i] ?? 99
            let hj = hcs[safe: j] ?? 99
            return hi == hj ? i < j : hi < hj
        }
    }

    // MARK: - Private

    private static func buildNineSlots(
        a: SharedRound, b: SharedRound,
        range: Range<Int>,
        aStrokes: Int, bStrokes: Int,
        sameCourse: Bool
    ) -> [Slot] {
        if sameCourse {
            return range.map { i in
                makeSlot(a: a, b: b, aIdx: i, bIdx: i,
                         rank: i - range.lowerBound + 1,
                         aStrokes: aStrokes, bStrokes: bStrokes)
            }
        } else {
            let aOrder = hcSortedIndices(hcs: a.hcs, range: range)
            let bOrder = hcSortedIndices(hcs: b.hcs, range: range)
            return (0..<9).map { r in
                makeSlot(a: a, b: b, aIdx: aOrder[r], bIdx: bOrder[r],
                         rank: r + 1,
                         aStrokes: aStrokes, bStrokes: bStrokes)
            }
        }
    }

    private static func makeSlot(
        a: SharedRound, b: SharedRound,
        aIdx: Int, bIdx: Int, rank: Int,
        aStrokes: Int, bStrokes: Int
    ) -> Slot {
        let grossA: Int? = aIdx < a.scores.count ? a.scores[aIdx] : nil
        let grossB: Int? = bIdx < b.scores.count ? b.scores[bIdx] : nil
        let hcA   = a.hcs[safe: aIdx] ?? STANDARD_HOLES
        let hcB   = b.hcs[safe: bIdx] ?? STANDARD_HOLES
        let popsA = NassauEngine.pops(for: aStrokes, strokeIndex: hcA)
        let popsB = NassauEngine.pops(for: bStrokes, strokeIndex: hcB)
        let netA  = grossA.map { $0 - popsA }
        let netB  = grossB.map { $0 - popsB }
        let parA  = a.pars[safe: aIdx]
        let parB  = b.pars[safe: bIdx]
        let winner: RemoteHoleWinner
        if let na = netA, let nb = netB {
            if let pa = parA, let pb = parB {
                let relA = na - pa, relB = nb - pb
                if relA < relB      { winner = .playerA }
                else if relB < relA { winner = .playerB }
                else                { winner = .tie }
            } else {
                if na < nb      { winner = .playerA }
                else if nb < na { winner = .playerB }
                else            { winner = .tie }
            }
        } else {
            winner = .noResult
        }
        return Slot(hcRank: rank, indexA: aIdx, indexB: bIdx,
                    grossA: grossA, grossB: grossB,
                    netA: netA, netB: netB,
                    parA: parA, parB: parB,
                    strokesA: popsA, strokesB: popsB,
                    winner: winner)
    }
}

