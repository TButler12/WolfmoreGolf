import Foundation

enum TeamTeeCountMode: String, Codable {
    case fixed, byPar
}

struct TeamTeeSettings: Codable {
    var isEnabled: Bool = false
    var countMode: TeamTeeCountMode = .byPar
    var fixedCount: Int = 2
    var par3Count: Int = 4
    var par4Count: Int = 3
    var par5Count: Int = 2

    func count(forPar par: Int) -> Int {
        switch countMode {
        case .fixed: return max(1, min(4, fixedCount))
        case .byPar:
            switch par {
            case 3:  return max(1, min(4, par3Count))
            case 5:  return max(1, min(4, par5Count))
            default: return max(1, min(4, par4Count))
            }
        }
    }
}

struct TeamTeeHoleResult {
    let holeIndex: Int          // 0-based match position
    let netScore: Int           // sum of lowest-N net scores
    let countedSeats: Set<Int>  // which players' scores were included
    let netsByPlayer: [Int: Int] // seat → net
}

struct TeamTeeResult {
    let seats: [Int]
    let holeResults: [TeamTeeHoleResult?]  // indexed by match hole; nil = not committed / incomplete

    var runningTotal: Int {
        holeResults.compactMap { $0?.netScore }.reduce(0, +)
    }

    var holesCompleted: Int {
        holeResults.compactMap { $0 }.count
    }

    /// Net contributed by a specific seat across all completed holes.
    func netTotal(for seat: Int) -> Int {
        holeResults.compactMap { $0?.netsByPlayer[seat] }.reduce(0, +)
    }

    /// Most recent completed hole result, for dot-indicator refresh.
    var lastCompletedResult: TeamTeeHoleResult? {
        holeResults.reversed().first { $0 != nil } ?? nil
    }
}
