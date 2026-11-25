import Foundation

enum CourseValidationError: Error, Equatable {
    case noHoleData
    case wrongHoleCount(got: Int, expected: Int)
    case invalidPar(hole: Int, par: Int)
    case duplicateHandicap(value: Int)
    case handicapOutOfRange(hole: Int, value: Int, max: Int)
    case missingHandicaps
}

extension CourseValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noHoleData:
            return "No hole data available for this course."
        case .wrongHoleCount(let got, let expected):
            return "Expected \(expected) holes, got \(got)"
        case .invalidPar(let hole, let par):
            return "Hole \(hole): par \(par) is invalid (must be 3–6)"
        case .duplicateHandicap(let value):
            return "Handicap \(value) appears more than once"
        case .handicapOutOfRange(let hole, let value, let max):
            return "Hole \(hole): handicap index \(value) is out of range (must be 1–\(max))"
        case .missingHandicaps:
            return "One or more holes are missing a handicap index"
        }
    }
}

struct CourseValidator {
    // Returns nil if valid, otherwise the first validation error found.
    static func validate(pars: [Int], handicaps: [Int]) -> CourseValidationError? {
        let n = pars.count
        guard n == handicaps.count else {
            return .wrongHoleCount(got: handicaps.count, expected: n)
        }
        for (i, par) in pars.enumerated() where !(3...6).contains(par) {
            return .invalidPar(hole: i + 1, par: par)
        }
        var seen = Set<Int>()
        for (i, hc) in handicaps.enumerated() {
            guard (1...n).contains(hc) else {
                return .handicapOutOfRange(hole: i + 1, value: hc, max: n)
            }
            guard seen.insert(hc).inserted else {
                return .duplicateHandicap(value: hc)
            }
        }
        return nil
    }

    // Builds pars and handicaps arrays from the holes endpoint response.
    // Accepts 9- or 18-hole courses only; anything else (including 0) returns noHoleData.
    static func buildArrays(
        from holes: [OpenGolfHoleData]
    ) -> Result<(pars: [Int], handicaps: [Int]), CourseValidationError> {
        guard holes.count == 9 || holes.count == 18 else {
            return .failure(.noHoleData)
        }
        let pars = holes.map { $0.par }
        let rawHcs = holes.map { $0.handicapIndex }
        guard rawHcs.allSatisfy({ $0 != nil }) else {
            return .failure(.missingHandicaps)
        }
        let handicaps = rawHcs.map { $0! }
        if let err = validate(pars: pars, handicaps: handicaps) {
            return .failure(err)
        }
        return .success((pars: pars, handicaps: handicaps))
    }
}
