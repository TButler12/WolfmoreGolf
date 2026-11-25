import XCTest
@testable import WolfmoreGolf

final class OpenGolfAPITests: XCTestCase {

    // Real response from api.opengolfapi.org/v1/courses/search?q=Lake+Barrington (2026-11-25)
    private static let fixtureJSON = """
    {"courses":[{"id":"c06081a8-4efc-4b7f-b0bc-e6416ab2a588","name":"Lake Barrington Shores Golf Club","course_name":"Lake Barrington Shores Golf Club","latitude":37.1611491105769,"longitude":-84.9600877471154,"state":"KY","city":"Lake Barrington","type":"Private","par":71,"phone":"+1-847-382-4240","website":"https://www.lbsgolf.com/"}],"total":1,"_license":"ODbL-1.0","_attribution":"© OpenStreetMap contributors (ODbL 1.0) via OpenGolfAPI — https://opengolfapi.org/attribution","_upgrade":"Full detail (tees, climate, weather, nearby, booking) free at /api/v1/courses/{id}"}
    """

    private struct SearchEnvelope: Decodable {
        let courses: [OpenGolfSearchResult]
    }

    private var fixture: SearchEnvelope {
        get throws {
            try JSONDecoder().decode(SearchEnvelope.self, from: Data(Self.fixtureJSON.utf8))
        }
    }

    func testDecodeSearchEnvelope() throws {
        XCTAssertEqual(try fixture.courses.count, 1)
    }

    func testDecodeFirstResult_id() throws {
        XCTAssertEqual(try fixture.courses[0].id, "c06081a8-4efc-4b7f-b0bc-e6416ab2a588")
    }

    func testDecodeFirstResult_name() throws {
        XCTAssertEqual(try fixture.courses[0].name, "Lake Barrington Shores Golf Club")
    }

    func testDecodeFirstResult_location() throws {
        let result = try fixture.courses[0]
        XCTAssertEqual(result.city, "Lake Barrington")
        XCTAssertEqual(result.state, "KY")
        XCTAssertEqual(result.locationLabel, "Lake Barrington, KY")
    }

    func testDecodeFirstResult_optionalFields() throws {
        let result = try fixture.courses[0]
        XCTAssertEqual(result.par, 71)
        XCTAssertEqual(result.phone, "+1-847-382-4240")
        XCTAssertEqual(result.website, "https://www.lbsgolf.com/")
        XCTAssertNil(result.country)
    }

    func testOpenGolfUUID_deterministic() {
        let uuid1 = CourseLibrary.openGolfUUID(apiId: "c06081a8-4efc-4b7f-b0bc-e6416ab2a588")
        let uuid2 = CourseLibrary.openGolfUUID(apiId: "c06081a8-4efc-4b7f-b0bc-e6416ab2a588")
        XCTAssertEqual(uuid1, uuid2)
    }

    func testOpenGolfUUID_usesNamespacePrefix() {
        let uuid = CourseLibrary.openGolfUUID(apiId: "c06081a8-4efc-4b7f-b0bc-e6416ab2a588")
        XCTAssertTrue(CourseLibrary.shared.isOpenGolfImport(id: uuid))
    }

    func testOpenGolfUUID_differentIdsProduceDifferentUUIDs() {
        let uuid1 = CourseLibrary.openGolfUUID(apiId: "c06081a8-4efc-4b7f-b0bc-e6416ab2a588")
        let uuid2 = CourseLibrary.openGolfUUID(apiId: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
        XCTAssertNotEqual(uuid1, uuid2)
    }
}

// MARK: - Course detail (/api/v1/courses/{id}) decode tests

final class OpenGolfCourseDetailTests: XCTestCase {

