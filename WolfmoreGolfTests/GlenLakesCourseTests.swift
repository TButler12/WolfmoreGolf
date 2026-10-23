import XCTest
@testable import WolfmoreGolf

final class GlenLakesCourseTests: XCTestCase {

    func testDunesVistaPar() {
        XCTAssertEqual(GL_DUNES_VISTA_PARS.reduce(0, +), 72)
    }

    func testLakesVistaPar() {
        XCTAssertEqual(GL_LAKES_VISTA_PARS.reduce(0, +), 71)
    }

    func testDunesLakesPar() {
        XCTAssertEqual(GL_DUNES_LAKES_PARS.reduce(0, +), 71)
    }
}
