import XCTest
@testable import WolfmoreGolf

final class CourseValidatorTests: XCTestCase {

    // MARK: - Helpers

    private static let validPars18: [Int] = [4,4,3,5,4,4,3,5,4, 4,4,3,5,4,4,3,5,4]
    private static let validHcs18: [Int]  = [1,3,15,5,11,7,17,9,13, 2,4,16,6,12,8,18,10,14]

    // MARK: - Happy path

    func testValidCoursePassesValidation() {
        XCTAssertNil(CourseValidator.validate(pars: Self.validPars18, handicaps: Self.validHcs18))
    }

    func testPar3And6AreAccepted() {
        var pars = Self.validPars18
        pars[0] = 3
        pars[1] = 6
        XCTAssertNil(CourseValidator.validate(pars: pars, handicaps: Self.validHcs18))
    }

    // MARK: - Par validation

    func testPar2IsRejected() {
        var pars = Self.validPars18
        pars[4] = 2
        let err = CourseValidator.validate(pars: pars, handicaps: Self.validHcs18)
        XCTAssertEqual(err, .invalidPar(hole: 5, par: 2))
    }

    func testPar7IsRejected() {
        var pars = Self.validPars18
        pars[0] = 7
        let err = CourseValidator.validate(pars: pars, handicaps: Self.validHcs18)
        XCTAssertEqual(err, .invalidPar(hole: 1, par: 7))
    }

    // MARK: - Handicap validation

    func testDuplicateHandicapIsRejected() {
        var hcs = Self.validHcs18
        hcs[1] = hcs[0]  // duplicate
        let err = CourseValidator.validate(pars: Self.validPars18, handicaps: hcs)
        XCTAssertEqual(err, .duplicateHandicap(value: hcs[0]))
    }

    func testHandicapZeroIsRejected() {
        var hcs = Self.validHcs18
        hcs[0] = 0
        let err = CourseValidator.validate(pars: Self.validPars18, handicaps: hcs)
        XCTAssertEqual(err, .handicapOutOfRange(hole: 1, value: 0, max: 18))
    }

    func testHandicap19On18HoleCourseIsRejected() {
        var hcs = Self.validHcs18
        hcs[0] = 19
        let err = CourseValidator.validate(pars: Self.validPars18, handicaps: hcs)
        XCTAssertEqual(err, .handicapOutOfRange(hole: 1, value: 19, max: 18))
    }

    // MARK: - Hole count

    func testWrongHoleCountIsRejected() {
        let pars = Array(Self.validPars18.prefix(9))
        let err = CourseValidator.validate(pars: pars, handicaps: Self.validHcs18)
        XCTAssertEqual(err, .wrongHoleCount(got: 18, expected: 9))
    }

    func testNineHoleCourseIsValid() {
        let pars = Array(Self.validPars18.prefix(9))
        let hcs: [Int] = [1,3,5,7,9,2,4,6,8]  // valid 1–9 unique handicaps
        XCTAssertNil(CourseValidator.validate(pars: pars, handicaps: hcs))
    }

    // MARK: - buildArrays

    func testBuildArraysSuccess() {
        let holes: [OpenGolfHoleData] = (1...18).map { i in
            makeFakeHole(number: i,
                         par: Self.validPars18[i-1],
                         hc:  Self.validHcs18[i-1])
        }
        switch CourseValidator.buildArrays(from: holes) {
        case .success(let (pars, hcs)):
            XCTAssertEqual(pars, Self.validPars18)
            XCTAssertEqual(hcs,  Self.validHcs18)
        case .failure(let err):
            XCTFail("Expected success, got \(err)")
        }
    }

    func testBuildArraysMissingHandicapFails() {
        var holes: [OpenGolfHoleData] = (1...18).map { i in
            makeFakeHole(number: i, par: Self.validPars18[i-1], hc: Self.validHcs18[i-1])
        }
        holes[3] = makeFakeHole(number: 4, par: 4, hc: nil)
        switch CourseValidator.buildArrays(from: holes) {
        case .success:   XCTFail("Expected failure")
        case .failure(let err): XCTAssertEqual(err, .missingHandicaps)
        }
    }

    func testBuildArraysWrongCount() {
        let holes: [OpenGolfHoleData] = (1...9).map { i in
            makeFakeHole(number: i, par: 4, hc: i)
        }
        switch CourseValidator.buildArrays(from: holes) {
        case .success:   XCTFail("Expected failure")
        case .failure(let err): XCTAssertEqual(err, .wrongHoleCount(got: 9, expected: 18))
        }
    }

    // MARK: - Helpers

    private func makeFakeHole(number: Int, par: Int, hc: Int?) -> OpenGolfHoleData {
        let json = """
        {"hole_number":\(number),"par":\(par)\(hc.map { ",\"handicap_index\":\($0)" } ?? "")}
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(OpenGolfHoleData.self, from: json)
    }
}