    // Compact fixture — real holes_data from api.opengolfapi.org/api/v1/courses/c06081a8-... (2026-11-25).
    // Extra fields (yardages, tee_coords, etc.) omitted; decoder ignores unknown keys.
    // postal_code 60010 → prefix 600 → IL; API reports "KY" — the corrector should override.
    private static let detailJSON = """
    {
      "id": "c06081a8-4efc-4b7f-b0bc-e6416ab2a588",
      "course_name": "Lake Barrington Shores Golf Club",
      "city": "Lake Barrington",
      "state": "KY",
      "holes": 18,
      "postal_code": "60010",
      "holes_data": [
        {"number":1,  "par":4, "handicap_index":18},
        {"number":2,  "par":5, "handicap_index":6},
        {"number":3,  "par":4, "handicap_index":8},
        {"number":4,  "par":4, "handicap_index":2},
        {"number":5,  "par":3, "handicap_index":10},
        {"number":6,  "par":4, "handicap_index":12},
        {"number":7,  "par":4, "handicap_index":16},
        {"number":8,  "par":3, "handicap_index":4},
        {"number":9,  "par":4, "handicap_index":14},
        {"number":10, "par":4, "handicap_index":9},
        {"number":11, "par":5, "handicap_index":7},
        {"number":12, "par":4, "handicap_index":17},
        {"number":13, "par":3, "handicap_index":11},
        {"number":14, "par":5, "handicap_index":5},
        {"number":15, "par":4, "handicap_index":13},
        {"number":16, "par":3, "handicap_index":15},
        {"number":17, "par":4, "handicap_index":1},
        {"number":18, "par":4, "handicap_index":3}
      ]
    }
    """

    private struct CourseDetailResponse: Decodable {
        let holesData: [OpenGolfHoleData]?
        let postalCode: String?
        enum CodingKeys: String, CodingKey {
            case holesData  = "holes_data"
            case postalCode = "postal_code"
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            holesData  = try? c.decode([OpenGolfHoleData].self, forKey: .holesData)
            postalCode = try? c.decode(String.self,            forKey: .postalCode)
        }
    }

    private var detail: CourseDetailResponse {
        get throws {
            try JSONDecoder().decode(CourseDetailResponse.self,
                                    from: Data(Self.detailJSON.utf8))
        }
    }

    func testDecodeHolesData_count() throws {
        XCTAssertEqual(try detail.holesData?.count, 18)
    }

    func testDecodeHolesData_firstHole() throws {
        let hole = try XCTUnwrap(detail.holesData?.first)
        XCTAssertEqual(hole.holeNumber, 1)
        XCTAssertEqual(hole.par, 4)
        XCTAssertEqual(hole.handicapIndex, 18)
    }

    func testDecodeHolesData_lastHole() throws {
        let hole = try XCTUnwrap(detail.holesData?.last)
        XCTAssertEqual(hole.holeNumber, 18)
        XCTAssertEqual(hole.par, 4)
        XCTAssertEqual(hole.handicapIndex, 3)
    }

    func testDecodeHolesData_uniqueHandicaps() throws {
        let hcs = try XCTUnwrap(detail.holesData).compactMap { $0.handicapIndex }
        XCTAssertEqual(Set(hcs).count, 18, "handicap_index values must all be unique")
    }

    func testDecodeHolesData_totalPar() throws {
        let par = try XCTUnwrap(detail.holesData).reduce(0) { $0 + $1.par }
        XCTAssertEqual(par, 71)
    }

    func testDecodeHolesData_passesValidator() throws {
        let holes = try XCTUnwrap(detail.holesData)
        switch CourseValidator.buildArrays(from: holes) {
        case .success: break
        case .failure(let err): XCTFail("Validation failed: \(err)")
        }
    }

    func testMissingHolesData_returnsNil() throws {
        let json = """
        {"id":"abc","course_name":"Test","city":null,"state":null,"holes":18}
        """
        let result = try JSONDecoder().decode(CourseDetailResponse.self,
                                             from: Data(json.utf8))
        XCTAssertNil(result.holesData)
    }

    func testDecodePostalCode() throws {
        XCTAssertEqual(try detail.postalCode, "60010")
    }

    func testNullHandicapIndex_passesDecodeButFailsValidator() throws {
        let json = """
        {"holes_data":[{"number":1,"par":4,"handicap_index":null}]}
        """
        let result = try JSONDecoder().decode(CourseDetailResponse.self,
                                             from: Data(json.utf8))
        // 1 hole → noHoleData (not 9 or 18)
        let holes = try XCTUnwrap(result.holesData)
        switch CourseValidator.buildArrays(from: holes) {
        case .success: XCTFail("Expected failure")
        case .failure(let err): XCTAssertEqual(err, .noHoleData)
        }
    }

    // Lake Barrington Shores: API reports KY, ZIP 60010 → IL.
    func testLakeBarringtonShores_zipOverridesAPIState() throws {
        let apiState  = try detail.postalCode.map { _ in "KY" }  // what the API sent
        let zipState  = try detail.postalCode.flatMap { ZipStateCorrector.state(forZip: $0) }
        XCTAssertEqual(zipState, "IL")
        XCTAssertNotEqual(zipState, apiState)
    }
}

// MARK: - ZipStateCorrector tests

final class ZipStateCorrectorTests: XCTestCase {

    func testPrefix600_returnsIL() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "60010"), "IL")
    }

    func testPrefix902_returnsCA() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "90210"), "CA")
    }

    func testPrefix100_returnsNY() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "10001"), "NY")
    }

    func testPrefix400_returnsKY() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "40509"), "KY")
    }

    func testPrefix302_returnsDE() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "30201"), "GA")  // 300-319 = GA
    }

    func testPrefix197_returnsDE() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "19701"), "DE")
    }

    func testPrefix200_returnsDC() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "20001"), "DC")
    }

    func testPrefix201_returnsVA() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "20110"), "VA")
    }

    func testPrefix995_returnsAK() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "99501"), "AK")
    }

    func testShortZip_returnsNil() {
        XCTAssertNil(ZipStateCorrector.state(forZip: "60"))
    }

    func testNonNumericZip_returnsNil() {
        XCTAssertNil(ZipStateCorrector.state(forZip: "ABCDE"))
    }

    func testUnassignedPrefix_returnsNil() {
        XCTAssertNil(ZipStateCorrector.state(forZip: "71500"))  // 715 is unassigned between LA/AR
    }

    func testFallback_nilZip_returnsFallback() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: nil, fallback: "KY"), "KY")
    }

    func testFallback_unknownZip_returnsFallback() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "71500", fallback: "AR"), "AR")
    }

    func testFallback_knownZip_overridesFallback() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "60010", fallback: "KY"), "IL")
    }

    func testFallback_nilZipNilFallback_returnsNil() {
        XCTAssertNil(ZipStateCorrector.state(forZip: nil, fallback: nil))
    }

    func testFallback_shortZip_returnsFallback() {
        XCTAssertEqual(ZipStateCorrector.state(forZip: "60", fallback: "IL"), "IL")
    }

    // Lake Barrington Shores: API reports KY, ZIP 60010 → corrects to IL.
    // If a built-in named "Lake Barrington Shores" / state IL existed, the duplicate check would fire.
    func testDuplicateCheck_lakeBarringtonShores_correctedStateIsIL() {
        let corrected = ZipStateCorrector.state(forZip: "60010", fallback: "KY")
        XCTAssertEqual(corrected, "IL",
            "ZIP correction must override API-reported KY with IL before the built-in duplicate check runs")
        let normalised = CourseImportViewController.normaliseName("Lake Barrington Shores Golf Club")
        XCTAssertEqual(normalised, "lake barrington shores")
    }

    func testNormaliseName_stripsGolfClub() {
        XCTAssertEqual(CourseImportViewController.normaliseName("Pebble Beach Golf Links"), "pebble beach")
        XCTAssertEqual(CourseImportViewController.normaliseName("Augusta National Golf Club"), "augusta national")
        XCTAssertEqual(CourseImportViewController.normaliseName("Lake Barrington Shores Golf Club"), "lake barrington shores")
        XCTAssertEqual(CourseImportViewController.normaliseName("Medinah Country Club"), "medinah")
    }
}
